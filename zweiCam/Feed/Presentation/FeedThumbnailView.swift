//
//  FeedThumbnailView.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import SwiftUI

struct FeedThumbnailView: View {

    let post: Post

    var body: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .clipped()
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
