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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prayer Title: \(prayer.title ?? "Untitled")")
                .font(.headline)
            
            /*
            if let creationDate = prayer.creationDate {
                Text("Created: \(creationDate, style: .date)")
            }
             */
            
            if let lastModifiedDate = prayer.lastModifiedDate {
                Text("Last Modified: \(lastModifiedDate, style: .date)")
                
            }
            
            
            Divider()
            
            Text("Requests for this Prayer:")
                .font(.subheadline)
             
            // Because prayer.requests is an NSSet or optional, we need to typecast and perhaps sort it.
            if let requestsSet = prayer.requests as? Set<RequestEntity> {
                // You might want a custom sort by creationDate:
                let requestsArray = requestsSet.sorted {
                    ($0.lastModifiedDate ?? Date()) < ($1.lastModifiedDate ?? Date())
                }
                
                ForEach(requestsArray, id: \.self) { request in
                    Text(request.request ?? "Untitled Request")
                }
            } else {
                Text("No requests yet.")
                    .foregroundColor(.secondary)
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
