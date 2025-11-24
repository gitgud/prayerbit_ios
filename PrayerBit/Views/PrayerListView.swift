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

    // Search manager
    @StateObject private var searchManager = PrayerSearchManager()

    // Local copy of prayers used for the List + reordering
    @State private var reorderablePrayers: [PrayerEntity] = []

    // Whether the search field is focused
    @FocusState private var searchIsFocused: Bool

    // Status filters (multiple can be active). Waiting is default.
    @State private var selectedFilters: Set<FilterStatus> = [.waiting]

    // From MainAppView
    @Binding var isKeyboardActive: Bool
    @Binding var hideMenu: Bool

    init(isKeyboardActive: Binding<Bool>, hideMenu: Binding<Bool>) {
        self._isKeyboardActive = isKeyboardActive
        self._hideMenu = hideMenu
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Search")
                            .font(.title)
                            .bold()
                        Spacer()
                        NavigationLink(destination: PrayerCreateView()) {
                            Image(systemName: "plus")
                                .font(.title2)
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .systemGroupedBackground))

                    // Combined search bar with inline status filter buttons
                    HStack(spacing: 8) {
                        // Magnifying glass icon on the left
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)

                        // Search text field bound to the search manager
                        TextField(
                            "Search...",
                            text: Binding(
                                get: { searchManager.searchText },
                                set: { searchManager.searchText = $0 }
                            )
                        )
                        .focused($searchIsFocused)

                        // Spacer to push filter buttons to the right.
                        // Increase minLength so the filter buttons sit slightly more to the right.
                        Spacer(minLength: 12)

                        // Inline filter buttons
                        HStack(spacing: 4) {
                            ForEach(FilterStatus.allCases, id: \.self) { filter in
                                Button {
                                    toggleFilter(filter)
                                } label: {
                                    Text(filter.rawValue)
                                        .font(.system(size: 18))
                                        .frame(width: 32, height: 32)
                                        .background(
                                            filter.color.opacity(
                                                selectedFilters.contains(filter) ? 1.0 : 0.6
                                            )
                                        )
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                        // Outline the button with a black stroke when selected
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.black, lineWidth: selectedFilters.contains(filter) ? 2 : 0)
                                        )
                                }
                            }
                        }
                    }
                    // Style the search bar container
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            // Use a very light gray fill similar to the example search bar
                            .fill(Color(uiColor: .systemGray6))
                    )
                    // Add a subtle border to match the container style
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(uiColor: .separator), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                    // List of prayers
                    List {
                        ForEach(reorderablePrayers, id: \.self) { prayer in
                            ZStack {
                                // Card content – only show requests that match filters
                                PrayerDetailView(
                                    prayer: prayer,
                                    activeFilterStatuses: selectedFilters
                                )
                                .padding(1)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1),
                                                radius: 4, x: 0, y: 2)
                                )
                                .padding(.vertical, 0)

                                // Invisible NavigationLink so tap opens full edit view
                                NavigationLink(
                                    destination: PrayerEditView(
                                        prayer: prayer,
                                        isKeyboardActive: $isKeyboardActive,
                                        hideMenu: $hideMenu
                                    )
                                ) {
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
                // Provide the context to the manager once
                searchManager.setContext(viewContext)

                // Optional: don’t auto-focus
                DispatchQueue.main.async {
                    searchIsFocused = false
                }

                updateReorderablePrayers()
            }
            .onChange(of: searchManager.filteredPrayers) { _ in
                updateReorderablePrayers()
            }
        }
    }
}

// MARK: - Helpers

extension PrayerListView {
    private func toggleFilter(_ filter: FilterStatus) {
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
        updateReorderablePrayers()
    }

    private func movePrayer(from source: IndexSet, to destination: Int) {
        // Local reorder only – keeps UI happy without touching Core Data.
        var updated = reorderablePrayers
        updated.move(fromOffsets: source, toOffset: destination)
        reorderablePrayers = updated
    }

    private func updateReorderablePrayers() {
        // Base set from search manager
        let matching = searchManager.filteredPrayers

        // Filter by selected request statuses
        let filteredByStatus = matching.filter { prayer in
            guard let requestSet = prayer.requests as? Set<RequestEntity>,
                  !requestSet.isEmpty
            else {
                // If no requests, keep the prayer regardless
                return true
            }

            // Does this prayer have at least one request whose status
            // is in the selected filter set?
            let allowedStatuses = Set(selectedFilters.map(\.coreDataRaw))
            return requestSet.contains { req in
                if let status = req.status {
                    return allowedStatuses.contains(status)
                } else {
                    return false
                }
            }
        }

        reorderablePrayers = filteredByStatus
    }
}

enum FilterStatus: String, CaseIterable {
    case waiting   = "⏳"
    case fulfilled = "✔️"
    case rejected  = "✘"
    case unknown   = "🤷‍♂️"   // male shrug

    /// Button background color
    var color: Color {
        switch self {
        case .waiting:   return .yellow
        case .fulfilled: return .green
        case .rejected:  return .red
        case .unknown:   return .gray
        }
    }

    /// The value stored in Core Data's `status` field
    var coreDataRaw: String {
        switch self {
        case .waiting:   return "Waiting"
        case .fulfilled: return "Fulfilled"
        case .rejected:  return "Rejected"
        case .unknown:   return "Unknown"
        }
    }
}

