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

    // Requests
    @FetchRequest private var requests: FetchedResults<RequestEntity>
    // Passages
    @FetchRequest private var passages: FetchedResults<PassageEntity>
    // Tags (now one-to-many from Prayer to Tag)
    @FetchRequest private var tags: FetchedResults<TagEntity>

    init(prayer: PrayerEntity) {
        self.prayer = prayer
        
        // Filter: "prayer == current prayer" for requests
        let predicateRequests = NSPredicate(format: "prayer == %@", prayer)
        _requests = FetchRequest<RequestEntity>(
            sortDescriptors: [NSSortDescriptor(keyPath: \RequestEntity.lastModifiedDate, ascending: false)],
            predicate: predicateRequests,
            animation: .default
        )

        // Filter: "prayer == current prayer" for passages
        let predicatePassages = NSPredicate(format: "prayer == %@", prayer)
        _passages = FetchRequest<PassageEntity>(
            sortDescriptors: [NSSortDescriptor(keyPath: \PassageEntity.lastModifiedDate, ascending: false)],
            predicate: predicatePassages,
            animation: .default
        )

        // For Tags in a one-to-many: "prayer == %@", prayer
        let predicateTags = NSPredicate(format: "prayer == %@", prayer)
        _tags = FetchRequest<TagEntity>(
            sortDescriptors: [NSSortDescriptor(keyPath: \TagEntity.tag, ascending: true)],
            predicate: predicateTags,
            animation: .default
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // MARK: - Prayer Title
            Text(prayer.title ?? "")
                .font(.headline)
            
            // MARK: - Passages Section
            if !passages.isEmpty {
                Divider()
                ForEach(passages, id: \.self) { passage in
                    Text(passage.passage ?? "Untitled Passage")
                }
            }

            // MARK: - Requests Section
            if !requests.isEmpty {
                Divider()
                ForEach(requests, id: \.self) { request in
                    // Bullet points for each Request
                    HStack(alignment: .top) {
                        Text("•")
                            .padding(.trailing, 4)
                        Text(request.request ?? "Untitled Request")
                    }
                }
            }

            // MARK: - Tags Section
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

