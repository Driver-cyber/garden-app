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
        Self.migrateStoreToAppGroupIfNeeded()
        let schema = Schema([Note.self, Category.self])
        let configuration = ModelConfiguration(
            schema: schema,
            url: GardenStoreLocator.storeURL,
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    /// One-time copy of the default-location SwiftData store into the App Group
    /// container, so the main app and the widget/intent process read the same data.
    /// No-op on fresh installs and on subsequent launches.
    private static func migrateStoreToAppGroupIfNeeded() {
        let newStoreURL = GardenStoreLocator.storeURL
        if FileManager.default.fileExists(atPath: newStoreURL.path) { return }

        guard let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first else { return }

        let contents = (try? FileManager.default.contentsOfDirectory(
            at: appSupport, includingPropertiesForKeys: nil
        )) ?? []
        guard let oldStoreURL = contents.first(where: { $0.pathExtension == "store" }) else { return }

        for suffix in ["", "-shm", "-wal"] {
            let from = URL(fileURLWithPath: oldStoreURL.path + suffix)
            let to = URL(fileURLWithPath: newStoreURL.path + suffix)
            if FileManager.default.fileExists(atPath: from.path) {
                try? FileManager.default.copyItem(at: from, to: to)
            }
        }
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { await seedIfNeeded() }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { @MainActor in
                    reconcile(in: sharedModelContainer.mainContext)
                }
            }
        }
    }

    @MainActor
    private func seedIfNeeded() async {
        let local = UserDefaults.standard
        let context = sharedModelContainer.mainContext

        // Merge any same-named categories CloudKit may have synced down before us.
        Self.dedupCategories(in: context)

        let categories = (try? context.fetch(FetchDescriptor<Category>())) ?? []

        // Legacy TBD: no longer seeded, but preserve its ID for users who already have one.
        if local.string(forKey: "garden.tbd.categoryID") == nil,
           let tbd = categories.first(where: { $0.name == "Ideas / TBD" }) {
            local.set(tbd.id.uuidString, forKey: "garden.tbd.categoryID")
        }

        local.set(true, forKey: "garden.seeded")

        reconcile(in: context)
    }

    /// Dedup categories, refresh the shared Inbox ID (if Inbox exists), and
    /// refresh the widget count. Safe to call repeatedly.
    @MainActor
    private func reconcile(in context: ModelContext) {
        Self.dedupCategories(in: context)

        let categories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        if let inbox = categories.first(where: { $0.name == "Inbox" }) {
            GardenStoreLocator.sharedDefaults.set(
                inbox.id.uuidString, forKey: InboxGate.inboxIDKey
            )
        } else {
            GardenStoreLocator.sharedDefaults.removeObject(forKey: InboxGate.inboxIDKey)
        }

        InboxCountStore.refresh(in: context)
    }

    /// Merge categories that share a name. Keeps the oldest, reassigns notes from
    /// the others, deletes the duplicates. CloudKit doesn't enforce uniqueness, so
    /// this runs every launch + every foreground.
    @MainActor
    private static func dedupCategories(in context: ModelContext) {
        guard let categories = try? context.fetch(FetchDescriptor<Category>()) else { return }
        let groups = Dictionary(grouping: categories, by: { $0.name })
        var didChange = false

        for (_, dupes) in groups where dupes.count > 1 {
            let sorted = dupes.sorted { $0.createdAt < $1.createdAt }
            guard let keeper = sorted.first else { continue }
            let toRemove = Array(sorted.dropFirst())
            let removeIDs = Set(toRemove.map(\.id))

            if let allNotes = try? context.fetch(FetchDescriptor<Note>()) {
                for note in allNotes where removeIDs.contains(note.categoryID) {
                    note.categoryID = keeper.id
                    didChange = true
                }
            }

            for cat in toRemove {
                context.delete(cat)
                didChange = true
            }
        }

        if didChange {
            try? context.save()
        }
    }
}
