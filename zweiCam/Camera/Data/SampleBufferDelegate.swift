//
//  SampleBufferDelegate.swift
//  zweiCam
//
//  Created by Ayi Padilla on 27.08.26.
//

import AVFoundation

final class SampleBufferDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    let streamName: String

    init(streamName: String) {
        self.streamName = streamName
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        debugPrint("Received \(streamName) sample buffer")
    }
}
