//
//  CaptureModel.swift
//  CameraControl
//
//  Created by Toshihiro Goto on 2024/10/27.
//

import UIKit
import AVFoundation
import Photos

public class CaptureModel : NSObject {
    public var captureSession: AVCaptureSession = AVCaptureSession()
    private var deviceInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput = AVCapturePhotoOutput()
    
    override init() {
        super.init()
        self.setupSession()
    }
    
    public func setupSession() {
        captureSession.beginConfiguration()
        
        guard let caputureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let deviceInput = try? AVCaptureDeviceInput(device: caputureDevice) else { return }
        self.deviceInput = deviceInput
        
        guard captureSession.canAddInput(deviceInput) else { return }
        captureSession.addInput(deviceInput)

        guard captureSession.canAddOutput(photoOutput) else { return }
        captureSession.sessionPreset = .photo
        captureSession.addOutput(photoOutput)
        
        setControls(device: caputureDevice)
        
        captureSession.commitConfiguration()
    }
    
    func getImageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        guard let cgImage = context.makeImage() else {
            return nil
        }
        let image = UIImage(cgImage: cgImage, scale: 1, orientation:.right)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        return image
    }
    
    public func updateInputOrientation(orientation: UIDeviceOrientation) {
        for connection in captureSession.connections {
            connection.videoRotationAngle = ConvertVideoOrientation(deviceOrientation: orientation)
        }
    }
}

public func ConvertVideoOrientation(deviceOrientation: UIDeviceOrientation) -> CGFloat {
    switch deviceOrientation {
    case .portrait:
        return 90
    case .portraitUpsideDown:
        return 270
    case .landscapeLeft:
        return 0
    case .landscapeRight:
        return 180
    default:
        return 90
    }
}

extension CaptureModel: AVCapturePhotoCaptureDelegate {
    // 写真撮影
    public func takePhoto() {
        let photoSetting = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: photoSetting, delegate: self)
        return
    }
    
    // 写真の保存
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else { print("Error capturing photo: \(error!)"); return }
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: photo.fileDataRepresentation()!, options: nil)
            }, completionHandler: {_,_ in })
        }
    }
}

extension CaptureModel: AVCaptureSessionControlsDelegate {
    // カメラコントロール オーバーレイとコントロールの設定
    func setControls(device: AVCaptureDevice) {
        let sessionQueue = DispatchSerialQueue(label: "cameraControlOverlay")
        captureSession.setControlsDelegate(self, queue: sessionQueue)
        
        // 焦点距離
        let captureSlider = AVCaptureSlider("Focus", symbolName: "scope", in: 0...1)

        captureSlider.setActionQueue(sessionQueue) { lensPosition in
            do {
                try device.lockForConfiguration()
                device.setFocusModeLocked(lensPosition: lensPosition)
                device.unlockForConfiguration()
            } catch {
                print("焦点距離の変更ができません: \(error)")
            }
        }
        
        // ズーム
        let zoomSlider = AVCaptureSystemZoomSlider(device: device)
        
        // 露出
        let exposureBiasSlider = AVCaptureSystemExposureBiasSlider(device: device)
        
        // ピッカー
        let labels: [String] = ["Label1", "Label2", "Label3"]
        let captureIndexPicker = AVCaptureIndexPicker("Filters", symbolName: "camera.filters", localizedIndexTitles: labels)
        
        captureIndexPicker.setActionQueue(sessionQueue) { IndexTitle in
            print("選択されたラベル \(labels[IndexTitle]).")
        }
        
        // 設定したコントロールをを追加
        let controls: [AVCaptureControl] = [captureSlider, zoomSlider, exposureBiasSlider, captureIndexPicker]
        
        if captureSession.supportsControls {
            for control in captureSession.controls {
                captureSession.removeControl(control)
            }
            
            for control in controls {
                if captureSession.canAddControl(control) {
                    captureSession.addControl(control)
                } else {
                    print("このコントロールは使用できません: \(control)")
                }
            }
        }
    }
    
    // Delegate

    public func sessionControlsDidBecomeActive(_ session: AVCaptureSession) {
        // キャプチャセッションのコントロールがアクティブになり、操作できるようになった時に呼ばれる
    }
    
    public func sessionControlsWillEnterFullscreenAppearance(_ session: AVCaptureSession) {
        // キャプチャセッションのコントロールが全画面表示になる時に呼ばれる
        
        // 主にカメラコントロールのオーバーレイ表示時に
        // 必要のないユーザーインターフェイスを非表示にするために使用する
    }
    
    public func sessionControlsWillExitFullscreenAppearance(_ session: AVCaptureSession) {
        // キャプチャセッションのコントロールの全画面表示が終了する時に呼ばれる
        
        // 主に sessionControlsWillEnterFullscreenAppearance など、
        // 以前に非表示にしたユーザーインターフェイスを元に戻すために使用する
    }
    
    public func sessionControlsDidBecomeInactive(_ session: AVCaptureSession) {
        // キャプチャセッションのコントロールが非アクティブになり、操作できなくなった時に呼ばれる
    }
}
