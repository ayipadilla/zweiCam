//
//  PhotoCaptureDelegate.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import AVFoundation
import UIKit

enum PhotoCaptureError: Error {
    case failedToCreateImage
}

final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {

    var continuation: CheckedContinuation<UIImage, Error>?

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            finish(with: .failure(error))
            return
        }

        guard
            let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else {
            finish(with: .failure(PhotoCaptureError.failedToCreateImage))
            return
        }

        finish(with: .success(image))
    }

    private func finish(with result: Result<UIImage, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}
