import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "EffectModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load Core Data store: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    // MARK: - Effect Caching
    
    func cacheEffect(_ effect: Effect, videoData: Data) {
        let fetchRequest: NSFetchRequest<CachedEffect> = CachedEffect.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", effect.id)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let existingEffect = results.first {
                existingEffect.videoData = videoData
                existingEffect.lastAccessed = Date()
            } else {
                let cachedEffect = CachedEffect(context: context)
                cachedEffect.id = Int64(effect.id)
                cachedEffect.title = effect.title
                cachedEffect.preview = effect.preview
                cachedEffect.videoData = videoData
                cachedEffect.lastAccessed = Date()
            }
            saveContext()
        } catch {
            print("Error caching effect: \(error)")
        }
    }
    
    func getCachedVideoData(for effectId: Int) -> Data? {
        let fetchRequest: NSFetchRequest<CachedEffect> = CachedEffect.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", effectId)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let cachedEffect = results.first {
                cachedEffect.lastAccessed = Date()
                saveContext()
                return cachedEffect.videoData
            }
        } catch {
            print("Error fetching cached effect: \(error)")
        }
        return nil
    }
    
    func clearOldCache(olderThan days: Int = 7) {
        let fetchRequest: NSFetchRequest<CachedEffect> = CachedEffect.fetchRequest()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        fetchRequest.predicate = NSPredicate(format: "lastAccessed < %@", cutoffDate as NSDate)
        
        do {
            let results = try context.fetch(fetchRequest)
            for effect in results {
                context.delete(effect)
            }
            saveContext()
        } catch {
            print("Error clearing old cache: \(error)")
        }
    }
} 