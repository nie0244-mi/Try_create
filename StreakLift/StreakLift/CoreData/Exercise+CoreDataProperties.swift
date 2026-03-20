import Foundation
import CoreData

extension Exercise {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Exercise> {
        return NSFetchRequest<Exercise>(entityName: "Exercise")
    }

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var bodyPart: String
    @NSManaged public var isCustom: Bool
    @NSManaged public var isDeleted: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var sets: NSSet?
}

// MARK: Generated accessors for sets
extension Exercise {

    @objc(addSetsObject:)
    @NSManaged public func addToSets(_ value: WorkoutSet)

    @objc(removeSetsObject:)
    @NSManaged public func removeFromSets(_ value: WorkoutSet)

    @objc(addSets:)
    @NSManaged public func addToSets(_ values: NSSet)

    @objc(removeSets:)
    @NSManaged public func removeFromSets(_ values: NSSet)
}

extension Exercise: Identifiable {}
