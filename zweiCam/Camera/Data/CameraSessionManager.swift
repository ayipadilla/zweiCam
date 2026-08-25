//
//  CameraSessionManager.swift
//  zweiCam
//
//  Created by Ayi Padilla on 25.08.26.
//

import AVFoundation

final class CameraSessionManager {
    func isMultiCamSupported() -> Bool {
        AVCaptureMultiCamSession.isMultiCamSupported
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
