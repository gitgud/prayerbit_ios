import SwiftUI

struct MainAppView: View {
    @State private var currentScreen: Screen = .search
    @State private var isKeyboardActive: Bool = false
    @State private var hideMenu: Bool = false
    
    enum Screen {
        case search
        case account
    }
    
    var body: some View {
        VStack(spacing: 0) {
            switch currentScreen {
            case .search:
                PrayerListView(
                    isKeyboardActive: $isKeyboardActive,
                    hideMenu: $hideMenu
                )
            case .account:
                AccountView()
            }
            
            // If not typing and not hidden, show the menu
            if !isKeyboardActive && !hideMenu {
                MenuView(
                    onSearchTapped: { currentScreen = .search },
                    onAccountTapped: { currentScreen = .account }
                )
                // Pin to the bottom and push even further (if you like)
                .ignoresSafeArea(edges: .bottom)
                .padding(.bottom, -10) // Adjust this negative value as needed
            }
        }
    }
}

struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
    }
}
