//
//  CameraPreviewView.swift
//  zweiCam
//
//  Created by Ayi Padilla on 25.08.26.
//

import AVFoundation
import SwiftUI
import UIKit

struct CameraPreviewView: UIViewRepresentable {
    let backPreviewLayer: AVCaptureVideoPreviewLayer
    let frontPreviewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView(
            backPreviewLayer: backPreviewLayer,
            frontPreviewLayer: frontPreviewLayer
        )
        backPreviewLayer.videoGravity = .resizeAspectFill
        frontPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.updatePreviewLayers(
            backPreviewLayer: backPreviewLayer,
            frontPreviewLayer: frontPreviewLayer
        )
    }
}

final class PreviewContainerView: UIView {
    private enum Layout {
        static let frontPreviewInsetRatio: CGFloat = 0.04
        static let frontPreviewWidthRatio: CGFloat = 0.32
        static let frontPreviewAspectRatio: CGFloat = 3 / 4
        static let frontPreviewCornerRadius: CGFloat = 14
        static let frontPreviewBorderWidth: CGFloat = 3
    }

    private var backPreviewLayer: AVCaptureVideoPreviewLayer
    private var frontPreviewLayer: AVCaptureVideoPreviewLayer

    init(
        backPreviewLayer: AVCaptureVideoPreviewLayer,
        frontPreviewLayer: AVCaptureVideoPreviewLayer
    ) {
        self.backPreviewLayer = backPreviewLayer
        self.frontPreviewLayer = frontPreviewLayer
        super.init(frame: .zero)

        clipsToBounds = true
        layer.addSublayer(backPreviewLayer)
        layer.addSublayer(frontPreviewLayer)
        configureFrontPreviewLayer()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        backPreviewLayer.frame = bounds

        let frontPreviewInset = bounds.width * Layout.frontPreviewInsetRatio
        let frontPreviewWidth = min(
            bounds.width * Layout.frontPreviewWidthRatio,
            bounds.height * 0.28
        )
        let frontPreviewHeight = frontPreviewWidth / Layout.frontPreviewAspectRatio

        frontPreviewLayer.frame = CGRect(
            x: frontPreviewInset,
            y: frontPreviewInset,
            width: frontPreviewWidth,
            height: frontPreviewHeight
        )
    }

    func updatePreviewLayers(
        backPreviewLayer: AVCaptureVideoPreviewLayer,
        frontPreviewLayer: AVCaptureVideoPreviewLayer
    ) {
        if self.backPreviewLayer !== backPreviewLayer {
            self.backPreviewLayer.removeFromSuperlayer()
            self.backPreviewLayer = backPreviewLayer
            layer.insertSublayer(backPreviewLayer, at: 0)
        }

        if self.frontPreviewLayer !== frontPreviewLayer {
            self.frontPreviewLayer.removeFromSuperlayer()
            self.frontPreviewLayer = frontPreviewLayer
            layer.addSublayer(frontPreviewLayer)
            configureFrontPreviewLayer()
        }

        setNeedsLayout()
    }

    private func configureFrontPreviewLayer() {
        frontPreviewLayer.cornerRadius = Layout.frontPreviewCornerRadius
        frontPreviewLayer.masksToBounds = true
        frontPreviewLayer.borderColor = UIColor.black.cgColor
        frontPreviewLayer.borderWidth = Layout.frontPreviewBorderWidth
    }
}

#Preview {
    CameraPreviewView(
        backPreviewLayer: AVCaptureVideoPreviewLayer(),
        frontPreviewLayer: AVCaptureVideoPreviewLayer()
    )
}
