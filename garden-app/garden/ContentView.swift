//
//  ContentView.swift
//  garden
//
//  Created by ORDOCFO on 4/25/26.
//

import SwiftUI

extension Notification.Name {
    static let gardenFocusComposer = Notification.Name("garden.focusComposer")
    static let gardenSelectInbox = Notification.Name("garden.selectInbox")
}

struct ContentView: View {
    @State private var selection: Int = 0
    @State private var showSettings: Bool = false

    var body: some View {
        TabView(selection: $selection) {
            NotesView(showSettings: $showSettings)
                .tabItem {
                    Label("Notes", systemImage: "pencil.and.scribble")
                }
                .tag(0)
            CalmView()
                .tabItem {
                    Label("Calm", systemImage: "leaf")
                }
                .tag(1)
        }
        .tint(Color.sageDeep)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onOpenURL { url in
            switch url.host {
            case "calm":
                selection = 1
            case "notes":
                selection = 0
            case "compose":
                selection = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    NotificationCenter.default.post(name: .gardenFocusComposer, object: nil)
                }
            case "inbox":
                selection = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    NotificationCenter.default.post(name: .gardenSelectInbox, object: nil)
                }
            case "settings", "setup-inbox":
                selection = 0
                // Defer one runloop tick so the tab selection settles before
                // the sheet attempts to present — presenting both in the same
                // cycle was hanging the app on cold-launch deep links.
                DispatchQueue.main.async {
                    showSettings = true
                }
            default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
}
