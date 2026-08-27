//
//  SampleBufferDelegate.swift
//  zweiCam
//
//  Created by Ayi Padilla on 27.08.26.
//

import AVFoundation

final class SampleBufferDelegate: NSObject,
    AVCaptureVideoDataOutputSampleBufferDelegate,
    AVCaptureAudioDataOutputSampleBufferDelegate {

    let streamName: String

    var onSampleBuffer: ((CMSampleBuffer) -> Void)?

    init(
        streamName: String,
        onSampleBuffer: ((CMSampleBuffer) -> Void)? = nil
    ) {
        self.streamName = streamName
        self.onSampleBuffer = onSampleBuffer
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        onSampleBuffer?(sampleBuffer)
    }

}
