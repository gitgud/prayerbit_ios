import SwiftUI

struct MenuView: View {
    var body: some View {
        HStack {
            Spacer()
            
            // Search
            VStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                Text("Search")
                    .font(.footnote)
            }
            
            Spacer()
            
            // Account
            VStack(spacing: 4) {
                Image(systemName: "person.circle")
                    .font(.title2)
                Text("Account")
                    .font(.footnote)
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}


struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MenuView()
                .previewDisplayName("Light Mode")
                .environment(\.colorScheme, .light)
            
            MenuView()
                .previewDisplayName("Dark Mode")
                .environment(\.colorScheme, .dark)
        }
    }
}
