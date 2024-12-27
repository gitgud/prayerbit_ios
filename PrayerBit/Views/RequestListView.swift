//
//  RequestListView.swift
//  PrayerBit
//
//  Created by kale on 12/24/24.
//


import SwiftUI
import CoreData

struct RequestListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \RequestEntity.creationDate, ascending: false)],
        animation: .default
    )
    private var requests: FetchedResults<RequestEntity>

    var body: some View {
        NavigationView {
            List {
                ForEach(requests, id: \.self) { request in
                    NavigationLink(destination: RequestDetailView(request: request)) {
                        Text(request.request ?? "Untitled Request")

                    }
                }
            }
        }
    }
}

struct RequestListView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Insert test data
        for i in 1...3 {
            let newRequest = RequestEntity(context: context)
            newRequest.id = UUID()
            newRequest.request = "Request #\(i)"
            newRequest.creationDate = Date().addingTimeInterval(Double(-i) * 86400)
            newRequest.lastModifiedDate = Date()
        }

        return RequestListView()
            .environment(\.managedObjectContext, context)
    }
}
