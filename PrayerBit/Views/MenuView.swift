import SwiftUI

struct MenuView: View {
    let onSearchTapped: () -> Void
    let onAccountTapped: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
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
        .padding(.vertical, 4)
        .background(Color.gray)// No extra vertical padding
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView(
            onSearchTapped: {},
            onAccountTapped: {}
        )
        .previewLayout(.sizeThatFits)
    }
}
