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
    
    // A FetchRequest that fetches only those RequestEntities
    // where prayer == the provided `prayer`
    @FetchRequest private var requests: FetchedResults<RequestEntity>
    
    // A FetchRequest that fetches only those PassageEntities
    // where prayer == the provided `prayer`
    @FetchRequest private var passages: FetchedResults<PassageEntity>
    
    // Initialize your fetch requests with a predicate for this prayer
    init(prayer: PrayerEntity) {
        self.prayer = prayer
        
        // Filter: "prayer == current prayer"
        let predicate = NSPredicate(format: "prayer == %@", prayer)
        
        _requests = FetchRequest<RequestEntity>(
            sortDescriptors: [NSSortDescriptor(keyPath: \RequestEntity.lastModifiedDate, ascending: false)],
            predicate: predicate,
            animation: .default
        )
        
        _passages = FetchRequest<PassageEntity>(
            sortDescriptors: [NSSortDescriptor(keyPath: \PassageEntity.lastModifiedDate, ascending: false)],
            predicate: predicate,
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
            
            // MARK: Tags (HORIZONTAL)
            // Example: many-to-many or one-to-many relationship from prayer to TagEntity
            if let tagSet = prayer.tags as? Set<TagEntity>, !tagSet.isEmpty {
                let sortedTags = tagSet.sorted { ($0.tag ?? "") < ($1.tag ?? "") }
                
                Text("Tags:")
                    .font(.subheadline)
                
                // Horizontal layout with an HStack
                HStack {
                    ForEach(sortedTags, id: \.self) { tagItem in
                        Text("#\(tagItem.tag ?? "Tag")")
                            .font(.callout)
                            .foregroundColor(.blue)
                    }
                }
            } else {
                Text("No tags yet.")
                    .foregroundColor(.secondary)
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
        
        // Create some Tags (assuming `TagEntity` has `id`, `tag` attributes)
        for tagText in ["Family", "Urgent", "Celebration"] {
            let newTag = TagEntity(context: context)
            newTag.id = UUID()
            newTag.tag = tagText
            // If it's a many-to-many relationship, do e.g. samplePrayer.addToTags(newTag)
            // If it's one-to-many, do newTag.prayer = samplePrayer
            samplePrayer.addToTags(newTag)
        }
        
        return NavigationView {
            PrayerDetailView(prayer: samplePrayer)
                .environment(\.managedObjectContext, context)
        }
    }
}
