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
    
    // A set of statuses (so multiple can be selected). "Waiting" is selected by default.
    @State private var selectedFilters: Set<FilterStatus> = [.waiting]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
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
                    
                    // MARK: - Filter Buttons
                    HStack(spacing: 4) {
                        ForEach(FilterStatus.allCases, id: \.self) { filter in
                            Button {
                                toggleFilter(filter)
                            } label: {
                                Text(filter.rawValue)
                                    .fontWeight(selectedFilters.contains(filter) ? .bold : .regular)
                                    .foregroundColor(.white)
                                    .font(.callout)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        filter.color.opacity(selectedFilters.contains(filter) ? 1.0 : 0.6)
                                    )
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // MARK: - Prayers List
                    List {
                        ForEach(reorderablePrayers, id: \.self) { prayer in
                            ZStack {
                                PrayerDetailView(prayer: prayer)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                                    .padding(.vertical, 4)
                                
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
                    
                    // MARK: - Bottom Menu
                    MenuView()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Provide the context to the manager & force a fetch
                searchManager.setContext(viewContext)
                
                // Optionally focus on the search bar automatically
                DispatchQueue.main.async {
                    searchIsFocused = true
                }
            }
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
    private func toggleFilter(_ filter: FilterStatus) {
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
        updateReorderablePrayers()
    }
    
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
    
    private func updateReorderablePrayers() {
        let matching = searchManager.filteredPrayers
        reorderablePrayers = matching.filter { prayer in
            guard let requestSet = prayer.requests as? Set<RequestEntity>, !requestSet.isEmpty else {
                return true
            }
            // Keep prayer if at least one request matches the selected filters
            for req in requestSet {
                if let reqStatus = req.status,
                   selectedFilters.map(\.rawValue).contains(reqStatus) {
                    return true
                }
            }
            return false
        }
    }
    
    private func movePrayer(from source: IndexSet, to destination: Int) {
        reorderablePrayers.move(fromOffsets: source, toOffset: destination)
        
        // If search text exactly matches a TagEntity, reorder that tag
        if isTagExactMatch {
            let total = reorderablePrayers.count
            for (idx, prayer) in reorderablePrayers.enumerated() {
                let newOrder = Int16(total - idx)
                
                // Find the TagEntity that matches search text
                if let tagSet = prayer.tags as? Set<TagEntity>,
                   let matchingTag = tagSet.first(where: { $0.tag == searchManager.searchText }) {
                    
                    matchingTag.order = newOrder
                    matchingTag.lastModifiedDate = Date()
                }
                
                prayer.lastModifiedDate = Date()
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Error saving after reorder: \(error)")
            }
            
            // Refresh search if needed
            searchManager.refresh()
        }
    }
}

enum FilterStatus: String, CaseIterable {
    case waiting   = "Waiting"
    case fulfilled = "Fulfilled"
    case rejected  = "Rejected"
    case unknown   = "Unknown"
    
    var color: Color {
        switch self {
        case .waiting:   return .yellow
        case .fulfilled: return .green
        case .rejected:  return .red
        case .unknown:   return .gray
        }
    }
}
