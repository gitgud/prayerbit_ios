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
    
    // Whether the search field is focused
    @FocusState private var searchIsFocused: Bool
    
    // MARK: - A set of statuses (so multiple can be selected). "Waiting" is selected by default.
    @State private var selectedFilters: Set<FilterStatus> = [.waiting]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gray background behind everything
                Color(uiColor: .systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    
                    // MARK: - Top Search Bar + Plus Button
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
                    
                    // MARK: - Filter Buttons (Below the Search Bar)
                    HStack(spacing: 4) {
                        ForEach(FilterStatus.allCases, id: \.self) { filter in
                            Button {
                                toggleFilter(filter)
                            } label: {
                                Text(filter.rawValue)
                                    // Bold if selected
                                    .fontWeight(selectedFilters.contains(filter) ? .bold : .regular)
                                    .foregroundColor(.white)
                                    .font(.callout)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    // Full color if selected, slightly faded if not
                                    .background(
                                        filter.color.opacity(selectedFilters.contains(filter) ? 1.0 : 0.6)
                                    )
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // MARK: - Drag-to-Reorder List (Shown if exact tag match)
                    if isTagExactMatch {
                        HStack {
                            Spacer()
                            EditButton()
                                .padding(.trailing, 16)
                        }
                    }
                    
                    // MARK: - The Prayers List
                    List {
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
            // Whenever the search results change, we re-filter them based on our buttons
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
    /// Toggle filter selection (on/off).
    private func toggleFilter(_ filter: FilterStatus) {
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
        updateReorderablePrayers()
    }
    
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
    
    /// **Key Change**:
    /// 1) Start with `searchManager.filteredPrayers` (already narrowed by tags/title/requests).
    /// 2) Keep only those that have *no requests* or at least *one request* with a status in `selectedFilters`.
    private func updateReorderablePrayers() {
        // Step 1: All prayers that match the search
        let matching = searchManager.filteredPrayers
        
        // Step 2: Filter by request status or "no requests"
        reorderablePrayers = matching.filter { prayer in
            // If no requests, it should appear.
            guard let requestSet = prayer.requests as? Set<RequestEntity>, !requestSet.isEmpty else {
                // No requests => keep this prayer
                return true
            }
            
            // If it has requests, keep it only if at least one request's status is in selectedFilters
            // Compare request.status to the rawValue (e.g. "Waiting", "Fulfilled", etc.)
            for req in requestSet {
                if let reqStatus = req.status, selectedFilters.map(\.rawValue).contains(reqStatus) {
                    return true
                }
            }
            // If none of its requests matched the selected statuses
            return false
        }
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

// MARK: - Filter Status Enum
/// Example enum with four statuses matching your color scheme.
/// (Supports multiple selection.)
enum FilterStatus: String, CaseIterable {
    case waiting    = "Waiting"
    case fulfilled  = "Fulfilled"
    case rejected   = "Rejected"
    case unknown    = "Unknown"
    
    var color: Color {
        switch self {
        case .waiting:   return .yellow
        case .fulfilled: return .green
        case .rejected:  return .red
        case .unknown:   return .gray
        }
    }
}
