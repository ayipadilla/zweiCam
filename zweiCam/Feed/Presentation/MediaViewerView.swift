//
//  MediaViewerScreen.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import AVKit
import SwiftUI

struct MediaViewerView: View {

    // MARK: - State

    @State private var viewModel: MediaViewerViewModel

    // MARK: - Initialization

    init(post: Post) {
        _viewModel = State(
            initialValue: MediaViewerViewModel(post: post)
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack {
                if viewModel.post.mediaType == .photo {
                    photoContent
                } else {
                    videoContent
                }

                Spacer()
            }
        }
        .navigationTitle(
            viewModel.post.createdAt.formatted(
                .dateTime
                    .day()
                    .month(.wide)
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    // MARK: - Photo

    private var photoContent: some View {
        if let backImage = viewModel.backImage {
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

                    if let frontImage = viewModel.frontImage {
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
        if let backPlayer = viewModel.backPlayer {
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
                        .allowsHitTesting(false)
                    // TODO: Add custom playback control across all the players

                    if let frontPlayer = viewModel.frontPlayer {
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
}
