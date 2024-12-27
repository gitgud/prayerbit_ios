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
            // The Delete button should appear if we currently have a focused request
            if let currentRequest = currentFocusedRequest() {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete") {
                        deleteRequest(currentRequest)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
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
        
        // Save so it appears in the list
        saveContext()
        
        // Focus the new request after creation (if desired):
        focusedRequestID = newRequest.objectID
    }
    
    /// Identify the RequestEntity that is currently focused, if any
    private func currentFocusedRequest() -> RequestEntity? {
        guard let focusedID = focusedRequestID else { return nil }
        
        // Look up which request has that objectID
        let requestsArray = sortedRequests()
        return requestsArray.first(where: { $0.objectID == focusedID })
    }
    
    private func deleteRequest(_ request: RequestEntity) {
        // Delete the request from the context
        viewContext.delete(request)
        
        // Clear focus so we don't show the delete button
        focusedRequestID = nil
        
        // Update the parent prayer so SwiftUI sees a change
        prayer.lastModifiedDate = Date()
        
        saveContext()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
