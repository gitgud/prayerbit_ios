//
//  ExportData.swift
//  PrayerBit
//
//  Created by kale on 1/6/25.
//

import Foundation
import CoreData

// MARK: - Codable structs for JSON export

/// The structure representing a prayer when exporting to JSON.
struct PrayerExport: Codable {
    let id: UUID?
    let title: String?
    let creationDate: Date?
    let lastModifiedDate: Date?
    
    // Child relationships
    let passages: [PassageExport]
    let requests: [RequestExport]
    let tags: [TagExport]
}

struct PassageExport: Codable {
    let id: UUID?
    let passage: String?
    let creationDate: Date?
    let lastModifiedDate: Date?
}

struct RequestExport: Codable {
    let id: UUID
    let request: String?
    let status: String?
    let creationDate: Date?
    let lastModifiedDate: Date?
}

struct TagExport: Codable {
    let id: UUID?
    let tag: String?
    let order: Int16
    let lastModifiedDate: Date?
}

// MARK: - Converting from Core Data objects to Export structs

extension PrayerEntity {
    /// Converts a `PrayerEntity` into its exportable `PrayerExport` struct.
    func toExportStruct() -> PrayerExport {
        // Convert to [PassageExport]
        let passageExports = (passage?.allObjects as? [PassageEntity])?
            .map { $0.toExportStruct() } ?? []
        
        // Convert to [RequestExport]
        let requestExports = (requests?.allObjects as? [RequestEntity])?
            .map { $0.toExportStruct() } ?? []
        
        // Convert to [TagExport]
        let tagExports = (tags?.allObjects as? [TagEntity])?
            .map { $0.toExportStruct() } ?? []
        
        return PrayerExport(
            id: id,
            title: title,
            creationDate: creationDate,
            lastModifiedDate: lastModifiedDate,
            passages: passageExports,
            requests: requestExports,
            tags: tagExports
        )
    }
}

extension PassageEntity {
    func toExportStruct() -> PassageExport {
        PassageExport(
            id: id,
            passage: passage,
            creationDate: creationDate,
            lastModifiedDate: lastModifiedDate
        )
    }
}

extension RequestEntity {
    func toExportStruct() -> RequestExport {
        // If `id` is non-optional in Core Data, you can directly use `id`.
        // If it's optional, unwrap or provide a default:
        RequestExport(
            id: id ?? UUID(),
            request: request,
            status: status,
            creationDate: creationDate,
            lastModifiedDate: lastModifiedDate
        )
    }
}

extension TagEntity {
    func toExportStruct() -> TagExport {
        TagExport(
            id: id,
            tag: tag,
            order: order,
            lastModifiedDate: lastModifiedDate
        )
    }
}
