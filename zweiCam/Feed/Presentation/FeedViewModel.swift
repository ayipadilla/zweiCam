//
//  FeedViewModel.swift
//  zweiCam
//
//  Created by Ayi Padilla on 28.08.26.
//

import Observation

@MainActor
@Observable
final class FeedViewModel {

    // MARK: - Dependencies

    private let mediaManager = MediaManager()

    // MARK: - State

    var posts: [Post] = []

    // MARK: - Lifecycle

    func onAppear() async {
        await loadPosts()
    }

    // MARK: - Feed

    private func loadPosts() async {
        do {
            posts = try await mediaManager.loadPosts()
        } catch {
            debugPrint("Failed to load posts: \(error)")
        }
    }
}
