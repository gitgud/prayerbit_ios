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
    @FocusState private var focusedTagID: NSManagedObjectID?
    
    // Tells MainAppView if any text field is currently focused
    @Binding var isKeyboardActive: Bool
    
    // If true, the bottom menu is hidden. We want it hidden as long as this View is presented.
    @Binding var hideMenu: Bool
    
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
                    // 1) Background color based on status
                    .listRowBackground(requestStatusColor(request))
                    // 2) Swipe actions for status changes
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Waiting") {
                            setRequestStatus(request, to: "Waiting")
                        }
                        .tint(.yellow)
                        
                        Button("Fulfilled") {
                            setRequestStatus(request, to: "Fulfilled")
                        }
                        .tint(.green)
                        
                        Button("Rejected") {
                            setRequestStatus(request, to: "Rejected")
                        }
                        .tint(.red)
                        
                        Button("Unknown") {
                            setRequestStatus(request, to: "Unknown")
                        }
                        .tint(.gray)
                    }
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
                                    // 1) Update Tag's lastModifiedDate
                                    tag.lastModifiedDate = Date()
                                    
                                    // 2) Recount how many tags in Core Data share this exact string
                                    let sameTagCount = countTags(with: newValue)
                                    tag.order = Int16(sameTagCount)
                                    
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
        // Whenever a focus changes, see if anything is focused, and update isKeyboardActive
        .onChange(of: focusedRequestID) { _ in updateKeyboardActive() }
        .onChange(of: focusedPassageID) { _ in updateKeyboardActive() }
        .onChange(of: focusedTagID) { _ in updateKeyboardActive() }
        // Hide the menu while this view is on screen
        .onAppear {
            hideMenu = true
        }
        .onDisappear {
            hideMenu = false
        }
    }
}

// MARK: - Helpers for Focus
extension PrayerEditView {
    private func updateKeyboardActive() {
        // If any field is focused, we consider the keyboard "active."
        isKeyboardActive = (
            focusedRequestID != nil ||
            focusedPassageID != nil ||
            focusedTagID != nil
        )
    }
}

// MARK: - Deletable Enum + Logic
extension PrayerEditView {
    private enum Deletable {
        case passage(PassageEntity)
        case request(RequestEntity)
        case tag(TagEntity)
    }
    
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
        // Sort by status order first, then by creation date.
        // The order is: Waiting(0), Fulfilled(1), Rejected(2), Unknown(3)
        return requestSet.sorted { left, right in
            let leftOrder = sortOrder(for: left)
            let rightOrder = sortOrder(for: right)
            
            if leftOrder == rightOrder {
                // Tie-breaker: fallback to creation date
                return (left.creationDate ?? Date()) < (right.creationDate ?? Date())
            } else {
                return leftOrder < rightOrder
            }
        }
    }
    
    private func sortOrder(for request: RequestEntity) -> Int {
        switch request.status {
        case "Waiting":
            return 0
        case "Fulfilled":
            return 1
        case "Rejected":
            return 2
        case "Unknown":
            return 3
        default:
            return 4
        }
    }
    
    private func addNewRequest() {
        let newRequest = RequestEntity(context: viewContext)
        newRequest.id = UUID()
        newRequest.request = "New Request"
        newRequest.creationDate = Date()
        newRequest.lastModifiedDate = Date()
        newRequest.prayer = prayer
        
        // Default status to "Waiting"
        newRequest.status = "Waiting"
        
        prayer.lastModifiedDate = Date()
        saveContext()
        
        // Focus the newly created request
        focusedRequestID = newRequest.objectID
    }
    
    /// Helper method to set the status on a request and save.
    private func setRequestStatus(_ request: RequestEntity, to newStatus: String) {
        request.status = newStatus
        request.lastModifiedDate = Date()
        prayer.lastModifiedDate = Date()
        saveContext()
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
        newTag.lastModifiedDate = Date() // 1) Set Tag's lastModifiedDate
        newTag.prayer = prayer
        
        // 2) Count how many tags in the store have this exact same `tag`.
        let sameTagCount = countTags(with: newTag.tag ?? "")
        newTag.order = Int16(sameTagCount + 1) // +1 to include this new tag
        
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
        viewContext.delete(tag)
        focusedTagID = nil
        prayer.lastModifiedDate = Date()
        saveContext()
    }
}

// MARK: - Count Tags Helper
extension PrayerEditView {
    private func countTags(with text: String) -> Int {
        let request: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        request.predicate = NSPredicate(format: "tag == %@", text)
        
        do {
            return try viewContext.fetch(request).count
        } catch {
            print("Error counting tags for text \(text): \(error)")
            return 0
        }
    }
}

// MARK: - Row Color Helper
extension PrayerEditView {
    /// Returns a color for the request row based on status.
    private func requestStatusColor(_ request: RequestEntity) -> Color {
        switch request.status {
        case "Waiting":
            return Color.yellow.opacity(0.3)
        case "Fulfilled":
            return Color.green.opacity(0.3)
        case "Rejected":
            return Color.red.opacity(0.3)
        case "Unknown":
            // A dark gray that’s a bit darker than the background
            return Color.gray.opacity(0.3)
        default:
            return Color.clear
        }
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
