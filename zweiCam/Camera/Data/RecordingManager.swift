//
//  RecordingManager.swift
//  zweiCam
//
//  Created by Ayi Padilla on 27.08.26.
//

import AVFoundation

final class RecordingManager {

    private var isRecording = false

    func startRecording() {
        guard !isRecording else {
            return
        }

        isRecording = true

        debugPrint("Recording started")
    }

    func stopRecording() {
        guard isRecording else {
            return
        }

        isRecording = false

        debugPrint("Recording stopped")
    }

    func appendBackVideo(
        sampleBuffer: CMSampleBuffer
    ) {
        guard isRecording else {
            return
        }

        // Step 5B
    }

    func appendFrontVideo(
        sampleBuffer: CMSampleBuffer
    ) {
        guard isRecording else {
            return
        }

        // Step 5B
    }

    func appendAudio(
        sampleBuffer: CMSampleBuffer
    ) {
        guard isRecording else {
            return
        }

        // Step 5C
    }

}
