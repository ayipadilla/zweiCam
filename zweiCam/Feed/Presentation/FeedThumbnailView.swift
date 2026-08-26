//
//  FeedThumbnailView.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import SwiftUI

struct FeedThumbnailView: View {

    let post: Post

    private let mediaManager = MediaManager()

    @State private var thumbnail: UIImage?

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.15))
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .overlay {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .padding(24)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .task {
                await loadThumbnail()
            }
    }

    private func loadThumbnail() async {
        do {
            thumbnail = try await mediaManager.loadImage(
                atRelativePath: post.thumbnailPath
            )
        } catch {
            debugPrint("Failed to load thumbnail: \(error)")
        }
    }
}

#Preview {
    FeedThumbnailView(
        post: Post(
            id: UUID(),
            createdAt: Date(),
            mediaType: .photo,
            backMediaPath: "",
            frontMediaPath: "",
            thumbnailPath: ""
        )
    )
}
