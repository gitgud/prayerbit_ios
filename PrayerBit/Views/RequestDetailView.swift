//
//  RequestDetailView.swift
//  test2
//
//  Created by kale on 12/24/24.
//

import SwiftUI
import CoreData

struct RequestDetailView: View {
    @ObservedObject var request: RequestEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Request")
                .font(.headline)
            
            //Text(request.request ?? "No request text")
            //   .font(.body)
            
            if let creationDate = request.creationDate {
                Text("Created: \(creationDate, style: .date)")
            }
            if let lastModifiedDate = request.lastModifiedDate {
                Text("Last Modified: \(lastModifiedDate, style: .date)")
            }
        }
        .padding()
        .navigationTitle("Request Details")
    }
}

struct RequestDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Mock data
        let sampleRequest = RequestEntity(context: context)
        sampleRequest.id = UUID()
        //sampleRequest.request = "Please pray for my friend."
        sampleRequest.creationDate = Date()
        sampleRequest.lastModifiedDate = Date()

        return NavigationView {
            RequestDetailView(request: sampleRequest)
                .environment(\.managedObjectContext, context)
        }
    }
}
