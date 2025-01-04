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
    
    // We store a local copy of the prayers for drag-to-reorder
    @State private var reorderablePrayers: [PrayerEntity] = []
    
    @FocusState private var searchIsFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gray background behind everything
                Color(uiColor: .systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // MARK: - Top Search Bar
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
                    
                    // MARK: - Drag-to-Reorder List (Shown if exact tag match)
                    if isTagExactMatch {
                        // The EditButton toggles the built-in edit mode to enable .onMove
                        HStack {
                            Spacer()
                            EditButton()
                                .padding(.trailing, 16)
                        }
                    }
                    
                    List {
                        // Bind to reorderablePrayers so we can reorder them with .onMove
                        ForEach(reorderablePrayers, id: \.self) { prayer in
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
                                
                                // Invisible NavigationLink to remove arrow on the right
                                NavigationLink(destination: PrayerEditView(prayer: prayer)) {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onMove(perform: movePrayer)
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
            // Sync our reorderablePrayers whenever the filtered prayers change
            .onChange(of: searchManager.filteredPrayers) { _ in
                updateReorderablePrayers()
            }
            .onAppear {
                updateReorderablePrayers()
            }
        }
    }
}

// MARK: - Private Helpers
extension PrayerListView {
    /// Whether searchManager.searchText is an EXACT match to a TagEntity in Core Data
    private var isTagExactMatch: Bool {
        let trimmed = searchManager.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        let fetchReq: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: "tag == %@", trimmed)
        fetchReq.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchReq)
            return !results.isEmpty
        } catch {
            print("Error checking exact tag match: \(error)")
            return false
        }
    }
    
    /// Updates our local reorderable array based on searchManager's filteredPrayers
    private func updateReorderablePrayers() {
        reorderablePrayers = searchManager.filteredPrayers
    }
    
    /// Called by .onMove after the user drags a row
    private func movePrayer(from source: IndexSet, to destination: Int) {
        reorderablePrayers.move(fromOffsets: source, toOffset: destination)
        
        // If the search text is an EXACT match to a tag, we update that tag's order
        // in descending order (top item => highest order).
        if isTagExactMatch {
            let total = reorderablePrayers.count
            
            for (idx, prayer) in reorderablePrayers.enumerated() {
                let newOrder = Int16(total - idx)  // highest at the top
                
                // Find the TagEntity that matches the search text
                if let tagSet = prayer.tags as? Set<TagEntity> {
                    if let matchingTag = tagSet.first(where: { $0.tag == searchManager.searchText }) {
                        matchingTag.order = newOrder
                        matchingTag.lastModifiedDate = Date()
                    }
                }
                
                // Optionally update the prayer too
                prayer.lastModifiedDate = Date()
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Error saving after reorder: \(error)")
            }
            
            // Re-run the search if you want the new order to be reflected
            searchManager.refresh()
        }
    }
}
