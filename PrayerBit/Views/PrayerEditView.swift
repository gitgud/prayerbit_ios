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
    
    // MARK: Focus State for Requests
    // Stores the NSManagedObjectID of whichever request is currently focused
    @FocusState private var focusedRequestID: NSManagedObjectID?
    
    // MARK: Focus State for Passages
    // Stores the NSManagedObjectID of whichever passage is currently focused
    @FocusState private var focusedPassageID: NSManagedObjectID?

    var body: some View {
        Form {
            // MARK: - Prayer Section
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
            
            // MARK: - Passages Section
            Section(header: Text("Passages")) {
                let passagesArray = sortedPassages()
                
                ForEach(passagesArray, id: \.objectID) { passage in
                    TextField(
                        "Passage",
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
                    // Tie this specific TextField's focus to the passage's `objectID`
                    .focused($focusedPassageID, equals: passage.objectID)
                }
                
                // Add Passage inline
                Button(action: addNewPassage) {
                    Label("Add Passage", systemImage: "plus.circle")
                }
            }
            
            // MARK: - Requests Section
            Section(header: Text("Requests")) {
                let requestsArray = sortedRequests()
                
                ForEach(requestsArray, id: \.objectID) { request in
                    TextField(
                        "Request",
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
                    // Tie this specific TextField's focus to the request's `objectID`
                    .focused($focusedRequestID, equals: request.objectID)
                }
                
                // Add Request inline
                Button(action: addNewRequest) {
                    Label("Add Request", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Edit Prayer")
        .toolbar {
            // If there's a currently focused passage, show a "Delete" button for that passage
            if let currentPassage = currentFocusedPassage() {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete Passage") {
                        deletePassage(currentPassage)
                    }
                }
            }
            // Else if there's a currently focused request, show a "Delete" button for that request
            else if let currentRequest = currentFocusedRequest() {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete Request") {
                        deleteRequest(currentRequest)
                    }
                }
            }
        }
    }
    
    // MARK: - Passages Helpers
    
    private func sortedPassages() -> [PassageEntity] {
        guard let passagesSet = prayer.passage as? Set<PassageEntity> else {
            return []
        }
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
        newPassage.prayer = prayer  // Link to parent prayer

        prayer.lastModifiedDate = Date()
        
        saveContext()
        
        // Optionally focus the new passage right away
        focusedPassageID = newPassage.objectID
    }
    
    private func currentFocusedPassage() -> PassageEntity? {
        guard let focusedID = focusedPassageID else { return nil }
        
        let passagesArray = sortedPassages()
        return passagesArray.first(where: { $0.objectID == focusedID })
    }
    
    private func deletePassage(_ passage: PassageEntity) {
        viewContext.delete(passage)
        focusedPassageID = nil  // Clear focus so we hide the delete button

        prayer.lastModifiedDate = Date()
        
        saveContext()
    }
    
    // MARK: - Requests Helpers
    
    private func sortedRequests() -> [RequestEntity] {
        guard let requestsSet = prayer.requests as? Set<RequestEntity> else {
            return []
        }
        return requestsSet.sorted {
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
        
        // Focus the new request after creation
        focusedRequestID = newRequest.objectID
    }
    
    private func currentFocusedRequest() -> RequestEntity? {
        guard let focusedID = focusedRequestID else { return nil }
        
        let requestsArray = sortedRequests()
        return requestsArray.first(where: { $0.objectID == focusedID })
    }
    
    private func deleteRequest(_ request: RequestEntity) {
        viewContext.delete(request)
        focusedRequestID = nil  // Clear focus so we hide the delete button

        prayer.lastModifiedDate = Date()
        
        saveContext()
    }
    
    // MARK: - Core Data Save

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

