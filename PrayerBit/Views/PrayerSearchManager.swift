//
//  PrayerSearchManager.swift
//  PrayerBit
//
//  Created by kale on 12/25/24.
//

import SwiftUI
import CoreData

class PrayerSearchManager: ObservableObject {
    @Published var searchText: String = ""
    
    private var context: NSManagedObjectContext?
    
    // We allow passing context in a method, so we can set it later in .onAppear
    func setContext(_ ctx: NSManagedObjectContext) {
        self.context = ctx
    }
    
    /// Returns prayers in the following priority:
    ///  1) Prayers whose tags match searchText
    ///  2) Prayers whose title matches
    ///  3) Prayers whose requests match
    /// Duplicates removed, so each prayer appears once in final array.
    func searchPrayers() -> [PrayerEntity] {
        guard let ctx = context else { return [] }
        
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return fetchAllPrayers(in: ctx)
        }
        
        var results = [PrayerEntity]()
        var seenIDs = Set<NSManagedObjectID>()
        
        // 1) Tag matches
        let tagMatches = fetchPrayersMatchingTag(trimmed, in: ctx)
        for p in tagMatches where !seenIDs.contains(p.objectID) {
            results.append(p)
            seenIDs.insert(p.objectID)
        }
        
        // 2) Title matches
        let titleMatches = fetchPrayersMatchingTitle(trimmed, in: ctx)
        for p in titleMatches where !seenIDs.contains(p.objectID) {
            results.append(p)
            seenIDs.insert(p.objectID)
        }
        
        // 3) Requests match
        let requestMatches = fetchPrayersMatchingRequest(trimmed, in: ctx)
        for p in requestMatches where !seenIDs.contains(p.objectID) {
            results.append(p)
            seenIDs.insert(p.objectID)
        }
        
        return results
    }
    
    // MARK: - Private Helpers
    
    private func fetchAllPrayers(in context: NSManagedObjectContext) -> [PrayerEntity] {
        let request: NSFetchRequest<PrayerEntity> = PrayerEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastModifiedDate", ascending: false)]
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching all prayers: \(error)")
            return []
        }
    }
    
    /// Many-to-many: ANY tags.tag CONTAINS[c] <text>
    private func fetchPrayersMatchingTag(_ text: String, in context: NSManagedObjectContext) -> [PrayerEntity] {
        let request: NSFetchRequest<PrayerEntity> = PrayerEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ANY tags.tag CONTAINS[c] %@", text)
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching by tag: \(error)")
            return []
        }
    }
    
    /// Title CONTAINS[c] <text>
    private func fetchPrayersMatchingTitle(_ text: String, in context: NSManagedObjectContext) -> [PrayerEntity] {
        let request: NSFetchRequest<PrayerEntity> = PrayerEntity.fetchRequest()
        request.predicate = NSPredicate(format: "title CONTAINS[c] %@", text)
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching by title: \(error)")
            return []
        }
    }
    
    /// ANY requests.request CONTAINS[c] <text>
    private func fetchPrayersMatchingRequest(_ text: String, in context: NSManagedObjectContext) -> [PrayerEntity] {
        let request: NSFetchRequest<PrayerEntity> = PrayerEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ANY requests.request CONTAINS[c] %@", text)
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching by request: \(error)")
            return []
        }
    }
}
