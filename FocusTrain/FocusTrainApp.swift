//
//  FocusTrainApp.swift
//  FocusTrain
//
//  Created by Guilherme Hoffmann on 5/29/26.
//

import SwiftUI
import SwiftData

@main
struct FocusTrainApp: App {
    @State private var sessionStore = SessionStore()
    @State private var focusModeStore = FocusModeStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sessionStore)
                .environment(focusModeStore)
        }
        .modelContainer(for: Journey.self)
    }
}
