//
//  ContentView.swift
//  CameraControl
//
//  Created by Toshihiro Goto on 2024/10/27.
//

import SwiftUI

struct ContentView: View {
    let captureModel: CaptureModel = .init()
    
    var body: some View {
        ZStack {
            GeometryReader { geom in
                CameraPreview(
                    previewFrame:
                        CGRect(
                            x: 0,
                            y: 0,
                            width: geom.size.width,
                            height: geom.size.height
                        ),
                    captureModel: captureModel
                )
                .onCameraCaptureEvent() { event in
                    if event.phase == .began {
                        captureModel.takePhoto()
                    }
                }
            }
            VStack {
                Spacer()
                Button {
                    captureModel.takePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(.white, lineWidth: 3)
                            .frame(maxWidth: 62, maxHeight: 62)
                        Circle()
                            .fill(.white)
                            .frame(maxWidth: 50, maxHeight: 50)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
}

#Preview {
    ContentView()
}
