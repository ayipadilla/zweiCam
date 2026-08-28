//
//  FeedScreen.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import SwiftUI

struct FeedView: View {

    // MARK: - State

    @State private var viewModel = FeedViewModel()

    private let columns = Array(
        repeating: GridItem(
            .flexible(),
            spacing: 2
        ),
        count: 4
    )

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ScrollView {
                if viewModel.posts.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(
                        columns: columns,
                        spacing: 2
                    ) {
                        ForEach(viewModel.posts) { post in
                            NavigationLink {
                                MediaViewerView(post: post)
                            } label: {
                                FeedThumbnailView(post: post)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.top, 16)
                }
            }
        }
        .navigationTitle("zweiCam")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CameraView()
                } label: {
                    Image(systemName: "camera")
                        .foregroundStyle(.white)
                }
            }
        }
        .task {
            await viewModel.onAppear()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("You have no posts yet.")
                .font(.headline)

            Text("Start creating one by tapping on Camera ⤴")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
        .padding(.horizontal, 32)
    }
}

#Preview {
    NavigationStack {
        FeedView()
    }
}
