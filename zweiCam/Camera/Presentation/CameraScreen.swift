//
//  CameraScreen.swift
//  zweiCam
//
//  Created by Ayi Padilla on 25.08.26.
//

import SwiftUI

struct CameraScreen: View {
    private let cameraSessionManager = CameraSessionManager()
    private let mediaManager = MediaManager()

    @State private var selectedMode = CameraMode.photo
    @State private var isMultiCamSupported = false
    @State private var hasCameraAccess = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                cameraPreview
                modeSelector
                Spacer()
                cameraButton
                    .padding(.bottom, 34)
            }
            .padding(.top, 18)
        }
        .task {
            isMultiCamSupported = cameraSessionManager.isMultiCamSupported()

            guard isMultiCamSupported else {
                print("MultiCam is not supported")
                return
            }
            print("MultiCam is supported")

            hasCameraAccess = await cameraSessionManager.requestCameraAccess()
            print("Camera access: \(hasCameraAccess)")
            
            let hasMicrophoneAccess =
                await cameraSessionManager.requestMicrophoneAccess()

            print("Microphone access: \(hasMicrophoneAccess)")
            
            if isMultiCamSupported && hasCameraAccess {
                cameraSessionManager.start()
            }
        }
    }

    private var cameraPreview: some View {
        ZStack {
            cameraPreviewBackground

            if hasCameraAccess {
                CameraPreviewView(
                    backPreviewLayer: cameraSessionManager.backPreviewLayer,
                    frontPreviewLayer: cameraSessionManager.frontPreviewLayer
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .aspectRatio(3 / 4, contentMode: .fit)
        .padding(.horizontal, 24)
    }

    private var cameraPreviewBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
    }

    private var modeSelector: some View {
        HStack(spacing: 28) {
            ForEach(CameraMode.allCases) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    Text(mode.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(selectedMode == mode ? .yellow : .white.opacity(0.55))
                }
            }
        }
    }

    private var cameraButton: some View {

        ZStack {

            shutterButton
                .opacity(selectedMode == .photo ? 1 : 0)
                .disabled(selectedMode != .photo)

            videoButton
                .opacity(selectedMode == .video ? 1 : 0)
                .disabled(selectedMode != .video)

        }

    }

    private var shutterButton: some View {

        Button {
            Task {
                do {
                    let photos = try await cameraSessionManager.captureDualPhoto()

                    debugPrint("Back photo captured: \(photos.backImage.size)")
                    debugPrint("Front photo captured: \(photos.frontImage.size)")
                    
                    let post = try await mediaManager.savePost(
                        backImage: photos.backImage,
                        frontImage: photos.frontImage
                    )

                    debugPrint("Post saved: \(post.id)")
                    
                } catch {
                    debugPrint("Failed to capture photo: \(error)")
                }
            }
        } label: {

            Circle()
                .strokeBorder(Color.white, lineWidth: 5)
                .background(
                    Circle()
                        .fill(Color.white)
                        .padding(9)
                )
                .frame(width: 82, height: 82)
        }
        .buttonStyle(.plain)
    }
    
    private var videoButton: some View {
        Button {
            debugPrint("Video button tapped")
        } label: {
            Circle()
                .strokeBorder(Color.red, lineWidth: 5)
                .frame(width: 82, height: 82)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

private enum CameraMode: String, CaseIterable, Identifiable {
    case video
    case photo

    var id: Self { self }

    var title: String {
        rawValue.uppercased()
    }
}

#Preview {
    CameraScreen()
}
