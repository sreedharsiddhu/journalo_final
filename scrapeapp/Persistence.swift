import CoreData
import SwiftUI

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "scrapeapp1")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for the ContentView preview
        for i in 0..<3 {
            let newScrapbook = Scrapbook(context: viewContext)
            newScrapbook.title = "Sample \(i+1)"
            newScrapbook.creationDate = Date().addingTimeInterval(TimeInterval(-i * 86400))
            newScrapbook.pageStyle = "Lined"
            newScrapbook.coverImageData = UIImage(named: "Book Cover 1")?.jpegData(compressionQuality: 0.8)
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
}
