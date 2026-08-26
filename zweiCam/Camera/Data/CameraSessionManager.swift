//
//  CameraSessionManager.swift
//  zweiCam
//
//  Created by Ayi Padilla on 25.08.26.
//

import AVFoundation

final class CameraSessionManager {
    private let multiCamSession = AVCaptureMultiCamSession()
    let backPreviewLayer = AVCaptureVideoPreviewLayer()
    
    func isMultiCamSupported() -> Bool {
        AVCaptureMultiCamSession.isMultiCamSupported
    }
    
    func start() {
        guard let backCamera = getBackCamera() else {
            debugPrint("Back camera not found")
            return
        }

        do {
            let backCameraInput = try AVCaptureDeviceInput(device: backCamera)

            do {
                multiCamSession.beginConfiguration()
                defer { multiCamSession.commitConfiguration() }

                guard multiCamSession.canAddInput(backCameraInput) else {
                    debugPrint("Cannot add back camera input to multi-cam session")
                    return
                }

                multiCamSession.addInputWithNoConnections(backCameraInput)

                guard let backVideoPort = backCameraInput.ports(
                    for: .video,
                    sourceDeviceType: backCamera.deviceType,
                    sourceDevicePosition: backCamera.position
                ).first else {
                    debugPrint("Back camera video port not found")
                    return
                }

                backPreviewLayer.setSessionWithNoConnection(multiCamSession)

                let backPreviewConnection = AVCaptureConnection(
                    inputPort: backVideoPort,
                    videoPreviewLayer: backPreviewLayer
                )

                guard multiCamSession.canAddConnection(backPreviewConnection) else {
                    debugPrint("Cannot add back preview connection to multi-cam session")
                    return
                }

                multiCamSession.addConnection(backPreviewConnection)
            }

            multiCamSession.startRunning()
            debugPrint("Back camera preview configured and multi-cam session started")
        } catch {
            debugPrint("Failed to create back camera input: \(error)")
        }
    }

    func getBackCamera() -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
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
