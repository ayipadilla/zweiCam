//
//  FeedScreen.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import SwiftUI

struct FeedScreen: View {

    private let mediaManager = MediaManager()

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 2),
        count: 4
    )

    @State private var posts: [Post] = []

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ScrollView {
                LazyVGrid(
                    columns: columns,
                    spacing: 2
                ) {
                    ForEach(posts) { post in
                        FeedThumbnailView(post: post)
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
            await loadPosts()
        }
    }

    private func loadPosts() async {
        do {
            posts = try await mediaManager.loadPosts()
        } catch {
            debugPrint("Failed to load posts: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        FeedScreen()
    }
}
