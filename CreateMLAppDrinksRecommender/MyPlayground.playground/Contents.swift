import Cocoa
import CoreML

let input = DrinksRecommenderInput(items: ["bellini":4.0], k: 5)

let model = try DrinksRecommender(configuration: MLModelConfiguration())

let recommendations = try model.prediction(input: input)

let rec = recommendations.recommendations
let scores = recommendations.scores
