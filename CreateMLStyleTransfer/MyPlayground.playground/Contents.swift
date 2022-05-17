import Combine
import CreateML
import Foundation
import SwiftUI
import PlaygroundSupport

let sessionDir = URL(fileURLWithPath: "\(NSTemporaryDirectory())MLStyleTransfer")
let styleImageURL = Bundle.main.url(forResource: "embroidery", withExtension: "jpg", subdirectory: "styles")!
let sampleImageURL = Bundle.main.url(forResource: "2", withExtension: "jpg", subdirectory: "validation")!

let trainingData = MLStyleTransfer.DataSource.images(
    styleImage: styleImageURL,
    contentDirectory: Bundle.main.url(forResource: "StyleGanImg_1042_96_0", withExtension: "jpg", subdirectory: "content")!.resolvingSymlinksInPath().deletingLastPathComponent(),
    processingOption: .scaleFit
)

let style = NSImage(byReferencing: styleImageURL)
let sample = NSImage(byReferencing: sampleImageURL)

let iterations = 100
let progressInterval = 5
let checkpointInterval = 5

let sessionParameters = MLTrainingSessionParameters(
    sessionDirectory: sessionDir,
    reportInterval: progressInterval,
    checkpointInterval: checkpointInterval,
    iterations: iterations
)

let maxIterations = iterations
let textelDensity = 512
let styleStrength = 8

let trainingParameters = MLStyleTransfer.ModelParameters(
    algorithm: .cnnLite,
    validation: .content(sampleImageURL),
    maxIterations: maxIterations,
    textelDensity: textelDensity,
    styleStrength: styleStrength
)

var subsriptions: [AnyCancellable] = []

let trainingJob = try MLStyleTransfer.train(
    trainingData: trainingData,
    parameters: trainingParameters,
    sessionParameters: sessionParameters
)

trainingJob.result.sink { result in
    print(result)
}
receiveValue: { model in
    try? model.write(to: sessionDir)
}
.store(in: &subsriptions)

trainingJob.progress.publisher(for: \.fractionCompleted).sink { completed in
    _ = completed

    guard let progress = MLProgress(progress: trainingJob.progress) else { return }
    if let styleLoss = progress.metrics[.styleLoss] { _ = styleLoss }
    if let contentLoss = progress.metrics[.contentLoss] { _ = contentLoss }
}
.store(in: &subsriptions)

trainingJob.checkpoints
    .compactMap { $0.metrics[.stylizedImageURL] as? URL }
    .map { NSImage(byReferencing: $0) }
    .receive(on: DispatchQueue.main)
    .sink { image in
        let _ = image

        let view = VStack {
            Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
            Image(nsImage: style).resizable().aspectRatio(contentMode: .fit)
            Image(nsImage: sample).resizable().aspectRatio(contentMode: .fit)
        }.frame(maxHeight: 500)

        PlaygroundSupport.PlaygroundPage.current.setLiveView(view)
    }
    .store(in: &subsriptions)

trainingJob.cancel()

let resumedJob = try MLStyleTransfer.train(
    trainingData: trainingData,
    parameters: trainingParameters,
    sessionParameters: sessionParameters
)
