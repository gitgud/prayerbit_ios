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
    
    var body: some View {
        Form {
            // MARK: - Prayer Section
            Section(header: Text("Prayer")) {
                TextField("Title",
                    text: Binding(
                        get: { prayer.title ?? "" },
                        set: { newValue in
                            prayer.title = newValue
                            prayer.lastModifiedDate = Date()
                            saveContext()
                        }
                    )
                )
            }
            
            // MARK: - Requests Section
            Section(header: Text("Requests")) {
                // Show each RequestEntity in a text field
                let requestsArray = sortedRequests()
                ForEach(requestsArray, id: \.objectID) { request in
                    TextField("Request",
                        text: Binding(
                            get: { request.request ?? "" },
                            set: { newValue in
                                request.request = newValue
                                request.lastModifiedDate = Date()
                                prayer.lastModifiedDate = Date()
                                prayer.objectWillChange.send()
                                request.objectWillChange.send()
                                saveContext()
           
                            }
                        )
                    )
                }
                
                // Add Request inline
                Button(action: addNewRequest) {
                    Label("Add Request", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Edit Prayer")
    }
    
    // MARK: - Helpers
    
    private func sortedRequests() -> [RequestEntity] {
        guard let requestsSet = prayer.requests as? Set<RequestEntity> else {
            return []
        }
        return requestsSet.sorted { ($0.creationDate ?? Date()) < ($1.creationDate ?? Date()) }
    }
    
    private func addNewRequest() {
        let newRequest = RequestEntity(context: viewContext)
        newRequest.id = UUID()
        // Set a placeholder so it’s not blank
        newRequest.request = "New Request"
        newRequest.creationDate = Date()
        newRequest.lastModifiedDate = Date()
        newRequest.prayer = prayer
        
        // Update parent’s lastModifiedDate
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
