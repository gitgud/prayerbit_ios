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
    // Tags (many-to-many)
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

        // For Tags in many-to-many: "ANY prayers == current prayer"
        let predicateTags = NSPredicate(format: "ANY prayers == %@", prayer)
        _tags = FetchRequest<TagEntity>(
            sortDescriptors: [NSSortDescriptor(keyPath: \TagEntity.tag, ascending: true)],
            predicate: predicateTags,
            animation: .default
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // MARK: Prayer Title
            Text(prayer.title ?? "")
                .font(.headline)
            
            Divider()
            
            // MARK: Passages
            if passages.isEmpty {
                Text("No passages yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(passages, id: \.self) { passage in
                    Text(passage.passage ?? "Untitled Passage")
                }
            }
            
            Divider()
            
            // MARK: Requests
            if requests.isEmpty {
                Text("No requests yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(requests, id: \.self) { request in
                    Text(request.request ?? "Untitled Request")
                }
            }

            Divider()

            // MARK: Tags (Many-to-Many)
            if tags.isEmpty {
                Text("No tags yet.")
                    .foregroundColor(.secondary)
            } else {
                // Show them horizontally with a leading "#"
                HStack {
                    ForEach(tags, id: \.self) { tag in
                        Text("#\(tag.tag ?? "Tag")")
                            .font(.callout)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Prayer Details")
    }
}

// MARK: Preview
struct PrayerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // Create a sample Prayer
        let samplePrayer = PrayerEntity(context: context)
        samplePrayer.id = UUID()
        samplePrayer.title = "Pray for Peace"
        samplePrayer.creationDate = Date().addingTimeInterval(-86400) // 1 day ago
        samplePrayer.lastModifiedDate = Date()
        
        // Create some Requests
        for i in 1...3 {
            let newRequest = RequestEntity(context: context)
            newRequest.id = UUID()
            newRequest.request = "Request #\(i)"
            newRequest.creationDate = Date().addingTimeInterval(Double(-i) * 3600)
            newRequest.lastModifiedDate = Date()
            newRequest.prayer = samplePrayer
        }
        
        // Create some Tags (assuming `TagEntity` has `id`, `tag` attributes and many-to-many with PrayerEntity)
        for tagText in ["Family", "Urgent", "Celebration"] {
            let newTag = TagEntity(context: context)
            newTag.id = UUID()
            newTag.tag = tagText
            // many-to-many => samplePrayer.addToTags(newTag)
            samplePrayer.addToTags(newTag)
        }
        
        return NavigationView {
            PrayerDetailView(prayer: samplePrayer)
                .environment(\.managedObjectContext, context)
        }
    }
}
