//
//  PrayerEditView.swift
//  test2
//
//  Created by kale on 12/25/24.
//

import SwiftUI
import CoreData


struct PrayerEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode

    @ObservedObject var prayer: PrayerEntity

    // Local state for the prayer title (so that we can discard changes if needed)
    @State private var localTitle: String = ""

    // Because requests is an NSSet, we typically convert it to an Array/Set for iteration.
    // We'll track the text for each request in a dictionary, keyed by the request's objectID.
    @State private var requestTexts: [NSManagedObjectID: String] = [:]

    var body: some View {
        Form {
            // MARK: Prayer Section
            Section(header: Text("Prayer")) {
                TextField("Title", text: $localTitle)
            }

            // MARK: Requests Section
            Section(header: Text("Requests")) {
                // List existing requests
                let requestsArray = sortedRequests()
                ForEach(requestsArray, id: \.objectID) { request in
                    // We'll bind each request to a text field.
                    TextField("Request",
                              text: Binding(
                                get: { requestTexts[request.objectID] ?? (request.request ?? "") },
                                set: { newValue in
                                    requestTexts[request.objectID] = newValue
                                }
                              )
                    )
                }

                // Button to add a new request in-line
                Button(action: addNewRequest) {
                    Label("Add Request", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle("Edit Prayer")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
            }
        }
        .onAppear {
            // Initialize localTitle and requestTexts from the existing data
            localTitle = prayer.title ?? ""
            initRequestTexts()
        }
    }

    // MARK: - Helper Methods

    /// Sort the prayer's requests by creationDate (ascending)
    private func sortedRequests() -> [RequestEntity] {
        guard let requestsSet = prayer.requests as? Set<RequestEntity> else {
            return []
        }

        return requestsSet.sorted {
            ($0.creationDate ?? Date()) < ($1.creationDate ?? Date())
        }
    }

    /// Initialize requestTexts for each existing request
    private func initRequestTexts() {
        for request in sortedRequests() {
            requestTexts[request.objectID] = request.request ?? ""
        }
    }

    /// Adds a new request object to the prayer
    private func addNewRequest() {
        let newRequest = RequestEntity(context: viewContext)
        newRequest.id = UUID()
        newRequest.request = ""
        newRequest.creationDate = Date()
        newRequest.lastModifiedDate = Date()
        // Link it to this prayer
        newRequest.prayer = prayer
        
        // Also initialize its text in requestTexts
        requestTexts[newRequest.objectID] = ""
    }

    /// Save all changes for both the prayer and its requests
    private func saveChanges() {
        // 1) Update the prayer fields
        prayer.title = localTitle
        prayer.lastModifiedDate = Date()

        // 2) Update each request's text
        for request in sortedRequests() {
            let text = requestTexts[request.objectID] ?? ""
            request.request = text
            request.lastModifiedDate = Date()
        }

        // 3) Attempt to save the context
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
}

struct PrayerEditView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Create a sample prayer
        let samplePrayer = PrayerEntity(context: context)
        samplePrayer.id = UUID()
        samplePrayer.title = "Sample Prayer"
        samplePrayer.creationDate = Date()

        // Create a couple of sample requests
        for i in 1...2 {
            let req = RequestEntity(context: context)
            req.id = UUID()
            req.request = "Sample Request #\(i)"
            req.creationDate = Date().addingTimeInterval(-Double(i)*3600)
            req.lastModifiedDate = Date()
            req.prayer = samplePrayer
        }

        return NavigationView {
            PrayerEditView(prayer: samplePrayer)
                .environment(\.managedObjectContext, context)
        }
    }
}
