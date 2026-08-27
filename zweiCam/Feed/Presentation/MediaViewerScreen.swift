//
//  MediaViewerScreen.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import SwiftUI

struct MediaViewerScreen: View {
    let post: Post

    private let mediaManager = MediaManager()

    @State private var backImage: UIImage?
    @State private var frontImage: UIImage?

    var body: some View {

        ZStack {

            Color.black
                .ignoresSafeArea()

            VStack {

                if let backImage {

                    ZStack(alignment: .topLeading) {

                        Image(uiImage: backImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 20,
                                    style: .continuous
                                )
                            )

                        if let frontImage {

                            Image(uiImage: frontImage)
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: 120,
                                    height: 160
                                )
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 14,
                                        style: .continuous
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(
                                        cornerRadius: 14,
                                        style: .continuous
                                    )
                                    .stroke(
                                        Color.black,
                                        lineWidth: 3
                                    )
                                )
                                .padding(12)

                        }

                    }
                    .padding(.horizontal, 20)

                }

                Spacer()

            }

        }
        .navigationTitle(
            post.createdAt.formatted(
                .dateTime
                    .day()
                    .month(.wide)
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                backImage = try await mediaManager.loadImage(
                    atRelativePath: post.backMediaPath
                )

                frontImage = try await mediaManager.loadImage(
                    atRelativePath: post.frontMediaPath
                )
            } catch {
                debugPrint("Failed to load post images: \(error)")
            }
        }

    }
    

}

//#Preview {
//
//    NavigationStack {
//        MediaViewerScreen(post: Post(/* ... */))
//    }
//
//}
