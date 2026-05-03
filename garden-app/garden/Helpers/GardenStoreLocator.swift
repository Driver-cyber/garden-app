import Foundation

enum GardenStoreLocator {
    static let appGroupID = "group.com.drivercyber.garden"
    static let storeFilename = "Garden.sqlite"

    static var storeURL: URL {
        guard let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("App Group container missing — \(appGroupID) is not configured for this target.")
        }
        return groupURL.appendingPathComponent(storeFilename)
    }

    /// Defaults shared between the main app and the widget/intent extension process.
    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
