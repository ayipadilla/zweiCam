//
//  CameraSessionManager.swift
//  zweiCam
//
//  Created by Ayi Padilla on 25.08.26.
//

import AVFoundation
import UIKit

final class CameraSessionManager {
    private struct VideoPorts {
        let back: AVCaptureInput.Port
        let front: AVCaptureInput.Port
    }
    
    private func configureInputs(
        backCameraInput: AVCaptureDeviceInput,
        frontCameraInput: AVCaptureDeviceInput,
        microphoneInput: AVCaptureDeviceInput
    ) throws {
        guard multiCamSession.canAddInput(backCameraInput) else {
            debugPrint("Cannot add back camera input to multi-cam session")
            throw CameraSessionError.cannotAddInput
        }
        
        guard multiCamSession.canAddInput(frontCameraInput) else {
            debugPrint("Cannot add front camera input to multi-cam session")
            throw CameraSessionError.cannotAddInput
        }
        
        guard multiCamSession.canAddInput(microphoneInput) else {
            debugPrint("Cannot add microphone input to multi-cam session")
            throw CameraSessionError.cannotAddInput
        }
        
        multiCamSession.addInputWithNoConnections(backCameraInput)
        multiCamSession.addInputWithNoConnections(frontCameraInput)
        multiCamSession.addInputWithNoConnections(microphoneInput)
    }
    
    private func getVideoPorts(
        backCameraInput: AVCaptureDeviceInput,
        frontCameraInput: AVCaptureDeviceInput,
        backCamera: AVCaptureDevice,
        frontCamera: AVCaptureDevice
    ) throws -> VideoPorts {
        guard let backVideoPort = backCameraInput.ports(
            for: .video,
            sourceDeviceType: backCamera.deviceType,
            sourceDevicePosition: backCamera.position
        ).first else {
            debugPrint("Back camera video port not found")
            throw CameraSessionError.videoPortNotFound
        }
        
        guard let frontVideoPort = frontCameraInput.ports(
            for: .video,
            sourceDeviceType: frontCamera.deviceType,
            sourceDevicePosition: frontCamera.position
        ).first else {
            debugPrint("Front camera video port not found")
            throw CameraSessionError.videoPortNotFound
        }
        
        return VideoPorts(
            back: backVideoPort,
            front: frontVideoPort
        )
    }
    
    private func configurePreview(
        backVideoPort: AVCaptureInput.Port,
        frontVideoPort: AVCaptureInput.Port
    ) throws {
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
            throw CameraSessionError.cannotAddConnection
        }
        
        guard multiCamSession.canAddConnection(frontPreviewConnection) else {
            debugPrint("Cannot add front preview connection to multi-cam session")
            throw CameraSessionError.cannotAddConnection
        }
        
        multiCamSession.addConnection(backPreviewConnection)
        multiCamSession.addConnection(frontPreviewConnection)
    }
    
    private func configurePhotoOutputs(
        backVideoPort: AVCaptureInput.Port,
        frontVideoPort: AVCaptureInput.Port
    ) throws {
        guard multiCamSession.canAddOutput(backPhotoOutput) else {
            debugPrint("Cannot add back photo output to multi-cam session")
            throw CameraSessionError.cannotAddOutput
        }
        
        guard multiCamSession.canAddOutput(frontPhotoOutput) else {
            debugPrint("Cannot add front photo output to multi-cam session")
            throw CameraSessionError.cannotAddOutput
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
            throw CameraSessionError.cannotAddConnection
        }
        
        guard multiCamSession.canAddConnection(frontPhotoConnection) else {
            debugPrint("Cannot add front photo connection to multi-cam session")
            throw CameraSessionError.cannotAddConnection
        }
        
        multiCamSession.addConnection(backPhotoConnection)
        multiCamSession.addConnection(frontPhotoConnection)
    }
    
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

        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            debugPrint("Microphone not found")
            return
        }

        do {
            let backCameraInput = try AVCaptureDeviceInput(
                device: backCamera
            )
            let frontCameraInput = try AVCaptureDeviceInput(
                device: frontCamera
            )
            let microphoneInput = try AVCaptureDeviceInput(
                device: microphone
            )

            do {
                multiCamSession.beginConfiguration()
                defer {
                    multiCamSession.commitConfiguration()
                }

                try configureInputs(
                    backCameraInput: backCameraInput,
                    frontCameraInput: frontCameraInput,
                    microphoneInput: microphoneInput
                )

                let videoPorts = try getVideoPorts(
                    backCameraInput: backCameraInput,
                    frontCameraInput: frontCameraInput,
                    backCamera: backCamera,
                    frontCamera: frontCamera
                )

                try configurePreview(
                    backVideoPort: videoPorts.back,
                    frontVideoPort: videoPorts.front
                )

                try configurePhotoOutputs(
                    backVideoPort: videoPorts.back,
                    frontVideoPort: videoPorts.front
                )
            }

            multiCamSession.startRunning()

            debugPrint(
                "Back and front camera previews configured and multi-cam session started"
            )
        } catch {
            debugPrint("Failed to configure camera session: \(error)")
        }
    }
    
    private func capturePhoto(
        from photoOutput: AVCapturePhotoOutput
    ) async throws -> UIImage {
        
        let settings = AVCapturePhotoSettings()
        let delegate = PhotoCaptureDelegate()
        
        photoCaptureDelegate = delegate
        
        return try await withCheckedThrowingContinuation { continuation in
            delegate.continuation = continuation
            
            photoOutput.capturePhoto(
                with: settings,
                delegate: delegate
            )
        }
    }
    
    func captureDualPhoto() async throws -> (
        backImage: UIImage,
        frontImage: UIImage
    ) {
        let backImage = try await capturePhoto(
            from: backPhotoOutput
        )
        
        try await Task.sleep(for: .seconds(1.5))
        
        let frontImage = try await capturePhoto(
            from: frontPhotoOutput
        )
        
        return (
            backImage: backImage,
            frontImage: frontImage
        )
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
    
    func requestMicrophoneAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            true
        case .notDetermined:
            await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            false
        @unknown default:
            false
        }
    }
}

private enum CameraSessionError: Error {
    case cannotAddInput
    case videoPortNotFound
    case cannotAddOutput
    case cannotAddConnection
}
