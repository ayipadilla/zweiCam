//
//  CameraSessionManager.swift
//  zweiCam
//
//  Created by Ayi Padilla on 25.08.26.
//

import AVFoundation
import UIKit

final class CameraSessionManager {

    // MARK: - Types

    private struct VideoPorts {
        let back: AVCaptureInput.Port
        let front: AVCaptureInput.Port
    }

    // MARK: - Properties

    private let multiCamSession = AVCaptureMultiCamSession()
    private var isSessionConfigured = false

    let backPreviewLayer = AVCaptureVideoPreviewLayer()
    let frontPreviewLayer = AVCaptureVideoPreviewLayer()

    private let backPhotoOutput = AVCapturePhotoOutput()
    private let frontPhotoOutput = AVCapturePhotoOutput()

    private let backVideoOutput = AVCaptureVideoDataOutput()
    private let frontVideoOutput = AVCaptureVideoDataOutput()
    private let audioOutput = AVCaptureAudioDataOutput()

    private let recordingManager = RecordingManager()

    private var photoCaptureDelegate: PhotoCaptureDelegate?
    private var isAudioConfigured = false
    private var isVideoCaptureConfigured = false
    private var isRecording = false
    private var videoPorts: VideoPorts?

    private let backVideoOutputQueue = DispatchQueue(
        label: "com.zweiCam.backVideoOutput"
    )

    private let frontVideoOutputQueue = DispatchQueue(
        label: "com.zweiCam.frontVideoOutput"
    )

    private let audioOutputQueue = DispatchQueue(
        label: "com.zweiCam.audioOutput"
    )

    private lazy var backSampleBufferDelegate = SampleBufferDelegate(
        streamName: "back video"
    ) { [weak self] sampleBuffer in
        self?.handleBackVideoSampleBuffer(sampleBuffer)
    }

    private lazy var frontSampleBufferDelegate = SampleBufferDelegate(
        streamName: "front video"
    ) { [weak self] sampleBuffer in
        self?.handleFrontVideoSampleBuffer(sampleBuffer)
    }

    private lazy var audioSampleBufferDelegate = SampleBufferDelegate(
        streamName: "audio"
    ) { [weak self] sampleBuffer in
        self?.handleAudioSampleBuffer(sampleBuffer)
    }

    // MARK: - Initialization

    init() {
        observeSessionInterruptions()
    }

    // MARK: - Setup

    func isMultiCamSupported() -> Bool {
        AVCaptureMultiCamSession.isMultiCamSupported
    }

    private func configureInputs(
        backCameraInput: AVCaptureDeviceInput,
        frontCameraInput: AVCaptureDeviceInput
    ) throws {
        guard multiCamSession.canAddInput(backCameraInput) else {
            throw CameraSessionError.cannotAddInput
        }

        guard multiCamSession.canAddInput(frontCameraInput) else {
            throw CameraSessionError.cannotAddInput
        }

        multiCamSession.addInputWithNoConnections(backCameraInput)
        multiCamSession.addInputWithNoConnections(frontCameraInput)
    }

    func configureVideoCapture() {
        guard !isVideoCaptureConfigured else {
            return
        }

        guard let videoPorts else {
            debugPrint("Video ports not configured")
            return
        }

        configureAudio()

        do {
            multiCamSession.beginConfiguration()

            defer {
                multiCamSession.commitConfiguration()
            }

            try configureVideoOutputs(
                backVideoPort: videoPorts.back,
                frontVideoPort: videoPorts.front
            )

            isVideoCaptureConfigured = true
        } catch {
            debugPrint("Failed to configure video outputs: \(error)")
        }
    }

    func configureAudio() {
        guard !isAudioConfigured else {
            return
        }

        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            debugPrint("Microphone not found")
            return
        }

