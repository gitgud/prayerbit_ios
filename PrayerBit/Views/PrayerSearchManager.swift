//
//  PrayerSearchManager.swift
//  PrayerBit
//
//  Created by kale on 12/25/24.
//
import SwiftUI
import CoreData

class PrayerSearchManager: ObservableObject {
    @Published var searchText: String = "" {
        didSet {
            refresh()
        }
    }
    
    @Published private(set) var filteredPrayers: [PrayerEntity] = []
    
    private var context: NSManagedObjectContext?
    
    func setContext(_ ctx: NSManagedObjectContext) {
        self.context = ctx
        refresh()
    }
    
    func refresh() {
        guard let ctx = context else {
            filteredPrayers = []
            return
        }
        
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If no search text, fetch all:
        if trimmed.isEmpty {
            filteredPrayers = fetchAllPrayers(in: ctx)
            return
        }
        
        // Otherwise, combine 3 sets of matches (tags, title, requests)
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
        
        filteredPrayers = results
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
    
    private func fetchPrayersMatchingTag(_ text: String, in context: NSManagedObjectContext) -> [PrayerEntity] {
        // This STILL works for a to-many "tags" relationship from Prayer to Tag
        let request: NSFetchRequest<PrayerEntity> = PrayerEntity.fetchRequest()
        request.predicate = NSPredicate(format: "ANY tags.tag CONTAINS[c] %@", text)
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching by tag: \(error)")
            return []
        }
    }
    
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
