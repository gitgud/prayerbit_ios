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
    
    // Tracks if the keyboard/text field is active (focused)
    @State private var isKeyboardActive: Bool = false
    
    // Whether or not to hide the bottom menu (used by PrayerEditView)
    @State private var hideMenu: Bool = false
    
    enum Screen {
        case search
        case account
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Show one child or the other
            switch currentScreen {
            case .search:
                // Pass the bindings down, so we know when a text field is focused
                // and when we need to hide the menu entirely.
                PrayerListView(
                    isKeyboardActive: $isKeyboardActive,
                    hideMenu: $hideMenu
                )
                
            case .account:
                AccountView()
            }
            
            // The custom bottom menu at the very bottom
            // Hide it if the user is typing OR if PrayerEditView says to hide it.
            if !isKeyboardActive && !hideMenu {
                MenuView(
                    onSearchTapped: { currentScreen = .search },
                    onAccountTapped: { currentScreen = .account }
                )
            }
        }
    }
}

struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
    }
}
