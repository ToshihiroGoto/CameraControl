//
//  CameraPreview.swift
//  CameraControl
//
//  Created by Toshihiro Goto on 2024/10/27.
//

import AVFoundation
import AVKit
import SwiftUI

public struct CameraPreview: UIViewRepresentable {
    let previewFrame: CGRect
    let captureModel: CaptureModel
    
    public func makeUIView(context: Context) -> UICameraPreview {
        let view = UICameraPreview(frame: previewFrame, session: self.captureModel.captureSession)
        view.setupPreview(previewSize: previewFrame)

        // カメラコントロール & 音量ボタンで撮影する
        let interaction = AVCaptureEventInteraction { event in
            if event.phase == .began {
                self.captureModel.takePhoto()
            }
        }
        view.addInteraction(interaction)

        return view
    }
    
    public func updateUIView(_ uiView: UICameraPreview, context: Context) {
        self.captureModel.updateInputOrientation(orientation: UIDevice.current.orientation)
        uiView.updateFrame(frame: previewFrame)
    }
}
