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
    
    var body: some View {
        NavigationView {
            List {
                // show the prayers from searchManager.searchPrayers()
                let prayers = searchManager.searchPrayers()
                
                ForEach(prayers, id: \.self) { prayer in
                    // Display PrayerDetailView inline in the row:
                    NavigationLink(destination: PrayerEditView(prayer: prayer)) {
                        PrayerDetailView(prayer: prayer)
                            // If it's too large, consider removing some detail or adjusting layout
                    }
                }
            }
            .navigationTitle("All Prayers")
            .toolbar {
                // We can place the search bar & plus button in one line
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Search field
                    TextField("Search...", text: $searchManager.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 150)
                    
                    // Plus button
                    NavigationLink(destination: PrayerCreateView()) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                // Provide the environment context to searchManager
                searchManager.setContext(viewContext)
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
        for i in 1...10 {
            let p = PrayerEntity(context: context)
            p.id = UUID()
            p.title = "Sample Prayer #\(i)"
            p.creationDate = Date().addingTimeInterval(Double(-i) * 86400)
            p.lastModifiedDate = Date()
            
            // A few requests
            for j in 1...2 {
                let req = RequestEntity(context: context)
                req.id = UUID()
                req.request = "Request #\(j) for Prayer #\(i)"
                req.creationDate = Date().addingTimeInterval(Double(-j) * 3600)
                req.lastModifiedDate = Date()
                req.prayer = p
            }
            
            // A few tags (many-to-many)
            let tag = TagEntity(context: context)
            tag.id = UUID()
            tag.tag = (i % 2 == 0) ? "Family" : "Urgent"
            p.addToTags(tag)
        }
        
        return PrayerListView()
            .environment(\.managedObjectContext, context)
    }
}
