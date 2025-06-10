//
//  lockinaiApp.swift
//  lockinai
//
//  Created by Savina Jabbo on 5/31/25.
//

import SwiftUI

@main
struct lockinaiApp: App {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    Task {
                        do {
                            try await screenTimeManager.requestAuthorization()
                            screenTimeManager.startMonitoring()
                        } catch {
                            print("Failed to request screen time authorization: \(error)")
                        }
                    }
                }
        }
    }
}
