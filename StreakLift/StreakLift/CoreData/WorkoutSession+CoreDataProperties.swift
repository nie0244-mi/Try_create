import Foundation
import CoreData

extension WorkoutSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutSession> {
        return NSFetchRequest<WorkoutSession>(entityName: "WorkoutSession")
    }

    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var totalVolumeKg: Double
    @NSManaged public var durationMinutes: Int32
    @NSManaged public var note: String?
    @NSManaged public var sets: NSSet?
}

// MARK: Generated accessors for sets
extension WorkoutSession {

    @objc(addSetsObject:)
    @NSManaged public func addToSets(_ value: WorkoutSet)

    @objc(removeSetsObject:)
    @NSManaged public func removeFromSets(_ value: WorkoutSet)

    @objc(addSets:)
    @NSManaged public func addToSets(_ values: NSSet)

    @objc(removeSets:)
    @NSManaged public func removeFromSets(_ values: NSSet)
}

extension WorkoutSession: Identifiable {}
