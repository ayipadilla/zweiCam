//
//  CameraSessionManager.swift
//  zweiCam
//
//  Created by Ayi Padilla on 25.08.26.
//

import AVFoundation
import UIKit

final class CameraSessionManager {
    private let multiCamSession = AVCaptureMultiCamSession()

    let backPreviewLayer = AVCaptureVideoPreviewLayer()
    let frontPreviewLayer = AVCaptureVideoPreviewLayer()

    private let backPhotoOutput = AVCapturePhotoOutput()
    private let frontPhotoOutput = AVCapturePhotoOutput()
    private var photoCaptureDelegate: PhotoCaptureDelegate?

    func isMultiCamSupported() -> Bool {
        AVCaptureMultiCamSession.isMultiCamSupported
    }
    
    func start() {
        guard let backCamera = getBackCamera() else {
            debugPrint("Back camera not found")
            return
        }

        guard let frontCamera = getFrontCamera() else {
            debugPrint("Front camera not found")
            return
        }

        do {
            let backCameraInput = try AVCaptureDeviceInput(device: backCamera)
            let frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)

            do {
                multiCamSession.beginConfiguration()
                defer { multiCamSession.commitConfiguration() }

                guard multiCamSession.canAddInput(backCameraInput) else {
                    debugPrint("Cannot add back camera input to multi-cam session")
                    return
                }

                guard multiCamSession.canAddInput(frontCameraInput) else {
                    debugPrint("Cannot add front camera input to multi-cam session")
                    return
                }

                multiCamSession.addInputWithNoConnections(backCameraInput)
                multiCamSession.addInputWithNoConnections(frontCameraInput)

                guard let backVideoPort = backCameraInput.ports(
                    for: .video,
                    sourceDeviceType: backCamera.deviceType,
                    sourceDevicePosition: backCamera.position
                ).first else {
                    debugPrint("Back camera video port not found")
                    return
                }

                guard let frontVideoPort = frontCameraInput.ports(
                    for: .video,
                    sourceDeviceType: frontCamera.deviceType,
                    sourceDevicePosition: frontCamera.position
                ).first else {
                    debugPrint("Front camera video port not found")
                    return
                }

                backPreviewLayer.setSessionWithNoConnection(multiCamSession)
                frontPreviewLayer.setSessionWithNoConnection(multiCamSession)

                let backPreviewConnection = AVCaptureConnection(
                    inputPort: backVideoPort,
                    videoPreviewLayer: backPreviewLayer
                )

                let frontPreviewConnection = AVCaptureConnection(
                    inputPort: frontVideoPort,
                    videoPreviewLayer: frontPreviewLayer
                )

                guard multiCamSession.canAddConnection(backPreviewConnection) else {
                    debugPrint("Cannot add back preview connection to multi-cam session")
                    return
                }

                guard multiCamSession.canAddConnection(frontPreviewConnection) else {
                    debugPrint("Cannot add front preview connection to multi-cam session")
                    return
                }
                
                multiCamSession.addConnection(backPreviewConnection)
                multiCamSession.addConnection(frontPreviewConnection)

                guard multiCamSession.canAddOutput(backPhotoOutput) else {
                    debugPrint("Cannot add back photo output to multi-cam session")
                    return
                }

                guard multiCamSession.canAddOutput(frontPhotoOutput) else {
                    debugPrint("Cannot add front photo output to multi-cam session")
                    return
                }
                
                multiCamSession.addOutputWithNoConnections(backPhotoOutput)
                multiCamSession.addOutputWithNoConnections(frontPhotoOutput)
                
                let backPhotoConnection = AVCaptureConnection(
                    inputPorts: [backVideoPort],
                    output: backPhotoOutput
                )

                let frontPhotoConnection = AVCaptureConnection(
                    inputPorts: [frontVideoPort],
                    output: frontPhotoOutput
                )

                guard multiCamSession.canAddConnection(backPhotoConnection) else {
                    debugPrint("Cannot add back photo connection to multi-cam session")
                    return
                }

                guard multiCamSession.canAddConnection(frontPhotoConnection) else {
                    debugPrint("Cannot add front photo connection to multi-cam session")
                    return
                }

                multiCamSession.addConnection(backPhotoConnection)
                multiCamSession.addConnection(frontPhotoConnection)

            }

            multiCamSession.startRunning()
            debugPrint("Back and front camera previews configured and multi-cam session started")
        } catch {
            debugPrint("Failed to create camera input: \(error)")
        }
    }
    
    func capturePhoto() async throws -> UIImage {
        let settings = AVCapturePhotoSettings()
        let delegate = PhotoCaptureDelegate()

        photoCaptureDelegate = delegate

        return try await withCheckedThrowingContinuation { continuation in
            delegate.continuation = continuation

            backPhotoOutput.capturePhoto(
                with: settings,
                delegate: delegate
            )
        }
    }

    func getBackCamera() -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }

    func getFrontCamera() -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    }

    func requestCameraAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            true
        case .notDetermined:
            await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            false
        @unknown default:
            false
        }
    }
}
