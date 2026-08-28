//
//  FeedScreen.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import SwiftUI

struct FeedScreen: View {

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
                LazyVGrid(
                    columns: columns,
                    spacing: 2
                ) {
                    ForEach(viewModel.posts) { post in
                        NavigationLink {
                            MediaViewerScreen(post: post)
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
        .navigationTitle("zweiCam")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CameraScreen()
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
}

#Preview {
    NavigationStack {
        FeedScreen()
    }
}
