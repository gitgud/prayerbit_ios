//
//  test2App.swift
//  test2
//
//  Created by kale on 12/24/24.
//

import SwiftUI

@main
struct test2App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            PrayerListView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
