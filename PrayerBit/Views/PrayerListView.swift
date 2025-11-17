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

                    // Search box
                    HStack {
                        TextField(
                            "Search...",
                            text: Binding(
                                get: { searchManager.searchText },
                                set: { searchManager.searchText = $0 }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .focused($searchIsFocused)
                    }
                    .padding(.horizontal)

                    // Filter buttons
                    HStack(spacing: 4) {
                        ForEach(FilterStatus.allCases, id: \.self) { filter in
                            Button {
                                toggleFilter(filter)
                            } label: {
                                Text(filter.rawValue)
                                    .fontWeight(selectedFilters.contains(filter) ? .bold : .regular)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(
                                        filter.color.opacity(
                                            selectedFilters.contains(filter) ? 1.0 : 0.6
                                        )
                                    )
                                    .cornerRadius(6)
                            }
                        }
                    }
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
                // Give the manager a context once
                searchManager.setContext(viewContext)

                // Optionally focus the search bar
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
            let allowedStatuses = Set(selectedFilters.map(\.rawValue))
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

// MARK: - FilterStatus

enum FilterStatus: String, CaseIterable {
    case waiting   = "Waiting"
    case fulfilled = "Fulfilled"
    case rejected  = "Rejected"
    case unknown   = "?"

    var color: Color {
        switch self {
        case .waiting:   return .yellow
        case .fulfilled: return .green
        case .rejected:  return .red
        case .unknown:   return .gray
        }
    }
}
