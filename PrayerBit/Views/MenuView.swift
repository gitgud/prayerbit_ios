import SwiftUI

struct MenuView: View {
    // Two closures passed in from the parent
    let onSearchTapped: () -> Void
    let onAccountTapped: () -> Void
    
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
            .onTapGesture {
                onSearchTapped()
            }
            
            Spacer()
            
            // Account
            VStack(spacing: 4) {
                Image(systemName: "person.circle")
                    .font(.title2)
                Text("Account")
                    .font(.footnote)
            }
            .onTapGesture {
                onAccountTapped()
            }
            
            Spacer()
        }
        .background(Color.gray)
        // Remove the vertical padding to bring it flush to the bottom
        .padding(.vertical, 0)
    }
}

// Preview
struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView(
            onSearchTapped: {},
            onAccountTapped: {}
        )
        .previewLayout(.sizeThatFits)
    }
}
