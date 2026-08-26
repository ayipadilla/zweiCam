//
//  MediaViewerScreen.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import SwiftUI

struct MediaViewerScreen: View {

    let post: Post

    var body: some View {

        ZStack {

            Color.black
                .ignoresSafeArea()

            VStack {

                RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
                .fill(Color.white.opacity(0.08))
                .aspectRatio(
                    3 / 4,
                    contentMode: .fit
                )
                .padding(.horizontal, 20)

                Spacer()

            }

        }
        .navigationTitle("19 August")
        .navigationBarTitleDisplayMode(.inline)

    }

}

//#Preview {
//
//    NavigationStack {
//        MediaViewerScreen(post: Post(/* ... */))
//    }
//
//}
