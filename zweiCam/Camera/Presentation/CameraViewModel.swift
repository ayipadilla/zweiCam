//
//  CameraViewModel.swift
//  zweiCam
//
//  Created by Ayi Padilla on 28.08.26.
//

import AVFoundation
import Observation
import UIKit

enum CameraMode: String, CaseIterable, Identifiable {
    case video
    case photo

    var id: Self {
        self
    }

    var title: String {
        rawValue.uppercased()
    }
}

@MainActor
@Observable
final class CameraViewModel {

    // MARK: - Dependencies

    private let cameraSessionManager = CameraSessionManager()
    private let mediaManager = MediaManager()

    // MARK: - State

    var selectedMode = CameraMode.photo
    var isMultiCamSupported = false
    var hasCameraAccess = false
    var isRecording = false
    var isLoading = true

    // MARK: - Camera Preview

    var backPreviewLayer: AVCaptureVideoPreviewLayer {
        cameraSessionManager.backPreviewLayer
    }

    var frontPreviewLayer: AVCaptureVideoPreviewLayer {
        cameraSessionManager.frontPreviewLayer
    }

    // MARK: - Lifecycle

    func onAppear() async {
        defer {
            isLoading = false
        }

        isMultiCamSupported =
            cameraSessionManager.isMultiCamSupported()

        guard isMultiCamSupported else {
            debugPrint("MultiCam is not supported")
            return
        }

        debugPrint("MultiCam is supported")

        hasCameraAccess =
            await cameraSessionManager.requestCameraAccess()

        debugPrint("Camera access: \(hasCameraAccess)")

        let hasMicrophoneAccess =
            await cameraSessionManager.requestMicrophoneAccess()

        debugPrint(
            "Microphone access: \(hasMicrophoneAccess)"
        )

        guard hasCameraAccess else {
            return
        }

        cameraSessionManager.start()
    }

    func onDisappear() {
        cameraSessionManager.stop()
    }

    // MARK: - Camera

    func selectMode(_ mode: CameraMode) {
        selectedMode = mode

        if mode == .video {
            cameraSessionManager.configureVideoCapture()
        }
    }

    // MARK: - Photo

    func capturePhoto() async {
        do {
            let photos =
                try await cameraSessionManager.captureDualPhoto()

            debugPrint(
                "Back photo captured: \(photos.backImage.size)"
            )

            debugPrint(
                "Front photo captured: \(photos.frontImage.size)"
            )

            let post =
                try await mediaManager.savePost(
                    backImage: photos.backImage,
                    frontImage: photos.frontImage
                )

            debugPrint("Post saved: \(post.id)")
        } catch {
            debugPrint(
                "Failed to capture photo: \(error)"
            )
        }
    }

    // MARK: - Video

    func toggleRecording() async {
        if isRecording {
            await stopRecording()
        } else {
            cameraSessionManager.startRecording()
            isRecording = true
        }
    }

    private func stopRecording() async {
        let recording =
            await cameraSessionManager.stopRecording()

        isRecording = false

        guard let recording else {
            return
        }

        do {
            let post =
                try await mediaManager.saveVideoPost(
                    recording: recording
                )

            debugPrint("Video post saved: \(post.id)")
        } catch {
            debugPrint(
                "Failed to save video post: \(error)"
            )
        }
    }
}
