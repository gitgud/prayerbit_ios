//
//  PrayerBitApp.swift
//  PrayerBit
//
//  Created by kale on 12/26/24.
//

import SwiftUI

@main
struct PrayerBitApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            // Instead of `PrayerListView()`,
            // we show our new parent container, `MainAppView()`.
                MainAppView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
