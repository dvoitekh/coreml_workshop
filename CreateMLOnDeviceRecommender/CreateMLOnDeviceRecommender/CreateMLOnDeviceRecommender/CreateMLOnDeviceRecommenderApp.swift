//
//  CreateMLOnDeviceRecommenderApp.swift
//  CreateMLOnDeviceRecommender
//
//  Created by Dmitry Voitekh on 17.05.2022.
//

import SwiftUI

@main
struct CreateMLOnDeviceRecommenderApp: App {
    var body: some Scene {
        WindowGroup {
            let viewModel = ViewModel()
            ContentView(viewModel: viewModel)
        }
    }
}
