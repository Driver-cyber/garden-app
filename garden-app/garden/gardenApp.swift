//
//  gardenApp.swift
//  garden
//
//  Created by ORDOCFO on 4/25/26.
//

import SwiftUI
import SwiftData

@main
struct gardenApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Note.self, Category.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await seedIfNeeded() }
        }
        .modelContainer(sharedModelContainer)
    }

    @MainActor
    private func seedIfNeeded() async {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "garden.seeded") else { return }

        let context = sharedModelContainer.mainContext
        let tbd = Category(name: "Ideas / TBD")
        context.insert(tbd)

        do {
            try context.save()
            defaults.set(tbd.id.uuidString, forKey: "garden.tbd.categoryID")
            defaults.set(true, forKey: "garden.seeded")
        } catch {
            print("Seed failed: \(error)")
        }
    }
}
