//
//  PrayerCreateView.swift
//  test2
//
//  Created by kale on 12/25/24.
//


import SwiftUI
import CoreData

struct PrayerCreateView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var newTitle: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("New Prayer Title")) {
                TextField("Title", text: $newTitle)
            }
        }
        .navigationTitle("Create a Prayer")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    createPrayer()
                }
            }
        }
    }
    
    private func createPrayer() {
        let prayer = PrayerEntity(context: viewContext)
        prayer.id = UUID()
        prayer.title = newTitle
        prayer.creationDate = Date()
        prayer.lastModifiedDate = Date()
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to create prayer: \(error)")
        }
    }
}

struct PrayerCreateView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        return NavigationView {
            PrayerCreateView()
                .environment(\.managedObjectContext, context)
        }
    }
}