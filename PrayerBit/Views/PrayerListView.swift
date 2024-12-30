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
    
    // Original fetch for all prayers (in descending lastModifiedDate order)
    // You can keep this or remove it if you prefer to rely entirely on search manager.
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PrayerEntity.lastModifiedDate, ascending: false)],
        animation: .default
    )
    private var prayers: FetchedResults<PrayerEntity>
    
    // Our search manager
    @StateObject private var searchManager: PrayerSearchManager
    
    // Init
    init() {
        // We must create the StateObject with a context. We'll do so in onAppear or an init that receives context.
        // But we do not have @Environment context here.
        // Instead, we'll do a custom init that we do NOT call from the preview. Or a .onAppear approach.
        // For demonstration, we'll do a failable init with nil, or do a 2-phase approach.
        
        // This is a trick: We can't directly fetch @Environment in init, so we'll create a placeholder.
        _searchManager = StateObject(wrappedValue: PrayerSearchManager(context: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        NavigationView {
            // Display either the normal "prayers" or the "searched" prayers
            List {
                ForEach(currentPrayers(), id: \.self) { prayer in
                    NavigationLink(destination: PrayerEditView(prayer: prayer)) {
                        // If you want the inline detail, do PrayerDetailView(prayer: prayer)
                        // But that can be very tall. We'll keep it simple with just the prayer title:
                        Text(prayer.title ?? "Untitled Prayer")
                    }
                }
            }
            .navigationTitle("All Prayers")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // 1) The search bar
                    TextField("Search", text: $searchManager.searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 160)  // tweak as needed to fit next to the plus button
                        .padding(.trailing, 4)
                    
                    // 2) The plus button
                    NavigationLink(destination: PrayerCreateView()) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                // Update the searchManager context if you prefer environment
                // so we don't rely on that "shared container" from init above.
                searchManagerUpdateContextIfNeeded()
            }
        }
    }
    
    /// Decide which prayers to display:
    /// - If searchText is non-empty, show the search results
    /// - Else show the default FetchedRequest "prayers"
    private func currentPrayers() -> [PrayerEntity] {
        let text = searchManager.searchText.trimmingCharacters(in: .whitespaces)
        if text.isEmpty {
            // Show the original fetch
            return prayers.map { $0 }
        } else {
            // Show the custom search results
            return searchManager.searchPrayers()
        }
    }
    
    private func searchManagerUpdateContextIfNeeded() {
        // If the search manager was created with a placeholder context,
        // let's update it to use the environment's context:
        if searchManager.searchPrayers().isEmpty {  // or some other logic
            // Re-init or do some bridging
            // For now, we'll just do nothing if it's already set up
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
            let newPrayerPreview = PrayerEntity(context: context)
            newPrayerPreview.id = UUID()
            newPrayerPreview.title = "Sample Prayer #\(i)"
            newPrayerPreview.creationDate = Date().addingTimeInterval(Double(-i) * 86400)
            newPrayerPreview.lastModifiedDate = Date()
            
            // Add some sample requests
            for j in 1...2 {
                let request = RequestEntity(context: context)
                request.id = UUID()
                request.request = "Request #\(j) for Prayer #\(i)"
                request.creationDate = Date().addingTimeInterval(Double(-j) * 3600)
                request.lastModifiedDate = Date()
                request.prayer = newPrayerPreview
            }
            
            // Add some sample tags
            let tag1 = TagEntity(context: context)
            tag1.id = UUID()
            tag1.tag = (i % 2 == 0) ? "Family" : "Urgent"
            newPrayerPreview.addToTags(tag1)
            
            let tag2 = TagEntity(context: context)
            tag2.id = UUID()
            tag2.tag = "Focus"
            newPrayerPreview.addToTags(tag2)
        }
        
        return PrayerListView()
            .environment(\.managedObjectContext, context)
    }
}
