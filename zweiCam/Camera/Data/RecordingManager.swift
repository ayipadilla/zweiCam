//
//  RecordingManager.swift
//  zweiCam
//
//  Created by Ayi Padilla on 27.08.26.
//

import AVFoundation

final class RecordingManager {

    private var isRecording = false
    private var recordingStartTime: CMTime?

    private var backVideoWriter: AVAssetWriter?
    private var frontVideoWriter: AVAssetWriter?

    private var backVideoInput: AVAssetWriterInput?
    private var frontVideoInput: AVAssetWriterInput?
    
    private var backVideoURL: URL?
    private var frontVideoURL: URL?

    func startRecording() throws {
        guard !isRecording else {
            return
        }

        recordingStartTime = nil

        let backVideoURL = createTemporaryURL(
            filename: "back.mov"
        )

        let frontVideoURL = createTemporaryURL(
            filename: "front.mov"
        )
        
        self.backVideoURL = backVideoURL
        self.frontVideoURL = frontVideoURL

        backVideoWriter = try AVAssetWriter(
            outputURL: backVideoURL,
            fileType: .mov
        )

        frontVideoWriter = try AVAssetWriter(
            outputURL: frontVideoURL,
            fileType: .mov
        )

        backVideoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: nil
        )

        frontVideoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: nil
        )

        guard
            let backVideoWriter,
            let frontVideoWriter,
            let backVideoInput,
            let frontVideoInput
        else {
            return
        }

        guard backVideoWriter.canAdd(backVideoInput) else {
            throw RecordingError.cannotAddBackVideoInput
        }

        guard frontVideoWriter.canAdd(frontVideoInput) else {
            throw RecordingError.cannotAddFrontVideoInput
        }

        backVideoWriter.add(backVideoInput)
        frontVideoWriter.add(frontVideoInput)

        isRecording = true

        debugPrint("Recording writers configured")
    }

    func stopRecording() async throws -> (
        backVideoURL: URL,
        frontVideoURL: URL
    ) {
        guard isRecording,
              let backVideoWriter,
              let frontVideoWriter,
              let backVideoInput,
              let frontVideoInput,
              let backVideoURL,
              let frontVideoURL
        else {
            throw RecordingError.recordingNotFound
        }

        isRecording = false

        backVideoInput.markAsFinished()
        frontVideoInput.markAsFinished()

        await backVideoWriter.finishWriting()
        await frontVideoWriter.finishWriting()

        guard backVideoWriter.status == .completed else {
            throw RecordingError.backVideoWritingFailed
        }

        guard frontVideoWriter.status == .completed else {
            throw RecordingError.frontVideoWritingFailed
        }

        debugPrint("Back and front video recordings finished")

        return (
            backVideoURL: backVideoURL,
            frontVideoURL: frontVideoURL
        )
    }

    func appendBackVideo(
        sampleBuffer: CMSampleBuffer
    ) {
        appendVideo(
            sampleBuffer: sampleBuffer,
            writer: backVideoWriter,
            input: backVideoInput
        )
    }

    func appendFrontVideo(
        sampleBuffer: CMSampleBuffer
    ) {
        appendVideo(
            sampleBuffer: sampleBuffer,
            writer: frontVideoWriter,
            input: frontVideoInput
        )
    }
    
    private func appendVideo(
        sampleBuffer: CMSampleBuffer,
        writer: AVAssetWriter?,
        input: AVAssetWriterInput?
    ) {
        guard isRecording,
              let writer,
              let input
        else {
            return
        }

        let presentationTime = CMSampleBufferGetPresentationTimeStamp(
            sampleBuffer
        )

        if recordingStartTime == nil {
            recordingStartTime = presentationTime
        }

        if writer.status == .unknown {
            writer.startWriting()

            if let recordingStartTime {
                writer.startSession(
                    atSourceTime: recordingStartTime
                )
            }
        }

        guard writer.status == .writing else {
            return
        }

        guard input.isReadyForMoreMediaData else {
            return
        }

        input.append(sampleBuffer)
    }

    func appendAudio(
        sampleBuffer: CMSampleBuffer
    ) {
        guard isRecording else {
            return
        }

        // Later step
    }

    private func createTemporaryURL(
        filename: String
    ) -> URL {

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        try? FileManager.default.removeItem(at: url)

        return url
    }

}

private enum RecordingError: Error {
    case cannotAddBackVideoInput
    case cannotAddFrontVideoInput
    case recordingNotFound
    case backVideoWritingFailed
    case frontVideoWritingFailed
}
