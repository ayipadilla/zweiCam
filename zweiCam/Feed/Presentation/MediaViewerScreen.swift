//
//  MediaViewerScreen.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import SwiftUI
import AVKit

struct MediaViewerScreen: View {

    // MARK: - Properties

    let post: Post

    private let mediaManager = MediaManager()

    @State private var backImage: UIImage?
    @State private var frontImage: UIImage?

    @State private var backPlayer: AVPlayer?
    @State private var frontPlayer: AVPlayer?
    @State private var audioPlayer: AVPlayer?

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack {
                if post.mediaType == .photo {
                    photoContent
                } else {
                    videoContent
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
            await loadMedia()
        }
        .onDisappear {
            backPlayer?.pause()
            frontPlayer?.pause()
            audioPlayer?.pause()
        }
    }

    // MARK: - Photo

    private var photoContent: some View {
        if let backImage {
            return AnyView(
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
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    // MARK: - Video

    private var videoContent: some View {
        if let backPlayer {
            return AnyView(
                ZStack(alignment: .topLeading) {
                    VideoPlayer(player: backPlayer)
                        .aspectRatio(
                            3 / 4,
                            contentMode: .fit
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 20,
                                style: .continuous
                            )
                        )

                    if let frontPlayer {
                        VideoPlayer(player: frontPlayer)
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
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, 20)
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    // MARK: - Media Loading

    private func loadMedia() async {
        do {
            if post.mediaType == .photo {
                backImage = try await mediaManager.loadImage(
                    atRelativePath: post.backMediaPath
                )

                frontImage = try await mediaManager.loadImage(
                    atRelativePath: post.frontMediaPath
                )
            } else {
                let backURL = try await mediaManager.loadMediaURL(
                    atRelativePath: post.backMediaPath
                )

                let frontURL = try await mediaManager.loadMediaURL(
                    atRelativePath: post.frontMediaPath
                )

                let newBackPlayer = AVPlayer(url: backURL)
                let newFrontPlayer = AVPlayer(url: frontURL)

                backPlayer = newBackPlayer
                frontPlayer = newFrontPlayer

                newBackPlayer.play()
                newFrontPlayer.play()

                if let audioPath = post.audioMediaPath {
                    let audioURL = try await mediaManager.loadMediaURL(
                        atRelativePath: audioPath
                    )

                    let newAudioPlayer = AVPlayer(url: audioURL)

                    audioPlayer = newAudioPlayer

                    newAudioPlayer.play()
                }
            }
        } catch {
            debugPrint("Failed to load post media: \(error)")
        }
    }
}
