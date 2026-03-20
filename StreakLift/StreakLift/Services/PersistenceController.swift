import CoreData

struct PersistenceController {

    // MARK: - Singleton
    static let shared = PersistenceController()

    // MARK: - Preview
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        // Seed preview data
        CoreDataManager(context: viewContext).seedPresetExercisesIfNeeded()
        return controller
    }()

    // MARK: - Container
    let container: NSPersistentContainer

    // MARK: - Init
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "StreakLift")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("CoreData persistent store failed to load: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save
    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("CoreData save error: \(nsError), \(nsError.userInfo)")
        }
    }

    // MARK: - Background Context
    func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
}
