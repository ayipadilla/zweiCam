//
//  CameraScreen.swift
//  zweiCam
//
//  Created by Ayi Padilla on 25.08.26.
//

import SwiftUI

struct CameraScreen: View {

    // MARK: - State

    @State private var viewModel = CameraViewModel()

    // MARK: - Body

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
            await viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    // MARK: - Components

    private var cameraPreview: some View {
        ZStack {
            cameraPreviewBackground

            if viewModel.hasCameraAccess {
                CameraPreviewView(
                    backPreviewLayer: viewModel.backPreviewLayer,
                    frontPreviewLayer: viewModel.frontPreviewLayer
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )
            }
        }
        .aspectRatio(3 / 4, contentMode: .fit)
        .padding(.horizontal, 24)
    }

    private var cameraPreviewBackground: some View {
        RoundedRectangle(
            cornerRadius: 14,
            style: .continuous
        )
        .fill(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .stroke(
                Color.white.opacity(0.16),
                lineWidth: 1
            )
        )
    }

    private var modeSelector: some View {
        HStack(spacing: 28) {
            ForEach(CameraMode.allCases) { mode in
                Button {
                    viewModel.selectMode(mode)
                } label: {
                    Text(mode.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(
                            viewModel.selectedMode == mode
                                ? .yellow
                                : .white.opacity(0.55)
                        )
                }
            }
        }
    }

    private var cameraButton: some View {
        ZStack {
            shutterButton
                .opacity(viewModel.selectedMode == .photo ? 1 : 0)
                .disabled(viewModel.selectedMode != .photo)

            videoButton
                .opacity(viewModel.selectedMode == .video ? 1 : 0)
                .disabled(viewModel.selectedMode != .video)
        }
    }

    private var shutterButton: some View {
        Button {
            Task {
                await viewModel.capturePhoto()
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
            Task {
                await viewModel.toggleRecording()
            }
        } label: {
            Circle()
                .strokeBorder(Color.red, lineWidth: 5)
                .frame(width: 82, height: 82)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CameraScreen()
}
