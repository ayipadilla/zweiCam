//
//  MediaManager.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import Foundation
import UIKit

actor MediaManager {

    private enum Storage {
        static let mediaDirectoryName = "Media"
        static let postsFileName = "posts.json"
    }

    // MARK: - Posts

    func savePost(
        backImage: UIImage,
        frontImage: UIImage
    ) async throws -> Post {

        let postID = UUID()

        let backMediaPath = try await saveImage(
            backImage,
            postID: postID
        )

        let frontMediaPath = try await saveImage(
            frontImage,
            postID: postID
        )

        let thumbnailImage = createThumbnail(
            backImage: backImage,
            frontImage: frontImage
        )

        let thumbnailPath = try await saveImage(
            thumbnailImage,
            postID: postID
        )

        let post = Post(
            id: postID,
            createdAt: Date(),
            mediaType: .photo,
            backMediaPath: backMediaPath,
            frontMediaPath: frontMediaPath,
            thumbnailPath: thumbnailPath
        )

        var posts = try loadPosts()
        posts.append(post)

        try savePosts(posts)

        return post
    }

    func loadPosts() throws -> [Post] {
        let postsFileURL = try postsFileURL()

        guard FileManager.default.fileExists(atPath: postsFileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: postsFileURL)

        return try JSONDecoder().decode(
            [Post].self,
            from: data
        )
    }

    // MARK: - Media

    func loadImage(
        atRelativePath relativePath: String
    ) throws -> UIImage {
        let fileURL = try fileURL(
            forRelativePath: relativePath
        )

        guard let image = UIImage(
            contentsOfFile: fileURL.path
        ) else {
            throw MediaManagerError.failedToLoadImage
        }

        return image
    }

    private func saveImage(
        _ image: UIImage,
        postID: UUID
    ) async throws -> String {

        let mediaID = UUID()
        let relativePath = "\(Storage.mediaDirectoryName)/\(postID.uuidString)/\(mediaID.uuidString).jpg"

        let fileURL = try fileURL(
            forRelativePath: relativePath
        )

        let imageData = try await Task.detached(priority: .utility) {
            guard let data = image.jpegData(compressionQuality: 0.9) else {
                throw MediaManagerError.failedToCreateImageData
            }

            return data
        }.value

        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        try imageData.write(
            to: fileURL,
            options: .atomic
        )

        return relativePath
    }

    private func createThumbnail(
        backImage: UIImage,
        frontImage: UIImage
    ) -> UIImage {

        let thumbnailWidth: CGFloat = 600

        let backAspectRatio =
            backImage.size.height / backImage.size.width

        let thumbnailSize = CGSize(
            width: thumbnailWidth,
            height: thumbnailWidth * backAspectRatio
        )

        let renderer = UIGraphicsImageRenderer(
            size: thumbnailSize
        )

        return renderer.image { _ in

            backImage.draw(
                in: CGRect(
                    origin: .zero,
                    size: thumbnailSize
                )
            )

            let inset = thumbnailWidth * 0.04
            let frontWidth = thumbnailWidth * 0.32
            let frontAspectRatio: CGFloat = 3.0 / 4.0
            let frontHeight = frontWidth / frontAspectRatio

            let frontRect = CGRect(
                x: inset,
                y: inset,
                width: frontWidth,
                height: frontHeight
            )

            let frontPath = UIBezierPath(
                roundedRect: frontRect,
                cornerRadius: 14
            )

            frontPath.addClip()

            frontImage.draw(in: frontRect)

            UIColor.black.setStroke()
            frontPath.lineWidth = 3
            frontPath.stroke()
        }
    }

    // MARK: - Storage

    private func savePosts(
        _ posts: [Post]
    ) throws {

        let postsFileURL = try postsFileURL()

        let directoryURL = postsFileURL.deletingLastPathComponent()

        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        let data = try encoder.encode(posts)

        try data.write(
            to: postsFileURL,
            options: .atomic
        )
    }

    private func postsFileURL() throws -> URL {
        try applicationSupportDirectory()
            .appendingPathComponent(
                Storage.postsFileName
            )
    }

    private func fileURL(
        forRelativePath relativePath: String
    ) throws -> URL {

        try applicationSupportDirectory()
            .appendingPathComponent(relativePath)
    }

    private func applicationSupportDirectory() throws -> URL {

        guard let directoryURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw MediaManagerError.applicationSupportDirectoryNotFound
        }

        return directoryURL
    }
}

// MARK: - Errors

private enum MediaManagerError: Error {
    case applicationSupportDirectoryNotFound
    case failedToCreateImageData
    case failedToLoadImage
}
