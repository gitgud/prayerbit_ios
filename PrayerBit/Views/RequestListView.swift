//
//  RequestListView.swift
//  PrayerBit
//
//  Created by kale on 12/24/24.
//


import SwiftUI
import CoreData


struct RequestListView: View {
    // The parent prayer for which we want to show requests
    var prayer: PrayerEntity

    // A fetch request specifically for RequestEntity, filtered by the parent
    @FetchRequest private var requests: FetchedResults<RequestEntity>

    // Custom initializer to set up the fetch request with a predicate
    init(prayer: PrayerEntity) {
        // This predicate means: "fetch all RequestEntity where prayer == this specific PrayerEntity"
        let predicate = NSPredicate(format: "prayer == %@", prayer)

        // Sort by lastModifiedDate descending, or creationDate ascending—your choice
        _requests = FetchRequest<RequestEntity>(
            sortDescriptors: [NSSortDescriptor(keyPath: \RequestEntity.lastModifiedDate, ascending: false)],
            predicate: predicate,
            animation: .default
        )

        self.prayer = prayer
    }

    var body: some View {
        List {
            ForEach(requests, id: \.self) { request in
                // Show each request’s text, or a textfield if we want inline editing
                Text(request.request ?? "Untitled Request")
            }
        }
        .navigationTitle("Requests for \(prayer.title ?? "")")
    }
}


