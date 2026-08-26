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
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView(previewLayer: previewLayer)
        previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.updatePreviewLayer(previewLayer)
    }
}

final class PreviewContainerView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer

    init(previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer
        super.init(frame: .zero)
        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }

    func updatePreviewLayer(_ previewLayer: AVCaptureVideoPreviewLayer) {
        guard self.previewLayer !== previewLayer else { return }

        self.previewLayer.removeFromSuperlayer()
        self.previewLayer = previewLayer
        layer.addSublayer(previewLayer)
        setNeedsLayout()
    }
}

#Preview {
    CameraPreviewView(previewLayer: AVCaptureVideoPreviewLayer())
}
