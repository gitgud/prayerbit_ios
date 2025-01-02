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
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject var prayer: PrayerEntity
    
    // MARK: Focus States
    @FocusState private var focusedRequestID: NSManagedObjectID?
    @FocusState private var focusedPassageID: NSManagedObjectID?
    @FocusState private var focusedTagID: NSManagedObjectID?  // <-- For tags
    
    // MARK: Body
    var body: some View {
        Form {
            // MARK: Prayer
            Section(header: Text("Prayer")) {
                TextField("Title", text: Binding(
                    get: { prayer.title ?? "" },
                    set: { newValue in
                        prayer.title = newValue
                        prayer.lastModifiedDate = Date()
                        saveContext()
                    }
                ))
            }
            
            // MARK: Passages
            Section(header: Text("Passages")) {
                let passagesArray = sortedPassages()
                
                ForEach(passagesArray, id: \.objectID) { passage in
                    TextField("Passage",
                              text: Binding(
                                get: { passage.passage ?? "" },
                                set: { newValue in
                                    passage.passage = newValue
                                    passage.lastModifiedDate = Date()
                                    prayer.lastModifiedDate = Date()
                                    saveContext()
                                }
                              )
                    )
                    .focused($focusedPassageID, equals: passage.objectID)
                }
                
                Button {
                    addNewPassage()
                } label: {
                    Label("Add Passage", systemImage: "plus.circle")
                }
            }
            
            // MARK: Requests
            Section(header: Text("Requests")) {
                let requestsArray = sortedRequests()
                
                ForEach(requestsArray, id: \.objectID) { request in
                    TextField("Request",
                              text: Binding(
                                get: { request.request ?? "" },
                                set: { newValue in
                                    request.request = newValue
                                    request.lastModifiedDate = Date()
                                    prayer.lastModifiedDate = Date()
                                    saveContext()
                                }
                              )
                    )
                    .focused($focusedRequestID, equals: request.objectID)
                }
                
                Button {
                    addNewRequest()
                } label: {
                    Label("Add Request", systemImage: "plus.circle")
                }
            }
            
            // MARK: Tags
            Section(header: Text("Tags")) {
                let tagsArray = sortedTags()
                
                ForEach(tagsArray, id: \.objectID) { tag in
                    TextField("Tag",
                              text: Binding(
                                get: { tag.tag ?? "" },
                                set: { newValue in
                                    tag.tag = newValue
                                    // If TagEntity also has lastModifiedDate, set it here:
                                    // tag.lastModifiedDate = Date()
                                    prayer.lastModifiedDate = Date()
                                    saveContext()
                                }
                              )
                    )
                    .focused($focusedTagID, equals: tag.objectID)
                }
                
                Button {
                    addNewTag()
                } label: {
                    Label("Add Tag", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Edit Prayer")
        .toolbar {
            // If a sub-item is focused, show "Delete" for that item;
            // otherwise, show "Delete Prayer."
            if let deletable = itemToDelete() {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete") {
                        switch deletable {
                        case .passage(let passage):
                            deletePassage(passage)
                        case .request(let request):
                            deleteRequest(request)
                        case .tag(let tag):
                            deleteTag(tag)
                        }
                    }
                }
            } else {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete Prayer") {
                        deletePrayer()
                    }
                }
            }
        }
    }
}

// MARK: - Deletable Enum + Logic
extension PrayerEditView {
    private enum Deletable {
        case passage(PassageEntity)
        case request(RequestEntity)
        case tag(TagEntity)
    }
    
    /// Returns which item is currently focused, if any.
    private func itemToDelete() -> Deletable? {
        if let pass = currentFocusedPassage() { return .passage(pass) }
        if let req = currentFocusedRequest() { return .request(req) }
        if let tag = currentFocusedTag() { return .tag(tag) }
        return nil
    }
}

// MARK: - Prayer-Level Delete
extension PrayerEditView {
    private func deletePrayer() {
        // Delete the entire PrayerEntity
        viewContext.delete(prayer)
        saveContext()
        
        // Once deleted, go back
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Passages Helpers
extension PrayerEditView {
    private func sortedPassages() -> [PassageEntity] {
        guard let passagesSet = prayer.passage as? Set<PassageEntity> else { return [] }
        return passagesSet.sorted {
            ($0.creationDate ?? Date()) < ($1.creationDate ?? Date())
        }
    }
    
    private func addNewPassage() {
        let newPassage = PassageEntity(context: viewContext)
        newPassage.id = UUID()
        newPassage.passage = "New Passage"
        newPassage.creationDate = Date()
        newPassage.lastModifiedDate = Date()
        newPassage.prayer = prayer
        
        prayer.lastModifiedDate = Date()
        saveContext()
        
        // Focus the newly created passage
        focusedPassageID = newPassage.objectID
    }
    
    private func currentFocusedPassage() -> PassageEntity? {
        guard let fid = focusedPassageID else { return nil }
        return sortedPassages().first { $0.objectID == fid }
    }
    
    private func deletePassage(_ passage: PassageEntity) {
        viewContext.delete(passage)
        focusedPassageID = nil
        prayer.lastModifiedDate = Date()
        saveContext()
    }
}

// MARK: - Requests Helpers
extension PrayerEditView {
    private func sortedRequests() -> [RequestEntity] {
        guard let requestSet = prayer.requests as? Set<RequestEntity> else { return [] }
        return requestSet.sorted {
            ($0.creationDate ?? Date()) < ($1.creationDate ?? Date())
        }
    }
    
    private func addNewRequest() {
        let newRequest = RequestEntity(context: viewContext)
        newRequest.id = UUID()
        newRequest.request = "New Request"
        newRequest.creationDate = Date()
        newRequest.lastModifiedDate = Date()
        newRequest.prayer = prayer
        
        prayer.lastModifiedDate = Date()
        saveContext()
        
        // Focus the newly created request
        focusedRequestID = newRequest.objectID
    }
    
    private func currentFocusedRequest() -> RequestEntity? {
        guard let fid = focusedRequestID else { return nil }
        return sortedRequests().first { $0.objectID == fid }
    }
    
    private func deleteRequest(_ request: RequestEntity) {
        viewContext.delete(request)
        focusedRequestID = nil
        prayer.lastModifiedDate = Date()
        saveContext()
    }
}

// MARK: - Tags Helpers
extension PrayerEditView {
    private func sortedTags() -> [TagEntity] {
        guard let tagSet = prayer.tags as? Set<TagEntity> else { return [] }
        return tagSet.sorted {
            ($0.tag ?? "") < ($1.tag ?? "")
        }
    }
    
    private func addNewTag() {
        let newTag = TagEntity(context: viewContext)
        newTag.id = UUID()
        newTag.tag = "New Tag"
        
        // If your model is one-to-many, do: newTag.prayer = prayer
        // If your model is many-to-many, do:
        prayer.addToTags(newTag)
        
        prayer.lastModifiedDate = Date()
        saveContext()
        
        // Focus the new tag
        focusedTagID = newTag.objectID
    }
    
    private func currentFocusedTag() -> TagEntity? {
        guard let fid = focusedTagID else { return nil }
        return sortedTags().first { $0.objectID == fid }
    }
    
    private func deleteTag(_ tag: TagEntity) {
        // If many-to-many, you might remove it from just this prayer:
        // prayer.removeFromTags(tag)
        // Or fully delete from the store:
        viewContext.delete(tag)
        
        focusedTagID = nil
        prayer.lastModifiedDate = Date()
        saveContext()
    }
}

// MARK: - Save
extension PrayerEditView {
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
