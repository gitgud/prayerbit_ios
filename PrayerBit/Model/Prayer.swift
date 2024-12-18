//
//  Prayer.swift
//  yolo
//
//  Created by kale on 12/13/24.
//

import Foundation

struct Prayer: Hashable, Codable, Identifiable {
    var id: String
    var name: String
    var description: String
    var status: Status
    
    enum Status: String, CaseIterable, Codable {
        case answered = "Answered"
        case denied = "Denied"
        case inProgress = "In Progress"
        var id: String { rawValue }
    }
    
    static let `default` = Prayer(id: NSUUID().uuidString.lowercased(), name: "test name", description: "test description", status: Status.answered)
    
}
