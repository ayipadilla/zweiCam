//
//  FeedScreen.swift
//  zweiCam
//
//  Created by Ayi Padilla on 26.08.26.
//

import SwiftUI

struct FeedScreen: View {

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 2),
        count: 4
    )

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ScrollView {
                LazyVGrid(
                    columns: columns,
                    spacing: 2
                ) {
                    ForEach(0..<20, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .aspectRatio(3.0 / 4.0, contentMode: .fit)
                    }
                }
                .padding(.horizontal, 2)
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
