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
    
    init(prayer: PrayerEntity) {
        self.prayer = prayer
        
        // Build a predicate to filter RequestEntities that belong to this specific PrayerEntity
        let predicate = NSPredicate(format: "prayer == %@", prayer)
        
        // You can customize the sort order here (e.g., by creationDate)
        _requests = FetchRequest<RequestEntity>(
            sortDescriptors: [NSSortDescriptor(keyPath: \RequestEntity.creationDate, ascending: false)],
            predicate: predicate,
            animation: .default
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prayer Title: \(prayer.title ?? "Untitled")")
                .font(.headline)
            
            Divider()
            
            Text("Requests for this Prayer:")
                .font(.subheadline)
            
            if requests.isEmpty {
                Text("No requests yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(requests, id: \.self) { request in
                    Text(request.request ?? "Untitled Request")
                }
            }
        }
        .padding()
        .navigationTitle("Prayer Details")
    }
}

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
        
        // Create a few related RequestEntities
        for i in 1...3 {
            let newRequest = RequestEntity(context: context)
            newRequest.id = UUID()
            newRequest.request = "Request #\(i)"
            newRequest.creationDate = Date().addingTimeInterval(Double(-i) * 3600)
            newRequest.lastModifiedDate = Date()
            
            // Link the request to the samplePrayer
            newRequest.prayer = samplePrayer
        }
        
        return NavigationView {
            PrayerDetailView(prayer: samplePrayer)
                .environment(\.managedObjectContext, context)
        }
    }
}
