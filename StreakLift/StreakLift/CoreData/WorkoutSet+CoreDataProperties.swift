import Foundation
import CoreData

extension WorkoutSet {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutSet> {
        return NSFetchRequest<WorkoutSet>(entityName: "WorkoutSet")
    }

    @NSManaged public var id: UUID
    @NSManaged public var weightKg: Double
    @NSManaged public var reps: Int32
    @NSManaged public var setOrder: Int32
    @NSManaged public var note: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var exercise: Exercise?
    @NSManaged public var session: WorkoutSession?
}

extension WorkoutSet: Identifiable {}
