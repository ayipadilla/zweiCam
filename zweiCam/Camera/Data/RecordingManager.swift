//
//  RecordingManager.swift
//  zweiCam
//
//  Created by Ayi Padilla on 27.08.26.
//

import AVFoundation
import UIKit

final class RecordingManager {
    
    struct VideoThumbnails {
        let back: UIImage
        let front: UIImage
    }

    private var isRecording = false
    private var recordingStartTime: CMTime?

    private var backVideoWriter: AVAssetWriter?
    private var frontVideoWriter: AVAssetWriter?
    private var audioWriter: AVAssetWriter?

    private var backVideoInput: AVAssetWriterInput?
    private var frontVideoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    
    private var backVideoURL: URL?
    private var frontVideoURL: URL?
    private var audioURL: URL?

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
        
        let audioURL = createTemporaryURL(
            filename: "audio.m4a"
        )

        self.backVideoURL = backVideoURL
        self.frontVideoURL = frontVideoURL
        self.audioURL = audioURL

        backVideoWriter = try AVAssetWriter(
            outputURL: backVideoURL,
            fileType: .mov
        )

        frontVideoWriter = try AVAssetWriter(
            outputURL: frontVideoURL,
            fileType: .mov
        )
        
        audioWriter = try AVAssetWriter(
            outputURL: audioURL,
            fileType: .m4a
        )

        backVideoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: nil
        )

        frontVideoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: nil
        )
        
        audioInput = AVAssetWriterInput(
            mediaType: .audio,
            outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderBitRateKey: 128_000
            ]
        )

        guard
            let backVideoWriter,
            let frontVideoWriter,
            let audioWriter,
            let backVideoInput,
            let frontVideoInput,
            let audioInput
        else {
            return
        }

        guard backVideoWriter.canAdd(backVideoInput) else {
            throw RecordingError.cannotAddBackVideoInput
        }

        guard frontVideoWriter.canAdd(frontVideoInput) else {
            throw RecordingError.cannotAddFrontVideoInput
        }
        
        guard audioWriter.canAdd(audioInput) else {
            throw RecordingError.cannotAddAudioInput
        }

        backVideoWriter.add(backVideoInput)
        frontVideoWriter.add(frontVideoInput)
        audioWriter.add(audioInput)
        
        isRecording = true

        debugPrint("Recording writers configured")
    }

    func stopRecording() async throws -> (
        backVideoURL: URL,
        frontVideoURL: URL,
        audioURL: URL
    ) {
        guard isRecording,
              let backVideoWriter,
              let frontVideoWriter,
              let audioWriter,
              let backVideoInput,
              let frontVideoInput,
              let audioInput,
              let backVideoURL,
              let frontVideoURL,
              let audioURL
        else {
            throw RecordingError.recordingNotFound
        }

        isRecording = false

        backVideoInput.markAsFinished()
        frontVideoInput.markAsFinished()
        audioInput.markAsFinished()

        await backVideoWriter.finishWriting()
        await frontVideoWriter.finishWriting()
        await audioWriter.finishWriting()

        guard backVideoWriter.status == .completed else {
            throw RecordingError.backVideoWritingFailed
        }

        guard frontVideoWriter.status == .completed else {
            throw RecordingError.frontVideoWritingFailed
        }
        
        guard audioWriter.status == .completed else {
            throw RecordingError.audioWritingFailed
        }

        debugPrint("Back + front video and audio recordings finished")

        return (
            backVideoURL: backVideoURL,
            frontVideoURL: frontVideoURL,
            audioURL: audioURL
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
        guard
            isRecording,
            let audioWriter,
            let audioInput
        else {
            return
        }

        let presentationTime = CMSampleBufferGetPresentationTimeStamp(
            sampleBuffer
        )

        if recordingStartTime == nil {
            recordingStartTime = presentationTime
        }

        if audioWriter.status == .unknown {
            audioWriter.startWriting()

            if let recordingStartTime {
                audioWriter.startSession(
                    atSourceTime: recordingStartTime
                )
            }
        }

        guard audioWriter.status == .writing else {
            return
        }

        guard audioInput.isReadyForMoreMediaData else {
            return
        }

        audioInput.append(sampleBuffer)
    }

    private func createTemporaryURL(
        filename: String
    ) -> URL {

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        try? FileManager.default.removeItem(at: url)

        return url
    }
    
    func generateThumbnails(
        backVideoURL: URL,
        frontVideoURL: URL
    ) async throws -> VideoThumbnails {

        async let backThumbnail = generateThumbnail(
            from: backVideoURL
        )

        async let frontThumbnail = generateThumbnail(
            from: frontVideoURL
        )

        return try await VideoThumbnails(
            back: backThumbnail,
            front: frontThumbnail
        )
    }
    
    private func generateThumbnail(
        from videoURL: URL
    ) async throws -> UIImage {

        let asset = AVURLAsset(url: videoURL)

        let imageGenerator = AVAssetImageGenerator(
            asset: asset
        )

        imageGenerator.appliesPreferredTrackTransform = true

        let cgImage = try await imageGenerator.image(
            at: .zero
        ).image

        return UIImage(cgImage: cgImage)
    }

}

private enum RecordingError: Error {
    case cannotAddBackVideoInput
    case cannotAddFrontVideoInput
    case cannotAddAudioInput
    case recordingNotFound
    case backVideoWritingFailed
    case frontVideoWritingFailed
    case audioWritingFailed
}
