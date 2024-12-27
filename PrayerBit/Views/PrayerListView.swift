//
//  PrayerListView.swift
//  test2
//
//  Created by kale on 12/25/24.
//

import SwiftUI
import CoreData

struct PrayerListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PrayerEntity.creationDate, ascending: false)],
        animation: .default
    )
    private var prayers: FetchedResults<PrayerEntity>

    var body: some View {
        NavigationView {
            List {
                ForEach(prayers, id: \.self) { prayer in
                    // Show the PrayerDetailView in each row
                    NavigationLink(destination: PrayerEditView(prayer: prayer)) {
                        PrayerDetailView(prayer: prayer)
                    }
                }
            }
            .navigationTitle("All Prayers")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: PrayerCreateView()) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct PrayerListView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Insert some sample prayers
        for i in 1...10 {
            let newPrayerPreview = PrayerEntity(context: context)
            newPrayerPreview.id = UUID()
            newPrayerPreview.title = "Sample Prayer #\(i)"
            newPrayerPreview.creationDate = Date().addingTimeInterval(Double(-i) * 86400)
            newPrayerPreview.lastModifiedDate = Date()
            
            //"\(String(describing: newPrayer.id))"
            for j in 1...2 {
                let request = RequestEntity(context: context)
                request.id = UUID()
                request.request = "Request #\(j) for Prayer #\(i)"
                request.creationDate = Date().addingTimeInterval(Double(-j) * 3600)
                request.lastModifiedDate = Date()
                request.prayer = newPrayerPreview
            }
        }
        
        

        return PrayerListView()
            .environment(\.managedObjectContext, context)
    }
}
