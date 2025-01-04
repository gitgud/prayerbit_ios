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
                // Gray background behind everything
                Color(uiColor: .systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Custom top bar with a matching background
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
                    
                    // The list below, bound to searchManager.filteredPrayers
                    List {
                        ForEach(searchManager.filteredPrayers, id: \.self) { prayer in
                            // We use a ZStack so we can place a hidden NavigationLink
                            // (removing the default chevron arrow), while still
                            // having a tappable area for navigation.
                            ZStack {
                                // The "bubble" styled view
                                PrayerDetailView(prayer: prayer)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.1),
                                                    radius: 4, x: 0, y: 2)
                                    )
                                    .padding(.vertical, 4)
                                
                                // Invisible NavigationLink to remove the arrow on the right
                                NavigationLink(destination: PrayerEditView(prayer: prayer)) {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                            // Remove default list row background and separators
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(uiColor: .systemGroupedBackground))
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Provide the context to the manager & force a fetch
                searchManager.setContext(viewContext)
                
                // Optional: Focus on the search bar automatically
                DispatchQueue.main.async {
                    searchIsFocused = true
                }
            }
        }
    }
}
