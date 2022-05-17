//
//  ContentView.swift
//  Imagenet
//
//  Created by Dmitry Voitekh on 12.05.2022.
//

import SwiftUI
import CoreML

func buffer(image: UIImage) -> CVPixelBuffer? {
    let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
    var pixelBuffer : CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
    guard (status == kCVReturnSuccess) else {
    return nil
    }

    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

    context?.translateBy(x: 0, y: image.size.height)
    context?.scaleBy(x: 1.0, y: -1.0)

    UIGraphicsPushContext(context!)
    image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    UIGraphicsPopContext()
    CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

    return pixelBuffer
}

func resize(image: UIImage, width: CGFloat, height: CGFloat) -> UIImage {
    UIGraphicsBeginImageContext(CGSize(width: width, height: height))
    image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage!
}

struct Classifier {
    let model = try! MobileNetV2FP16(configuration: MLModelConfiguration())
    
    func predict(uiImage: UIImage) -> String {
        let cvPixelBuffer = buffer(image: resize(image: uiImage, width: 224, height: 224))
        let input = MobileNetV2FP16Input(image: cvPixelBuffer!)
        let result = try! model.prediction(input: input)
        let topLabel = result.classLabelProbs.max(by: { $0.value < $1.value })
        return "Label: \(topLabel!.key), confidence: \(topLabel!.value)"
    }
}

struct ContentView: View {
    let images = ["cat", "dog", "snake", "fish", "parrot", "monkey", "horse"]
    @State var currentImage = UIImage(named: "cat")!
    @State var text = ""
    let model = Classifier()
    
    var body: some View {
        VStack {
            Image(uiImage: currentImage)
                .resizable()
                .frame(width: 224, height: 224).padding()
            
            Text(text).padding()
            
            Button("Shuffle Image") {
                currentImage = UIImage(named: images.randomElement()!)!
                text = model.predict(uiImage: currentImage)
            }.padding()
        }.onAppear {
            Task {
                text = model.predict(uiImage: currentImage)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
