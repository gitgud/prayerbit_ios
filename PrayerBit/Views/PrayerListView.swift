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
    
    // Single data source: we only rely on searchManager for the final prayers list
    @StateObject private var searchManager = PrayerSearchManager()
    
    // Use a FocusState for the search TextField
    @FocusState private var searchIsFocused: Bool
    
    var body: some View {
        NavigationView {
            List {
                let prayers = searchManager.searchPrayers()
                ForEach(prayers, id: \.self) { prayer in
                    NavigationLink(destination: PrayerEditView(prayer: prayer)) {
                        PrayerDetailView(prayer: prayer)
                    }
                }
            }
            .navigationTitle("All Prayers")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Search field
                    TextField("Search...", text: $searchManager.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 150)
                        .focused($searchIsFocused)    // <-- Tie to our FocusState
                                        
                    // Plus button
                    NavigationLink(destination: PrayerCreateView()) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                // Provide the environment context to searchManager
                searchManager.setContext(viewContext)
                
                // Immediately focus the search bar
                DispatchQueue.main.async {
                    searchIsFocused = true
                }
            }
        }
    }
}

// MARK: Preview
struct PrayerListView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // Insert some sample prayers
        for i in 1...3 {
            let prayer = PrayerEntity(context: context)
            prayer.id = UUID()
            prayer.title = "Sample Prayer #\(i)"
            prayer.creationDate = Date().addingTimeInterval(Double(-i) * 86400)
            prayer.lastModifiedDate = Date()
            
            // Add sample requests
            for j in 1...2 {
                let req = RequestEntity(context: context)
                req.id = UUID()
                req.request = "Request #\(j) for Prayer #\(i)"
                req.creationDate = Date().addingTimeInterval(Double(-j) * 3600)
                req.lastModifiedDate = Date()
                req.prayer = prayer
            }
            
            // Add a few sample tags
            let tag = TagEntity(context: context)
            tag.id = UUID()
            tag.tag = (i % 2 == 0) ? "Family" : "Urgent"
            prayer.addToTags(tag)
        }
        
        return PrayerListView()
            .environment(\.managedObjectContext, context)
    }
}
