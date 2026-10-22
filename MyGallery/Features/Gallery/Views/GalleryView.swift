//
//  GalleryView.swift
//  MyGallery
//
//  Created by Rahul Gangwar on 22/10/26.
//

import SwiftUI

struct GalleryView: View {
    @StateObject private var viewModel = GalleryViewModel()
    let onLogout: () -> Void

    // Two equal columns on iPhone, three on the wider iPad screen.
    private var columns: [GridItem] {
        let count = DeviceLayout.isPad ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("MyGallery")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Logout", action: onLogout)
                    }
                }
                .navigationDestination(for: GalleryImage.self) { image in
                    ImageDetailView(image: image)
                }
        }
        .task {
            await viewModel.loadFirstPageIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.images.isEmpty {
            ProgressView("Loading photos...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage, viewModel.images.isEmpty {
            errorView(message: errorMessage)
        } else if viewModel.images.isEmpty {
            emptyView
        } else {
            imageGrid
        }
    }

    private var imageGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.images) { image in
                    NavigationLink(value: image) {
                        GalleryGridItemView(image: image)
                    }
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.loadMoreIfNeeded(currentImage: image)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            loadMoreFooter
                .padding(.vertical, 16)
        }
        .refreshable {
            await viewModel.loadFirstPage()
        }
    }

    @ViewBuilder
    private var loadMoreFooter: some View {
        if viewModel.isLoadingMore {
            ProgressView()
        } else if let message = viewModel.loadMoreErrorMessage {
            VStack(spacing: 8) {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    Task { await viewModel.loadNextPage() }
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(AppColors.secondaryText)
            Text("Couldn't load photos")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.loadFirstPage() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle")
                .font(.largeTitle)
                .foregroundStyle(AppColors.secondaryText)
            Text("No photos yet")
                .font(.headline)
            Text("There are no photos to show right now. Pull down to refresh.")
                .font(.subheadline)
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.loadFirstPage() }
            }
            .buttonStyle(.bordered)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
