//
//  Post.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import Foundation

enum MediaType: String, Codable {
    case photo
    case video
}

struct Post: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let mediaType: MediaType
    let backMediaPath: String
    let frontMediaPath: String
    let audioMediaPath: String?
    let thumbnailPath: String
}
