//
//  GalleryViewModelTests.swift
//  MyGalleryTests
//

import XCTest
@testable import MyGallery

@MainActor
final class GalleryViewModelTests: XCTestCase {

    func testInitialStateIsIdle() {
        let viewModel = GalleryViewModel(repository: MockImageRepository(results: []))
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(viewModel.images.isEmpty)
    }

    func testLoadSuccessPublishesImagesAndLoadedState() async {
        let repository = MockImageRepository(results: [.success(makePage(start: 0, count: 20))])
        let viewModel = GalleryViewModel(repository: repository, pageSize: 20)

        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.images.count, 20)
        XCTAssertEqual(repository.requestedPages, [1])
        XCTAssertTrue(viewModel.canLoadMore)
    }

    func testStateIsLoadingWhileRequestIsInFlight() async {
        let repository = SuspendedRepository()
        let viewModel = GalleryViewModel(repository: repository)

        let task = Task { await viewModel.loadIfNeeded() }
        await repository.waitUntilRequested()
        XCTAssertEqual(viewModel.state, .loading)

        repository.resume(with: makePage(start: 0, count: 3))
        await task.value
        XCTAssertEqual(viewModel.state, .loaded)
    }

    func testLoadIfNeededDoesNotRefetchAfterSuccess() async {
        let repository = MockImageRepository(results: [.success(makePage(start: 0, count: 5))])
        let viewModel = GalleryViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded() // e.g. returning from the detail screen

        XCTAssertEqual(repository.requestedPages, [1])
    }

    func testErrorThenRetrySucceeds() async {
        let repository = MockImageRepository(results: [
            .failure(TestError.network),
            .success(makePage(start: 0, count: 4))
        ])
        let viewModel = GalleryViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        guard case .failed = viewModel.state else {
            return XCTFail("Expected failed state, got \(viewModel.state)")
        }

        await viewModel.retry()
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.images.count, 4)
        XCTAssertEqual(repository.requestedPages, [1, 1])
    }

    func testEmptyResponseShowsEmptyState() async {
        let viewModel = GalleryViewModel(repository: MockImageRepository(results: [.success([])]))
        await viewModel.loadIfNeeded()
        XCTAssertEqual(viewModel.state, .empty)
        XCTAssertFalse(viewModel.canLoadMore)
    }

    func testLoadMoreAppendsNextPage() async {
        let repository = MockImageRepository(results: [
            .success(makePage(start: 0, count: 10)),
            .success(makePage(start: 10, count: 10))
        ])
        let viewModel = GalleryViewModel(repository: repository, pageSize: 10)

        await viewModel.loadIfNeeded()
        await viewModel.loadMoreIfNeeded(currentImage: viewModel.images[9])

        XCTAssertEqual(viewModel.images.count, 20)
        XCTAssertEqual(repository.requestedPages, [1, 2])
        XCTAssertTrue(viewModel.canLoadMore)
    }

    func testLoadMoreNotTriggeredForEarlyItems() async {
        let repository = MockImageRepository(results: [.success(makePage(start: 0, count: 10))])
        let viewModel = GalleryViewModel(repository: repository, pageSize: 10)

        await viewModel.loadIfNeeded()
        await viewModel.loadMoreIfNeeded(currentImage: viewModel.images[0])

        XCTAssertEqual(repository.requestedPages, [1])
    }

    func testShortPageStopsPagination() async {
        let repository = MockImageRepository(results: [
            .success(makePage(start: 0, count: 10)),
            .success(makePage(start: 10, count: 3))
        ])
        let viewModel = GalleryViewModel(repository: repository, pageSize: 10)

        await viewModel.loadIfNeeded()
        await viewModel.loadMore()
        await viewModel.loadMore()

        XCTAssertFalse(viewModel.canLoadMore)
        XCTAssertEqual(viewModel.images.count, 13)
        XCTAssertEqual(repository.requestedPages, [1, 2])
    }

    func testLoadMoreFailureKeepsExistingImagesAndCanRetry() async {
        let repository = MockImageRepository(results: [
            .success(makePage(start: 0, count: 10)),
            .failure(TestError.network),
            .success(makePage(start: 10, count: 10))
        ])
        let viewModel = GalleryViewModel(repository: repository, pageSize: 10)

        await viewModel.loadIfNeeded()
        await viewModel.loadMore()
        XCTAssertEqual(viewModel.images.count, 10)
        XCTAssertNotNil(viewModel.loadMoreError)
        XCTAssertEqual(viewModel.state, .loaded)

        await viewModel.loadMore()
        XCTAssertNil(viewModel.loadMoreError)
        XCTAssertEqual(viewModel.images.count, 20)
        XCTAssertEqual(repository.requestedPages, [1, 2, 2])
    }

    func testSelectingImagePushesItAndPreparesDetail() async {
        let image = makeImage("42", author: "Jane Doe", width: 4000, height: 2000)
        let viewModel = GalleryViewModel(repository: MockImageRepository(results: [.success([image])]))
        await viewModel.loadIfNeeded()

        viewModel.select(image)
        XCTAssertEqual(viewModel.path, [image])

        let detail = viewModel.makeDetailViewModel(for: image)
        XCTAssertEqual(detail.image, image)
        XCTAssertEqual(detail.title, "Jane Doe")
        XCTAssertEqual(detail.aspectRatio, 2, accuracy: 0.001)
        XCTAssertEqual(detail.imageURL.absoluteString, "https://picsum.photos/id/42/1200/600")
        XCTAssertTrue(detail.metadata.contains { $0.label == "Image ID" && $0.value == "42" })

        // Popping back keeps loaded items.
        viewModel.path.removeAll()
        XCTAssertEqual(viewModel.images, [image])
    }
}

/// Repository that suspends until the test resumes it, to observe `.loading`.
private final class SuspendedRepository: ImageRepositoryProtocol, @unchecked Sendable {
    private var continuation: CheckedContinuation<[GalleryImage], Error>?
    private var requestedWaiter: CheckedContinuation<Void, Never>?
    private var requested = false

    func fetchImages(page: Int, limit: Int) async throws -> [GalleryImage] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.continuation = continuation
                self.requested = true
                self.requestedWaiter?.resume()
                self.requestedWaiter = nil
            }
        }
    }

    @MainActor
    func waitUntilRequested() async {
        if requested { return }
        await withCheckedContinuation { requestedWaiter = $0 }
    }

    @MainActor
    func resume(with images: [GalleryImage]) {
        continuation?.resume(returning: images)
        continuation = nil
    }
}
