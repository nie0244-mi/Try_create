import Foundation
import CoreData

extension Badge {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Badge> {
        return NSFetchRequest<Badge>(entityName: "Badge")
    }

    @NSManaged public var id: UUID
    @NSManaged public var badgeType: String
    @NSManaged public var title: String
    @NSManaged public var unlockedAt: Date?
}

extension Badge: Identifiable {}
