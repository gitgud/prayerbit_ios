import SwiftUI
import CoreData

struct PrayerListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var searchManager = PrayerSearchManager()
    @FocusState private var searchIsFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // 1) Gray background behind everything
                Color(uiColor: .systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // 2) Custom top bar with a matching background
                    HStack {
                        TextField("Search...", text: $searchManager.searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: .infinity)
                            .focused($searchIsFocused)
                        
                        NavigationLink(destination: PrayerCreateView()) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .padding(.horizontal, 8)
                        }
                    }
                    .padding()
                    // Give the HStack the same background color (optional,
                    // because the ZStack behind it is also gray)
                    .background(Color(uiColor: .systemGroupedBackground))
                    
                    // 3) The list below
                    List {
                        let prayers = searchManager.searchPrayers()
                        ForEach(prayers, id: \.self) { prayer in
                            NavigationLink(destination: PrayerEditView(prayer: prayer)) {
                                PrayerDetailView(prayer: prayer)
                            }
                        }
                    }
                    .listStyle(.plain)
                    // On iOS 16+:
                    .scrollContentBackground(.hidden)       // hide white BG
                    .background(Color(uiColor: .systemGroupedBackground)) // keep list area gray
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                searchManager.setContext(viewContext)
                DispatchQueue.main.async {
                    searchIsFocused = true
                }
            }
        }
    }
}
