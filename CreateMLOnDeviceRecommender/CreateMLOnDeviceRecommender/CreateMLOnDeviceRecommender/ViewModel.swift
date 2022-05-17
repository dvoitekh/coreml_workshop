//
//  ViewModel.swift
//  CreateMLOnDeviceRecommender
//
//  Created by Dmitry Voitekh on 17.05.2022.
//

import Foundation
import SwiftUI

struct Album: Decodable, Identifiable, Hashable {
    let name: String
    let artist: String
    let artwork: String
    let keywords: [String]
    
    var id: String {
        "\(name)-\(artist)"
    }
    
    var image: UIImage {
        UIImage(named: artwork)!
    }
}

@MainActor
class ViewModel: ObservableObject {
    let recommeder : Recommender = Recommender()
    @Published var albums = [Album]()
    @Published var recommendedAlbums = [Album]()
    @Published var likes = [Album:Bool]()
    
    func loadAlbums() {
        do {
            let url = Bundle.main.url(forResource: "albums", withExtension: "json")!
            let json = try Data(contentsOf: url)
            albums = try JSONDecoder().decode([Album].self, from: json)
            albums.forEach { album in
                likes[album] = false
            }
        } catch {
            print("error loading albums")
        }
    }
    
    func isLiked(album: Album) -> Bool {
        return likes[album]!
    }
    
    func likeAlbum(like: Bool, album: Album) {
        likes[album] = like
    }
    
    func makeRecommendations() async throws {
        recommendedAlbums = try await recommeder.recommend(likes: likes)
    }
}
