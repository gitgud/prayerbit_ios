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
                                // Instead of showing PrayerDetailView directly,
                                // place it in a bubble/capsule style background.

                                PrayerDetailView(prayer: prayer)
                                    // Extra padding inside the bubble
                                    .padding()
                                    // Bubble background
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(.systemBackground))              // or any color you want
                                            .shadow(color: .black.opacity(0.1),
                                                    radius: 4, x: 0, y: 2)
                                    )
                                    // Tweak overall spacing around the cell
                                    .padding(.vertical, 4)
                            }
                            // Make sure the system doesn’t force a default background
                            .listRowBackground(Color.clear)
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
