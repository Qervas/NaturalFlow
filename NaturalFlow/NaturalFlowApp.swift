//
//  NaturalFlowApp.swift
//  NaturalFlow
//
//  Created by FrankYin on 2024-11-08.
//

import SwiftData
import SwiftUI

@main
struct NaturalFlowApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            // Define the schema with all model types
            let schema = Schema([
                Book.self,
                Word.self,
            ])

            // Configure the model container
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

            // Create the container
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