        do {
            let microphoneInput = try AVCaptureDeviceInput(
                device: microphone
            )

            multiCamSession.beginConfiguration()

            defer {
                multiCamSession.commitConfiguration()
            }

            guard multiCamSession.canAddInput(microphoneInput) else {
                debugPrint("Cannot add microphone input to multi-cam session")
                return
            }

            multiCamSession.addInputWithNoConnections(microphoneInput)

            let audioPort = try getAudioPort(
                microphoneInput: microphoneInput,
                microphone: microphone
            )

            audioOutput.setSampleBufferDelegate(
                audioSampleBufferDelegate,
                queue: audioOutputQueue
            )

            guard multiCamSession.canAddOutput(audioOutput) else {
                debugPrint("Cannot add audio output to multi-cam session")
                throw CameraSessionError.cannotAddOutput
            }

            multiCamSession.addOutputWithNoConnections(audioOutput)

            let audioConnection = AVCaptureConnection(
                inputPorts: [audioPort],
                output: audioOutput
            )

            guard multiCamSession.canAddConnection(audioConnection) else {
                debugPrint("Cannot add audio connection to multi-cam session")
                throw CameraSessionError.cannotAddConnection
            }

            multiCamSession.addConnection(audioConnection)

            isAudioConfigured = true

            debugPrint("Microphone input and audio output configured")
        } catch {
            debugPrint("Failed to configure audio: \(error)")
        }
    }

    private func configureVideoOutputs(
        backVideoPort: AVCaptureInput.Port,
        frontVideoPort: AVCaptureInput.Port
    ) throws {
        backVideoOutput.setSampleBufferDelegate(
            backSampleBufferDelegate,
            queue: backVideoOutputQueue
        )

        frontVideoOutput.setSampleBufferDelegate(
            frontSampleBufferDelegate,
            queue: frontVideoOutputQueue
        )

        guard multiCamSession.canAddOutput(backVideoOutput) else {
            debugPrint("Cannot add back video output to multi-cam session")
            throw CameraSessionError.cannotAddOutput
        }

        guard multiCamSession.canAddOutput(frontVideoOutput) else {
            debugPrint("Cannot add front video output to multi-cam session")
            throw CameraSessionError.cannotAddOutput
        }

        multiCamSession.addOutputWithNoConnections(backVideoOutput)
        multiCamSession.addOutputWithNoConnections(frontVideoOutput)

        let backVideoConnection = AVCaptureConnection(
            inputPorts: [backVideoPort],
            output: backVideoOutput
        )

        let frontVideoConnection = AVCaptureConnection(
            inputPorts: [frontVideoPort],
            output: frontVideoOutput
        )

        guard multiCamSession.canAddConnection(backVideoConnection) else {
            debugPrint("Cannot add back video connection to multi-cam session")
            throw CameraSessionError.cannotAddConnection
        }

        guard multiCamSession.canAddConnection(frontVideoConnection) else {
            debugPrint("Cannot add front video connection to multi-cam session")
            throw CameraSessionError.cannotAddConnection
        }

        multiCamSession.addConnection(backVideoConnection)
        multiCamSession.addConnection(frontVideoConnection)

        debugPrint("Back and front video outputs configured")
    }

    private func getAudioPort(
        microphoneInput: AVCaptureDeviceInput,
        microphone: AVCaptureDevice
    ) throws -> AVCaptureInput.Port {
        guard let audioPort = microphoneInput.ports(
            for: .audio,
            sourceDeviceType: microphone.deviceType,
            sourceDevicePosition: microphone.position
        ).first else {
            debugPrint("Microphone audio port not found")
            throw CameraSessionError.audioPortNotFound
        }

        return audioPort
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

    func start() {
        if isSessionConfigured {
            guard !multiCamSession.isRunning else {
                return
            }
            
            multiCamSession.startRunning()
            debugPrint("Multi-cam session restarted")
            return
        }

        guard let backCamera = getBackCamera() else {
            debugPrint("Back camera not found")
            return
        }

        guard let frontCamera = getFrontCamera() else {
            debugPrint("Front camera not found")
            return
        }

        do {
            let backCameraInput = try AVCaptureDeviceInput(
                device: backCamera
            )

            let frontCameraInput = try AVCaptureDeviceInput(
                device: frontCamera
            )

            do {
                multiCamSession.beginConfiguration()

                defer {
                    multiCamSession.commitConfiguration()
                }

                try configureInputs(
                    backCameraInput: backCameraInput,
                    frontCameraInput: frontCameraInput
                )

                let videoPorts = try getVideoPorts(
                    backCameraInput: backCameraInput,
                    frontCameraInput: frontCameraInput,
                    backCamera: backCamera,
                    frontCamera: frontCamera
                )

                self.videoPorts = videoPorts

                try configurePreview(
                    backVideoPort: videoPorts.back,
                    frontVideoPort: videoPorts.front
                )

                try configurePhotoOutputs(
                    backVideoPort: videoPorts.back,
                    frontVideoPort: videoPorts.front
                )
                
                isSessionConfigured = true
            }

            multiCamSession.startRunning()

            debugPrint(
                "Back and front camera previews configured and multi-cam session started"
            )
        } catch {
            debugPrint("Failed to configure camera session: \(error)")
        }
    }

    func stop() {
        guard multiCamSession.isRunning else {
            return
        }

        multiCamSession.stopRunning()

        debugPrint("Multi-cam session stopped")
    }
    
    // MARK: - Session Lifecycle
    private func observeSessionInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSessionInterruption),
            name: AVCaptureSession.wasInterruptedNotification,
            object: multiCamSession
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSessionInterruptionEnded),
            name: AVCaptureSession.interruptionEndedNotification,
            object: multiCamSession
        )
    }
    
    @objc private func handleSessionInterruption(
        _ notification: Notification
    ) {
        debugPrint("Multi-cam session interrupted")

        if isRecording {
            Task {
                _ = await stopRecording()
            }
        }
    }

    @objc private func handleSessionInterruptionEnded(
        _ notification: Notification
    ) {
        debugPrint("Multi-cam session interruption ended")

        if !multiCamSession.isRunning {
            start()
        }
    }

    // MARK: - Sample Buffers

    private func handleBackVideoSampleBuffer(
        _ sampleBuffer: CMSampleBuffer
    ) {
        guard isRecording else {
            return
        }

        recordingManager.appendBackVideo(
            sampleBuffer: sampleBuffer
        )
    }

    private func handleFrontVideoSampleBuffer(
        _ sampleBuffer: CMSampleBuffer
    ) {
        guard isRecording else {
            return
        }

        recordingManager.appendFrontVideo(
            sampleBuffer: sampleBuffer
        )
    }

    private func handleAudioSampleBuffer(
        _ sampleBuffer: CMSampleBuffer
    ) {
        guard isRecording else {
            return
        }

        recordingManager.appendAudio(
            sampleBuffer: sampleBuffer
        )
    }

    // MARK: - Photo

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

    // MARK: - Camera Access

    func getBackCamera() -> AVCaptureDevice? {
        AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        )
    }

    func getFrontCamera() -> AVCaptureDevice? {
        AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        )
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

    // MARK: - Recording

    func startRecording() {
        guard !isRecording else {
            return
        }

        do {
            try recordingManager.startRecording()
            isRecording = true

            debugPrint("Recording started")
        } catch {
            debugPrint("Failed to start recording: \(error)")
        }
    }

    func stopRecording() async -> RecordingManager.RecordingResult? {
        guard isRecording else {
            return nil
        }

        isRecording = false

        do {
            let recording = try await recordingManager.stopRecording()

            debugPrint("Back video: \(recording.backVideoURL)")
            debugPrint("Front video: \(recording.frontVideoURL)")

            return recording
        } catch {
            debugPrint("Failed to stop recording: \(error)")
            return nil
        }
    }
}

private enum CameraSessionError: Error {
    case cannotAddInput
    case videoPortNotFound
    case audioPortNotFound
    case cannotAddOutput
    case cannotAddConnection
}
