//
//  CameraScreen.swift
//  zweiCam
//
//  Created by Ayi Padilla on 25.08.26.
//

import SwiftUI

struct CameraScreen: View {
    private let cameraSessionManager = CameraSessionManager()

    @State private var selectedMode = CameraMode.photo
    @State private var isMultiCamSupported = false
    @State private var hasCameraAccess = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                topBar

                cameraPreview

                modeSelector

                Spacer()

                shutterButton
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
            
            if isMultiCamSupported && hasCameraAccess {
                cameraSessionManager.start()
            }
        }
    }

    private var cameraPreview: some View {
        ZStack {
            cameraPreviewBackground

            if hasCameraAccess {
                CameraPreviewView(previewLayer: cameraSessionManager.backPreviewLayer)
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

    private var topBar: some View {
        ZStack {
            Text("zweiCam")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            HStack {
                Spacer()

                Button("Feed") {}
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Color.white.opacity(0.12), in: Capsule())
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 20)
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

    private var shutterButton: some View {
        Button {} label: {
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
