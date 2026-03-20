import Foundation
import CoreData

extension UserStats {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserStats> {
        return NSFetchRequest<UserStats>(entityName: "UserStats")
    }

    @NSManaged public var id: UUID
    @NSManaged public var currentStreak: Int32
    @NSManaged public var longestStreak: Int32
    @NSManaged public var lastWorkoutDate: Date?
    @NSManaged public var weightUnit: String
}

extension UserStats: Identifiable {}
