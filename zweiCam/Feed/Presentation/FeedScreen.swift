//
//  FeedScreen.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import SwiftUI

struct FeedScreen: View {

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack {
                Spacer()
            }
        }
        .navigationTitle("Your Feed")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FeedScreen()
    }
}
