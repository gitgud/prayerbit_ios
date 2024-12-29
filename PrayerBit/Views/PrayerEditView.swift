//
//  PrayerEditView.swift
//  PrayerBit
//
//  Created by kale on 12/25/24.
//

import SwiftUI
import CoreData

struct PrayerEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var prayer: PrayerEntity
    
    // Focus states for inline editing
    @FocusState private var focusedRequestID: NSManagedObjectID?
    @FocusState private var focusedTagID: NSManagedObjectID?

    var body: some View {
        Form {
            // MARK: - Prayer
            Section("Prayer") {
                TextField("Title", text: Binding(
                    get: { prayer.title ?? "" },
                    set: { newValue in
                        prayer.title = newValue
                        prayer.lastModifiedDate = Date()
                        saveContext()
                    }
                ))
            }
            
            // MARK: - Requests (unchanged from your code)
            Section("Requests") {
                let requestsArray = sortedRequests()
                ForEach(requestsArray, id: \.objectID) { req in
                    TextField("Request",
                        text: Binding(
                            get: { req.request ?? "" },
                            set: { newValue in
                                req.request = newValue
                                req.lastModifiedDate = Date()
                                prayer.lastModifiedDate = Date()
                                saveContext()
                            }
                        )
                    )
                    .focused($focusedRequestID, equals: req.objectID)
                }
                
                Button("Add Request", action: addNewRequest)
            }

            // MARK: - Tags
            Section("Tags") {
                let tagsArray = sortedTags()
                ForEach(tagsArray, id: \.objectID) { tag in
                    TextField("Tag",
                        text: Binding(
                            get: { tag.tag ?? "" },
                            set: { newValue in
                                tag.tag = newValue
                                // If you have a lastModifiedDate in TagEntity, set it here:
                                // tag.lastModifiedDate = Date()
                                prayer.lastModifiedDate = Date()
                                saveContext()
                            }
                        )
                    )
                    .focused($focusedTagID, equals: tag.objectID)
                }
                
                Button("Add Tag", action: addNewTag)
            }
        }
        .navigationTitle("Edit Prayer")
        .toolbar {
            // 1) If a tag is currently focused, show "Delete Tag" button
            if let currentTag = currentFocusedTag() {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete Tag") {
                        deleteTag(currentTag)
                    }
                }
            }
            // 2) Otherwise, if a request is currently focused, show "Delete Request" button
            else if let currentRequest = currentFocusedRequest() {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete Request") {
                        deleteRequest(currentRequest)
                    }
                }
            }
        }
    }
}

// MARK: - Helpers
extension PrayerEditView {
    // ---------- Requests ----------
    private func sortedRequests() -> [RequestEntity] {
        guard let requestSet = prayer.requests as? Set<RequestEntity> else { return [] }
        return requestSet.sorted {
            ($0.creationDate ?? Date()) < ($1.creationDate ?? Date())
        }
    }

    private func addNewRequest() {
        let newReq = RequestEntity(context: viewContext)
        newReq.id = UUID()
        newReq.request = "New Request"
        newReq.creationDate = Date()
        newReq.lastModifiedDate = Date()
        
        // Link many-to-one
        newReq.prayer = prayer

        prayer.lastModifiedDate = Date()
        saveContext()
        
        // Focus this new request
        focusedRequestID = newReq.objectID
    }
    
    private func currentFocusedRequest() -> RequestEntity? {
        guard let id = focusedRequestID else { return nil }
        return sortedRequests().first { $0.objectID == id }
    }
    
    private func deleteRequest(_ request: RequestEntity) {
        viewContext.delete(request)
        focusedRequestID = nil
        prayer.lastModifiedDate = Date()
        saveContext()
    }
    
    // ---------- Tags (MANY-TO-MANY) ----------
    private func sortedTags() -> [TagEntity] {
        // prayer.tags is typically an NSSet?
        // Xcode auto-generates "public var tags: NSSet?" or "public var tags: Set<TagEntity>"
        // Use the typed generated accessors if they exist, or cast if needed.
        // e.g., if you have 'public var tags: Set<TagEntity>' in your generated code, just do `prayer.tags.sorted(by:)`.
        
        guard let tagSet = prayer.tags as? Set<TagEntity> else { return [] }
        // Sort by some attribute, if you want:
        // If TagEntity has creationDate, do something like:
        //   return tagSet.sorted { ($0.creationDate ?? Date()) < ($1.creationDate ?? Date()) }
        // Otherwise, sort by `tag` string lexically, or skip sorting:
        
        return tagSet.sorted { ($0.tag ?? "") < ($1.tag ?? "") }
    }
    
    private func addNewTag() {
        let newTag = TagEntity(context: viewContext)
        newTag.id = UUID()
        newTag.tag = "New Tag"
        // If you have creationDate in TagEntity, set it:
        // newTag.creationDate = Date()
        
        // Because it's a many-to-many, we can't do newTag.prayer = prayer (that's for a to-one).
        // Instead, we can use the generated accessor:
        // prayer.addToTags(newTag)
        // Or newTag.addToPrayers(prayer)
        // Either way updates both sides of the relationship.
        
        prayer.addToTags(newTag)
        
        prayer.lastModifiedDate = Date()
        saveContext()
        
        // Focus the new tag
        focusedTagID = newTag.objectID
    }

    private func currentFocusedTag() -> TagEntity? {
        guard let id = focusedTagID else { return nil }
        return sortedTags().first { $0.objectID == id }
    }

    private func deleteTag(_ tag: TagEntity) {
        // Because it's many-to-many, we typically remove it from the prayer's set
        // (and maybe from other prayers if it’s no longer needed).
        // If you truly want to remove the Tag from the entire store, you can just delete it:
        //   viewContext.delete(tag)
        // But that might break other prayers that share this tag, so it depends on your design.
        
        // If each tag is used by multiple prayers, you might do:
        //   prayer.removeFromTags(tag)
        // so it’s no longer associated with just this prayer, but still around for other prayers.
        // However, if your design means no tag is used for more than one prayer, go ahead and delete it from the context.
        
        // Example: remove it from just this prayer
        prayer.removeFromTags(tag)
        
        // If you want to permanently remove it from the data store:
        // viewContext.delete(tag)

        focusedTagID = nil
        prayer.lastModifiedDate = Date()
        saveContext()
    }
    
    // ---------- Save ----------
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
