//
//  MediaViewerViewModel.swift
//  zweiCam
//
//  Created by Ayi Padilla on 28.08.26.
//

import AVKit
import Observation
import UIKit

@MainActor
@Observable
final class MediaViewerViewModel {

    // MARK: - Dependencies

    private let mediaManager = MediaManager()

    // MARK: - State

    let post: Post

    var backImage: UIImage?
    var frontImage: UIImage?

    var backPlayer: AVPlayer?
    var frontPlayer: AVPlayer?
    var audioPlayer: AVPlayer?

    // MARK: - Initialization

    init(post: Post) {
        self.post = post
    }

    // MARK: - Lifecycle

    func onAppear() async {
        await loadMedia()
    }

    func onDisappear() {
        backPlayer?.pause()
        frontPlayer?.pause()
        audioPlayer?.pause()
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
