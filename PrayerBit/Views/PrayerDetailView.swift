//
//  PrayerDetailView.swift
//  PrayerBit
//
//  Created by kale on 12/25/24.
//

import SwiftUI
import CoreData

struct PrayerDetailView: View {
    @ObservedObject var prayer: PrayerEntity

    /// Optional filter set coming from the list screen.
    /// If `nil` or empty we show *all* requests.
    var activeFilterStatuses: Set<FilterStatus>? = nil

    // Requests
    @FetchRequest private var requests: FetchedResults<RequestEntity>
    // Passages
    @FetchRequest private var passages: FetchedResults<PassageEntity>
    // Tags
    @FetchRequest private var tags: FetchedResults<TagEntity>

    init(prayer: PrayerEntity, activeFilterStatuses: Set<FilterStatus>? = nil) {
        self.prayer = prayer
        self.activeFilterStatuses = activeFilterStatuses

        let basePredicate = NSPredicate(format: "prayer == %@", prayer)

        // Requests: respect filters if provided, otherwise show all
        let predicateRequests: NSPredicate
        if let filters = activeFilterStatuses, !filters.isEmpty {
            let rawStatuses = filters.map(\.rawValue)
            let statusPredicate = NSPredicate(format: "status IN %@", rawStatuses)
            predicateRequests = NSCompoundPredicate(andPredicateWithSubpredicates: [
                basePredicate,
                statusPredicate
            ])
        } else {
            predicateRequests = basePredicate
        }

        _requests = FetchRequest<RequestEntity>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \RequestEntity.lastModifiedDate, ascending: false)
            ],
            predicate: predicateRequests,
            animation: .default
        )

        _passages = FetchRequest<PassageEntity>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \PassageEntity.lastModifiedDate, ascending: false)
            ],
            predicate: basePredicate,
            animation: .default
        )

        _tags = FetchRequest<TagEntity>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \TagEntity.tag, ascending: true)
            ],
            predicate: basePredicate,
            animation: .default
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title
            Text(prayer.title ?? "")
                .font(.headline)

            // Passages
            if !passages.isEmpty {
                Divider()
                ForEach(passages, id: \.self) { passage in
                    Text(passage.passage ?? "Untitled Passage")
                }
            }

            // Requests
            if !requests.isEmpty {
                Divider()
                ForEach(requests, id: \.self) { request in
                    HStack(alignment: .top) {
                        Text("•")
                            .padding(.trailing, 4)
                        Text(request.request ?? "Untitled Request")
                    }
                }
            }

            // Tags
            if !tags.isEmpty {
                Divider()
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        Text("#\(tag.tag ?? "Tag")")
                            .font(.callout)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.init(top: 4, leading: 10, bottom: 8, trailing: 10))
        .navigationTitle("Prayer Details")
    }
}
