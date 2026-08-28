//
//  FeedThumbnailView.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import SwiftUI

struct FeedThumbnailView: View {

    // MARK: - Properties

    let post: Post

    private let mediaManager = MediaManager()

    @State private var thumbnail: UIImage?

    // MARK: - Body

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.15))
            .aspectRatio(
                3.0 / 4.0,
                contentMode: .fit
            ) // TODO: Fix aspect ratio
            .overlay {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFit()
                        .clipped()
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .padding(24)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .clipped()
            .task {
                await loadThumbnail()
            }
    }

    // MARK: - Actions

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
            audioMediaPath: nil,
            thumbnailPath: ""
        )
    )
}
