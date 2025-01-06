//
//  MainAppView.swift
//  PrayerBit
//
//  Created by kale on 1/6/25.
//


import SwiftUI

/// The parent container that switches between PrayerListView and AccountView.
/// It also shows the custom bottom menu (MenuView).
struct MainAppView: View {
    // Tracks which screen is active
    @State private var currentScreen: Screen = .search
    
    enum Screen {
        case search
        case account
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Show one child or the other
            switch currentScreen {
            case .search:
                PrayerListView()
            case .account:
                AccountView()
            }
            
            // The custom bottom menu at the very bottom
            MenuView(
                onSearchTapped: { currentScreen = .search },
                onAccountTapped: { currentScreen = .account }
            )
        }
    }
}

struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
    }
}