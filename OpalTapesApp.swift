//
//  OpalTapesApp.swift
//  OpalTapes
//
//  Created by Ali Hammoud on 3/9/24.
//

import SwiftUI
import SwiftData

@main
struct OpalTapesApp: App {
    var MainModelContainer: ModelContainer = {
        let schema = Schema([
            //Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView().onAppear {
                let requestTrack = FetchTrack()
                requestTrack.networkFetchDone = {
                    print("Finished Request")
                }
                requestTrack.performRequest()
            }
        }
        .modelContainer(MainModelContainer)
    }
}
