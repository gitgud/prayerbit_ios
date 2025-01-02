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
    
    // Our custom manager that holds the search text and the resulting array
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
                    .background(Color(uiColor: .systemGroupedBackground))
                    
                    // 3) The list below, bound to searchManager.filteredPrayers
                    List {
                        ForEach(searchManager.filteredPrayers, id: \.self) { prayer in
                            NavigationLink(destination: PrayerEditView(prayer: prayer)) {
                                // A simple subview that displays the prayer’s title, etc.
                                PrayerDetailView(prayer: prayer)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(uiColor: .systemGroupedBackground))
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // 1) Provide the context to the manager
                // 2) Manager immediately does a fetch in setContext -> refresh()
                searchManager.setContext(viewContext)
                
                // Optional: Focus on the search bar automatically
                DispatchQueue.main.async {
                    searchIsFocused = true
                }
            }
        }
    }
}
