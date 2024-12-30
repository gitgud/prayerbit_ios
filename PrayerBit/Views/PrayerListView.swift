//
//  PrayerListView.swift
//  PrayerBit
//
//  Created by kale on 12/25/24.
//

import SwiftUI
import CoreData

struct PrayerListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var searchManager = PrayerSearchManager()
    @FocusState private var searchIsFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Our custom "title bar" area
                HStack {
                    // Make the search bar big
                    TextField("Search...", text: $searchManager.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: .infinity)     // Occupy as much space as possible
                        .focused($searchIsFocused)
                    
                    // Plus button
                    NavigationLink(destination: PrayerCreateView()) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .padding(.horizontal, 8)
                    }
                }
                .padding()    // Some vertical/horizontal padding for style
                
                // The list below the custom title bar
                List {
                    let prayers = searchManager.searchPrayers()
                    ForEach(prayers, id: \.self) { prayer in
                        NavigationLink(destination: PrayerEditView(prayer: prayer)) {
                            PrayerDetailView(prayer: prayer)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationBarHidden(true)  // Hide default nav bar so we can use our custom header
            .onAppear {
                searchManager.setContext(viewContext)
                // Focus the search bar on appear
                DispatchQueue.main.async {
                    searchIsFocused = true
                }
            }
        }
    }
}
