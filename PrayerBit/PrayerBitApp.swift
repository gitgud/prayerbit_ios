//
//  PrayerBitApp.swift
//  PrayerBit
//
//  Created by kale on 12/17/24.
//

import SwiftUI

@main
struct PrayerBitApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
