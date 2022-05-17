//
//  ContentView.swift
//  CreateMLOnDeviceRecommender
//
//  Created by Dmitry Voitekh on 17.05.2022.
//

import SwiftUI

struct AlbumCard: View {
    @StateObject var viewModel : ViewModel
    let album : Album
    
    var body: some View {
        VStack {
            Image(uiImage: album.image).resizable().frame(width: 200, height: 200)
            Text(album.name).font(.title3)
            Text(album.artist).font(.headline)
            Button(viewModel.isLiked(album: album) ? "Unlike" : "Like") {
                viewModel.likeAlbum(like: !viewModel.isLiked(album: album), album: album)
                Task {
                    try await viewModel.makeRecommendations()
                }
            }
        }.padding()
    }
}

struct ContentView: View {
    @StateObject var viewModel: ViewModel
    
    var body: some View {
        ScrollView {
            if (!viewModel.recommendedAlbums.isEmpty) {
                Text("Recommendations").font(.title).padding()
                ScrollView(.horizontal) {
                    LazyHStack {
                        ForEach(viewModel.recommendedAlbums) { album in
                            AlbumCard(viewModel: viewModel, album: album)
                        }
                    }
                }.padding()
            }
            
            Text("All albums").font(.title).padding()
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4)) {
                ForEach(viewModel.albums) { album in
                    AlbumCard(viewModel: viewModel, album: album)
                }
            }.onAppear {
                Task {
                    viewModel.loadAlbums()
                }
            }.padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ViewModel()
        ContentView(viewModel: viewModel)
    }
}
