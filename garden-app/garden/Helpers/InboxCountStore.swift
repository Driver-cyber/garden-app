import Foundation
import SwiftData
import WidgetKit

/// Used to be a bridge that wrote inbox count into App Group UserDefaults for
/// the widget to read. Now the widget reads SwiftData directly, so this is
/// just a thin wrapper for "the inbox state changed, please reload the
/// timeline." Kept as a named call site for clarity at every place we mutate
/// notes or categories.
enum InboxCountStore {
    @MainActor
    static func refresh(in context: ModelContext) {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
