//
//  PrayerSearchManager.swift
//  PrayerBit
//
//  Created by kale on 12/25/24.
//

import SwiftUI
import CoreData

class PrayerSearchManager: ObservableObject {
    /// The text the user enters into the search bar.
    /// Whenever this text changes, we call `refresh()` to update `filteredPrayers`.
    @Published var searchText: String = "" {
        didSet {
            refresh()
        }
    }
    
    /// The array of prayers currently matching the search text (or all prayers if empty).
    @Published private(set) var filteredPrayers: [PrayerEntity] = []
    
    private var context: NSManagedObjectContext?
    
    /// Called from the outside (e.g. in PrayerListView.onAppear)
    /// to assign a Core Data context and immediately load data.
    func setContext(_ ctx: NSManagedObjectContext) {
        self.context = ctx
        refresh()
    }
    
    /// Fetches from Core Data and updates `filteredPrayers` based on the current `searchText`.
    func refresh() {
        guard let ctx = context else {
            filteredPrayers = []
            return
        }
        
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If no search text, just fetch all prayers:
        if trimmed.isEmpty {
            filteredPrayers = fetchAllPrayers(in: ctx)
            return
        }
        
        // Otherwise, we combine 3 sets of matches (tags, title, requests),
        // then remove duplicates
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
