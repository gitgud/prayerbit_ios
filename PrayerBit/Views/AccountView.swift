//
//  AccountView.swift
//  PrayerBit
//
//  Created by kale on 1/6/25.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct AccountView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Fetch all PrayerEntity objects
    @FetchRequest(
        entity: PrayerEntity.entity(),
        sortDescriptors: []
    ) private var prayers: FetchedResults<PrayerEntity>
    
    // MARK: - State for export
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    
    // MARK: - State for import
    @State private var showFileImporter = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export / Import your Prayer Data (JSON)")
                .font(.headline)
            
            // Export to JSON
            Button(action: exportToJson) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export")
                }
                .font(.title3)
                .foregroundColor(.blue)
            }
            .padding()
            
            // Import from JSON
            Button(action: { showFileImporter = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import")
                }
                .font(.title3)
                .foregroundColor(.blue)
            }
            .padding()
            // SwiftUI’s FileImporter
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        // 1) Access security scope
                        if url.startAccessingSecurityScopedResource() {
                            defer { url.stopAccessingSecurityScopedResource() }
                            
                            // 2) Copy the file to the app’s Documents directory if you want a permanent copy
                            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                            let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)
                            
                            do {
                                let data = try Data(contentsOf: url)
                                try data.write(to: destinationURL, options: .atomic)
                                
                                // Now import from the local copy
                                importFromJson(fileURL: destinationURL)
                            } catch {
                                print("Error copying or importing file: \(error)")
                            }
                        } else {
                            print("Could not access the file’s security-scoped resource.")
                        }
                    }
                case .failure(let error):
                    print("FileImporter error: \(error)")
                }
            }
            
            // Delete all data in Core Data
            Button("Delete Data") {
                deleteAllData()
            }
            .font(.title3)
            .foregroundColor(.red)
            .padding()
        }
        // Add bottom toolbar with two placeholder buttons
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button("Search") {
                    // TODO: Implement search action
                    print("Search tapped")
                }
                
                Spacer()
                
                Button("Account") {
                    // TODO: Implement account action
                    print("Account tapped")
                }
            }
        }
        // Present a share sheet (using a wrapper) when showShareSheet is true
        .sheet(isPresented: $showShareSheet) {
            ActivityViewControllerWrapper(activityItems: shareItems)
        }
    }
    
    // MARK: - Export
    
    /// Gathers all PrayerEntity data, encodes to JSON, writes to a temp file, then triggers share sheet.
    private func exportToJson() {
        // 1) Convert all fetched objects to export structs
        let prayerExportList = prayers.map { $0.toExportStruct() }
        
        // 2) Encode them to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let data = try encoder.encode(prayerExportList)
            
            // 3) Write to a temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("ExportedPrayers.json")
            try data.write(to: tempURL, options: .atomic)
            
            // 4) Share the file
            shareItems = [tempURL]
            showShareSheet = true
            
        } catch {
            print("Error encoding or writing JSON: \(error)")
        }
    }
    
    // MARK: - Import
    
    /// Reads JSON from the provided file URL, decodes, and inserts into Core Data.
    private func importFromJson(fileURL: URL) {
        do {
            let data = try Data(contentsOf: fileURL)
            
            // Decode into array of PrayerExport
            let importedPrayers = try JSONDecoder().decode([PrayerExport].self, from: data)
            
            for prayerExport in importedPrayers {
                // Create a new PrayerEntity
                let newPrayer = PrayerEntity(context: viewContext)
                newPrayer.id = prayerExport.id
                newPrayer.title = prayerExport.title
                newPrayer.creationDate = prayerExport.creationDate
                newPrayer.lastModifiedDate = prayerExport.lastModifiedDate
                
                // Passages
                for passageExport in prayerExport.passages {
                    let newPassage = PassageEntity(context: viewContext)
                    newPassage.id = passageExport.id
                    newPassage.passage = passageExport.passage
                    newPassage.creationDate = passageExport.creationDate
                    newPassage.lastModifiedDate = passageExport.lastModifiedDate
                    newPassage.prayer = newPrayer
                }
                
                // Requests
                for requestExport in prayerExport.requests {
                    let newRequest = RequestEntity(context: viewContext)
                    newRequest.id = requestExport.id
                    newRequest.request = requestExport.request
                    newRequest.status = requestExport.status ?? ""
                    newRequest.creationDate = requestExport.creationDate
                    newRequest.lastModifiedDate = requestExport.lastModifiedDate
                    newRequest.prayer = newPrayer
                }
                
                // Tags
                for tagExport in prayerExport.tags {
                    let newTag = TagEntity(context: viewContext)
                    newTag.id = tagExport.id
                    newTag.tag = tagExport.tag
                    newTag.order = tagExport.order
                    newTag.lastModifiedDate = tagExport.lastModifiedDate
                    newTag.prayer = newPrayer
                }
            }
            
            // Save context
            try viewContext.save()
            print("Import Success: \(importedPrayers.count) prayers imported.")
            
        } catch {
            print("JSON import failed: \(error)")
        }
    }
    
    // MARK: - Delete All Data
    
    /// Deletes all data by performing a typed fetch for each entity and deleting fetched objects.
    private func deleteAllData() {
        do {
            // PrayerEntity
            let prayerFetch: NSFetchRequest<PrayerEntity> = PrayerEntity.fetchRequest()
            let prayerObjects = try viewContext.fetch(prayerFetch)
            prayerObjects.forEach { viewContext.delete($0) }
            
            // PassageEntity
            let passageFetch: NSFetchRequest<PassageEntity> = PassageEntity.fetchRequest()
            let passageObjects = try viewContext.fetch(passageFetch)
            passageObjects.forEach { viewContext.delete($0) }
            
            // RequestEntity
            let requestFetch: NSFetchRequest<RequestEntity> = RequestEntity.fetchRequest()
            let requestObjects = try viewContext.fetch(requestFetch)
            requestObjects.forEach { viewContext.delete($0) }
            
            // TagEntity
            let tagFetch: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            let tagObjects = try viewContext.fetch(tagFetch)
            tagObjects.forEach { viewContext.delete($0) }
            
            // Save context
            try viewContext.save()
            print("All data has been deleted.")
        } catch {
            print("Failed to delete data: \(error)")
        }
    }
}

// MARK: - ActivityViewControllerWrapper

/// A simple `UIViewControllerRepresentable` that wraps `UIActivityViewController`.
/// This is used to present a share sheet from SwiftUI.
struct ActivityViewControllerWrapper: UIViewControllerRepresentable {
    
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // no-op
    }
}
