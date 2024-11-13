//
//  UICameraPreview.swift
//  CameraControl
//
//  Created by Toshihiro Goto on 2024/10/27.
//

import UIKit
import AVFoundation
import AVKit

public class UICameraPreview: UIView {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    public init(frame: CGRect, session: AVCaptureSession) {
        self.captureSession = session
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupPreview(previewSize: CGRect) {
        self.frame = previewSize

        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.previewLayer.frame = self.bounds
        self.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    func updateFrame(frame: CGRect) {
        self.frame = frame
        self.previewLayer.frame = frame
    }
}
