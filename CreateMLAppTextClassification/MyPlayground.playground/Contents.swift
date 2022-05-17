import Cocoa
import CoreML

let input = MyTextClassifierInput(text: "I play football in the evening")

let model = try MyTextClassifier(configuration: MLModelConfiguration())

let output = try model.prediction(input: input)

let label = output.label

