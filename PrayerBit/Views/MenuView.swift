import SwiftUI

struct MenuView: View {
    // Two closures that the parent view will pass in
    let onSearchTapped: () -> Void
    let onAccountTapped: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            // Search item
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
            
            // Account item
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
        // 1) Make background gray
        .background(Color.gray)
        // 2) Reduce vertical padding from 8 to 6 (~25% smaller)
        .padding(.vertical, 6)
    }
}

// Optional Preview
struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView(
            onSearchTapped: {},
            onAccountTapped: {}
        )
        .previewLayout(.sizeThatFits)
    }
}
