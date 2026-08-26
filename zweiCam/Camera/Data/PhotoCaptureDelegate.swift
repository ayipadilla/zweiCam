//
//  PhotoCaptureDelegate.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import AVFoundation
import UIKit

final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {

    var continuation: CheckedContinuation<UIImage, Error>?

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            continuation?.resume(throwing: error)
            return
        }

        guard
            let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else {
            continuation?.resume(
                throwing: PhotoCaptureError.failedToCreateImage
            )
            return
        }

        continuation?.resume(returning: image)
    }
}

enum PhotoCaptureError: Error {
    case failedToCreateImage
}
