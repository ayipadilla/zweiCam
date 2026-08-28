//
//  RecordingManager.swift
//  zweiCam
//
//  Created by Ayi Padilla on 27.08.26.
//

import AVFoundation
import UIKit

final class RecordingManager {

    // MARK: - Types

    struct RecordingResult {
        let backVideoURL: URL
        let frontVideoURL: URL
        let audioURL: URL?
        let backThumbnail: UIImage
        let frontThumbnail: UIImage
    }

    // MARK: - State

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

    private var backThumbnail: UIImage?
    private var frontThumbnail: UIImage?

    // MARK: - Recording

    func startRecording() throws {
        guard !isRecording else {
            return
        }

        recordingStartTime = nil
        backThumbnail = nil
        frontThumbnail = nil

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
            let audioWriter,
            let audioInput
        else {
            return
        }

        guard audioWriter.canAdd(audioInput) else {
            throw RecordingError.cannotAddAudioInput
        }

        audioWriter.add(audioInput)
        isRecording = true

        debugPrint("Recording writers configured")
    }

    func stopRecording() async throws -> RecordingResult {
        guard
            isRecording,
            let backVideoWriter,
            let frontVideoWriter,
            let audioWriter,
            let backVideoURL,
            let frontVideoURL,
            let audioURL,
            let backThumbnail,
            let frontThumbnail
        else {
            throw RecordingError.recordingNotFound
        }

        isRecording = false

        backVideoInput?.markAsFinished()
        frontVideoInput?.markAsFinished()
        audioInput?.markAsFinished()

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

        return RecordingResult(
            backVideoURL: backVideoURL,
            frontVideoURL: frontVideoURL,
            audioURL: audioURL,
            backThumbnail: backThumbnail,
            frontThumbnail: frontThumbnail
        )
    }

    // MARK: - Video

    func appendBackVideo(
        sampleBuffer: CMSampleBuffer
    ) {
        appendVideo(
            sampleBuffer: sampleBuffer,
            writer: backVideoWriter,
            input: backVideoInput,
            setInput: { [weak self] input in
                self?.backVideoInput = input
            },
            shouldCaptureThumbnail: { [weak self] in
                self?.backThumbnail == nil
            },
            setThumbnail: { [weak self] thumbnail in
                self?.backThumbnail = thumbnail
            }
        )
    }

    func appendFrontVideo(
        sampleBuffer: CMSampleBuffer
    ) {
        appendVideo(
            sampleBuffer: sampleBuffer,
            writer: frontVideoWriter,
            input: frontVideoInput,
            setInput: { [weak self] input in
                self?.frontVideoInput = input
            },
            shouldCaptureThumbnail: { [weak self] in
                self?.frontThumbnail == nil
            },
            setThumbnail: { [weak self] thumbnail in
                self?.frontThumbnail = thumbnail
            }
        )
    }

    private func appendVideo(
        sampleBuffer: CMSampleBuffer,
        writer: AVAssetWriter?,
        input: AVAssetWriterInput?,
        setInput: (AVAssetWriterInput) -> Void,
        shouldCaptureThumbnail: () -> Bool,
        setThumbnail: (UIImage) -> Void
    ) {
        guard
            isRecording,
            let writer
        else {
            return
        }

        let presentationTime = CMSampleBufferGetPresentationTimeStamp(
            sampleBuffer
        )

        if recordingStartTime == nil {
            recordingStartTime = presentationTime
        }

        var videoInput = input

        if videoInput == nil {
            guard let formatDescription =
                CMSampleBufferGetFormatDescription(sampleBuffer)
            else {
                return
            }

            let dimensions = CMVideoFormatDescriptionGetDimensions(
                formatDescription
            )

            let newInput = AVAssetWriterInput(
                mediaType: .video,
                outputSettings: [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: Int(dimensions.width),
                    AVVideoHeightKey: Int(dimensions.height)
                ]
            )

            newInput.transform = CGAffineTransform(rotationAngle: .pi / 2)

            guard writer.canAdd(newInput) else {
                return
            }

            writer.add(newInput)
            setInput(newInput)
            videoInput = newInput

            guard writer.status == .unknown else {
                return
            }

            writer.startWriting()

            if let recordingStartTime {
                writer.startSession(
                    atSourceTime: recordingStartTime
                )
            }
        }

        guard
            writer.status == .writing,
            let videoInput,
            videoInput.isReadyForMoreMediaData
        else {
            return
        }

        if shouldCaptureThumbnail(),
           let image = image(from: sampleBuffer) {
            setThumbnail(image)
        }

        videoInput.append(sampleBuffer)
    }

    // MARK: - Audio

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

    // MARK: - Helpers

    private func image(
        from sampleBuffer: CMSampleBuffer
    ) -> UIImage? {
        guard
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else {
            return nil
        }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()

        guard let cgImage = context.createCGImage(
            ciImage,
            from: ciImage.extent
        ) else {
            return nil
        }

        return UIImage(
            cgImage: cgImage,
            scale: 1.0,
            orientation: .right
        )
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

// MARK: - Errors

private enum RecordingError: Error {
    case cannotAddAudioInput
    case recordingNotFound
    case backVideoWritingFailed
    case frontVideoWritingFailed
    case audioWritingFailed
}
