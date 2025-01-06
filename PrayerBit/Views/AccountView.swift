//
//  AccountView.swift
//  PrayerBit
//
//  Created by kale on 1/6/25.
//

import SwiftUI
import CoreData

struct AccountView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Fetch all PrayerEntity objects (or you can fetch only the ones you need).
    @FetchRequest(
        entity: PrayerEntity.entity(),
        sortDescriptors: [] // Provide sort descriptors if desired
    ) private var prayers: FetchedResults<PrayerEntity>
    
    // State variables to control the share sheet
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export your data to JSON")
                .font(.headline)
            
            // Replace the old "Export" text button with a share icon button
            Button(action: exportToJson) {
                Image(systemName: "square.and.arrow.up")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            .padding()
        }
        .padding()
        
        // Present a share sheet (using a wrapper) when showShareSheet is true
        .sheet(isPresented: $showShareSheet) {
            ActivityViewControllerWrapper(activityItems: shareItems)
        }
    }
    
    /// Gathers all `PrayerEntity` data, encodes to JSON, writes to a temp file, then triggers share sheet.
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
