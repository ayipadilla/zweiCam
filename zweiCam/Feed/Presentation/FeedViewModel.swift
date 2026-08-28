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

    // MARK: - Pagination

    private let pageSize = 20
    private var currentPage = 0
    private var isLoading = false
    private var hasMorePosts = true

    // MARK: - Lifecycle

    func onAppear() async {
        posts = []
        currentPage = 0
        hasMorePosts = true

        await loadNextPage()
    }

    // MARK: - Feed

    func loadMoreIfNeeded(currentPost: Post) async {
        guard
            currentPost.id == posts.last?.id,
            hasMorePosts,
            !isLoading
        else {
            return
        }

        await loadNextPage()
    }

    private func loadNextPage() async {
        guard !isLoading, hasMorePosts else {
            return
        }

        isLoading = true

        do {
            let offset = currentPage * pageSize

            let newPosts = try await mediaManager.loadPosts(
                limit: pageSize,
                offset: offset
            )

            posts.append(contentsOf: newPosts)
            currentPage += 1
            hasMorePosts = newPosts.count == pageSize
        } catch {
            debugPrint("Failed to load posts: \(error)")
        }

        isLoading = false
    }
}
