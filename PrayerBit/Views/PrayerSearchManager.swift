//
//  PrayerSearchManager.swift
//  PrayerBit
//
//  Created by kale on 12/29/24.
//


import SwiftUI
import CoreData

class PrayerSearchManager: ObservableObject {
    @Published var searchText: String = ""
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    /// Returns prayers in the following priority:
    /// 1) Prayers whose tags match searchText
    /// 2) Prayers whose title matches
    /// 3) Prayers whose requests match
    /// Duplicates removed, so each prayer appears once in final array.
    func searchPrayers() -> [PrayerEntity] {
        // If search text is empty, just fetch all prayers (or return empty to show them all differently).
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return fetchAllPrayers()
        }
        
        var results = [PrayerEntity]()
        var seen = Set<NSManagedObjectID>()  // track IDs to remove duplicates
        
        // 1) Tag matches
        let tagMatches = fetchPrayersMatchingTag(searchText)
        for prayer in tagMatches {
            if !seen.contains(prayer.objectID) {
                results.append(prayer)
                seen.insert(prayer.objectID)
            }
        }
        
        // 2) Title matches
        let titleMatches = fetchPrayersMatchingTitle(searchText)
        for prayer in titleMatches {
            if !seen.contains(prayer.objectID) {
                results.append(prayer)
                seen.insert(prayer.objectID)
            }
        }
        
        // 3) Requests match
        let requestMatches = fetchPrayersMatchingRequest(searchText)
        for prayer in requestMatches {
            if !seen.contains(prayer.objectID) {
                results.append(prayer)
                seen.insert(prayer.objectID)
            }
        }
        
        return results
    }
    
    // MARK: - Private Helper Fetches
    
    private func fetchAllPrayers() -> [PrayerEntity] {
        let request: NSFetchRequest<PrayerEntity> = PrayerEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastModifiedDate", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching all prayers: \(error)")
            return []
        }
    }
    
    /// Fetch prayers whose TAG matches searchText
    private func fetchPrayersMatchingTag(_ text: String) -> [PrayerEntity] {
        // For many-to-many, we test if ANY TagEntity has `tag CONTAINS[c] text`
        // That means:  ANY tags.tag CONTAINS[c] text
        let request: NSFetchRequest<PrayerEntity> = PrayerEntity.fetchRequest()
        let predicate = NSPredicate(format: "ANY tags.tag CONTAINS[c] %@", text)
        request.predicate = predicate
        request.sortDescriptors = []
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching prayers by tag: \(error)")
            return []
        }
    }
    
    /// Fetch prayers whose TITLE matches searchText
    private func fetchPrayersMatchingTitle(_ text: String) -> [PrayerEntity] {
        let request: NSFetchRequest<PrayerEntity> = PrayerEntity.fetchRequest()
        let predicate = NSPredicate(format: "title CONTAINS[c] %@", text)
        request.predicate = predicate
        request.sortDescriptors = []
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching prayers by title: \(error)")
            return []
        }
    }
    
    /// Fetch prayers whose REQUESTS match searchText
    private func fetchPrayersMatchingRequest(_ text: String) -> [PrayerEntity] {
        // For one-to-many requests, we do: ANY requests.request CONTAINS[c] text
        let request: NSFetchRequest<PrayerEntity> = PrayerEntity.fetchRequest()
        let predicate = NSPredicate(format: "ANY requests.request CONTAINS[c] %@", text)
        request.predicate = predicate
        request.sortDescriptors = []
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching prayers by request: \(error)")
            return []
        }
    }
}