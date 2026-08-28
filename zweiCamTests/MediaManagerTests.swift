//
//  MediaManagerTests.swift
//  zweiCam
//
//  Created by Ayi Padilla on 28.08.26.
//

import Foundation
import Testing
@testable import zweiCam

struct MediaManagerTests {

    @Test
    func loadPostsReturnsEmptyArrayWhenNoPostsExist() async throws {
        let testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        let mediaManager = MediaManager(
            storageDirectory: testDirectory
        )

        let posts = try await mediaManager.loadPosts()

        #expect(posts.isEmpty)
    }
}
