//
//  ContentView.swift
//  garden
//
//  Created by ORDOCFO on 4/25/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "pencil.and.scribble")
                }
            CalmView()
                .tabItem {
                    Label("Calm", systemImage: "leaf")
                }
        }
        .tint(Color.sageDeep)
    }
}

#Preview {
    ContentView()
}
