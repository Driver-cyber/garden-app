//
//  ContentView.swift
//  garden
//
//  Created by ORDOCFO on 4/25/26.
//

import SwiftUI

extension Notification.Name {
    static let gardenFocusComposer = Notification.Name("garden.focusComposer")
    static let gardenInboxEnabled = Notification.Name("garden.inboxEnabled")
    static let gardenShowSettings = Notification.Name("garden.showSettings")
}

struct ContentView: View {
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            NotesView()
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
            case "settings", "setup-inbox":
                selection = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    NotificationCenter.default.post(name: .gardenShowSettings, object: nil)
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
