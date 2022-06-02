//
//  Recommender.swift
//  CreateMLOnDeviceRecommender
//
//  Created by Dmitry Voitekh on 17.05.2022.
//

import Foundation
import CoreML
import TabularData
import CreateML

class Recommender {
    func recommend(likes: [Album:Bool]) async throws -> [Album] {
        let uniqueKeywords = allKeywords(albums: Array(likes.keys))
        let (likedAlbums, otherAlbums) = getLikedAndOtherAlbums(likes: likes)
        let dataset = generateDataset(likedAlbums: likedAlbums, otherAlbums: otherAlbums, uniqueKeywords: uniqueKeywords)
        let classifier = try await trainLinearRegressor(data: dataset)
        return try makePredictions(otherAlbums: otherAlbums, classifier: classifier!, uniqueKeywords: uniqueKeywords)
    }
    
    private func allKeywords(albums: [Album]) -> [String] {
        return Array(Set(albums.flatMap { $0.keywords} +
                         albums.map { $0.name} +
                         albums.map { $0.artist }))
    }
    
    func getLikedAndOtherAlbums(likes: [Album:Bool]) -> ([Album], [Album]) {
        var likedAlbums = [Album]()
        var unlikedAlbums = [Album]()
        
        likes.forEach { item in
            if (item.value) {
                likedAlbums.append(item.key)
            } else {
                unlikedAlbums.append(item.key)
            }
        }
        return (likedAlbums, unlikedAlbums)
    }

    private func albumFeatures(album: Album, uniqueKeywords: [String]) -> [Int] {
        var features = Array(repeating: 0, count: uniqueKeywords.count)
        features[uniqueKeywords.firstIndex(of: album.name)!] = 1
        features[uniqueKeywords.firstIndex(of: album.artist)!] = 1
        for keyword in album.keywords {
            features[uniqueKeywords.firstIndex(of: keyword)!] = 1
        }
        return features
    }

    private func buildDataframe(features: [[Int]], uniqueKeywords: [String], targets: [Double]?=nil) -> DataFrame {
        var df = DataFrame()
        for (i, column) in uniqueKeywords.enumerated() {
            df.append(column: Column(name: column, contents: features.map { $0[i] }))
        }
        if (targets != nil) {
            df.append(column: Column(name: "target", contents: targets!))
        }
        return df
    }

    private func generateDataset(likedAlbums: [Album], otherAlbums: [Album], uniqueKeywords: [String]) -> DataFrame {
        var trainingFeatures = [[Int]]()
        var trainingTargets = [Double]()

        for album in likedAlbums {
            trainingFeatures.append(albumFeatures(album: album, uniqueKeywords: uniqueKeywords))
            trainingTargets.append(1.0)

            trainingFeatures.append(albumFeatures(album: otherAlbums.randomElement()!, uniqueKeywords: uniqueKeywords))
            trainingTargets.append(-1.0)
        }

        return buildDataframe(features: trainingFeatures, uniqueKeywords: uniqueKeywords, targets: trainingTargets)
    }

    func makePredictions(otherAlbums: [Album], classifier: MLLinearRegressor, uniqueKeywords: [String]) throws -> [Album] {
        var featuresAll = [[Int]]()
        for album in otherAlbums {
            featuresAll.append(albumFeatures(album: album, uniqueKeywords: uniqueKeywords))
        }
        
        let df = buildDataframe(features: featuresAll, uniqueKeywords: uniqueKeywords)
        let predictions = try classifier.predictions(from: df)
        
        return otherAlbums.enumerated().sorted(by: { predictions[$0.offset] as! Double > predictions[$1.offset] as! Double }).map { $0.element }
    }
    
    private func trainLinearRegressor(data: DataFrame) async throws -> MLLinearRegressor? {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let model = try MLLinearRegressor(trainingData: data, targetColumn: "target")
                    continuation.resume(returning: model)
                } catch {
                    continuation.resume(throwing: NSError(domain: "classifier",
                                                          code: 1,
                                                          userInfo: [:]))
                }
            }
        }
    }
}
