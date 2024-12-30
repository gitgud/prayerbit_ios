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
                // custom header
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
                
                // your list
                List {
                    let prayers = searchManager.searchPrayers()
                    ForEach(prayers, id: \.self) { prayer in
                        NavigationLink(destination: PrayerEditView(prayer: prayer)) {
                            PrayerDetailView(prayer: prayer)
                        }
                    }
                }
                .listStyle(.plain)
                // For iOS 16+:
                .scrollContentBackground(.hidden)  // Hide white BG
                .background(Color(uiColor: .systemGroupedBackground)) // Gray BG
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
