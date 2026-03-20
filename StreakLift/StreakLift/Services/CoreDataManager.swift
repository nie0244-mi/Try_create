import CoreData
import Foundation

// MARK: - Preset Exercise Definition
private struct PresetExercise {
    let name: String
    let bodyPart: String
}

// MARK: - CoreDataManager
final class CoreDataManager {

    // MARK: - Singleton
    static let shared = CoreDataManager(context: PersistenceController.shared.container.viewContext)

    // MARK: - Context
    private let context: NSManagedObjectContext

    // MARK: - Init
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Save
    func save() throws {
        guard context.hasChanges else { return }
        try context.save()
    }

    // =========================================================
    // MARK: - Exercise CRUD
    // =========================================================

    func fetchAllExercises(includeDeleted: Bool = false) throws -> [Exercise] {
        let request = Exercise.fetchRequest()
        if !includeDeleted {
            request.predicate = NSPredicate(format: "isDeleted == NO")
        }
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Exercise.bodyPart, ascending: true),
            NSSortDescriptor(keyPath: \Exercise.name, ascending: true)
        ]
        return try context.fetch(request)
    }

    func fetchExercises(for bodyPart: String) throws -> [Exercise] {
        let request = Exercise.fetchRequest()
        request.predicate = NSPredicate(format: "isDeleted == NO AND bodyPart == %@", bodyPart)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Exercise.name, ascending: true)]
        return try context.fetch(request)
    }

    @discardableResult
    func createExercise(name: String, bodyPart: String) throws -> Exercise {
        let exercise = Exercise(context: context)
        exercise.id = UUID()
        exercise.name = name
        exercise.bodyPart = bodyPart
        exercise.isCustom = true
        exercise.isDeleted = false
        exercise.createdAt = Date()
        try save()
        return exercise
    }

    func updateExercise(_ exercise: Exercise, name: String? = nil, bodyPart: String? = nil) throws {
        if let name { exercise.name = name }
        if let bodyPart { exercise.bodyPart = bodyPart }
        try save()
    }

    func softDeleteExercise(_ exercise: Exercise) throws {
        exercise.isDeleted = true
        try save()
    }

    // =========================================================
    // MARK: - WorkoutSession CRUD
    // =========================================================

    func fetchAllSessions() throws -> [WorkoutSession] {
        let request = WorkoutSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSession.date, ascending: false)]
        return try context.fetch(request)
    }

    func fetchSession(for date: Date) throws -> WorkoutSession? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }

        let request = WorkoutSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func fetchRecentSessions(limit: Int = 30) throws -> [WorkoutSession] {
        let request = WorkoutSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSession.date, ascending: false)]
        request.fetchLimit = limit
        return try context.fetch(request)
    }

    @discardableResult
    func createSession(date: Date = Date(), note: String? = nil) throws -> WorkoutSession {
        let session = WorkoutSession(context: context)
        session.id = UUID()
        session.date = Calendar.current.startOfDay(for: date)
        session.totalVolumeKg = 0
        session.durationMinutes = 0
        session.note = note
        try save()
        return session
    }

    func updateSession(_ session: WorkoutSession, durationMinutes: Int32? = nil, note: String? = nil) throws {
        if let durationMinutes { session.durationMinutes = durationMinutes }
        if let note { session.note = note }
        recalculateTotalVolume(for: session)
        try save()
    }

    func deleteSession(_ session: WorkoutSession) throws {
        context.delete(session)
        try save()
    }

    private func recalculateTotalVolume(for session: WorkoutSession) {
        let sets = (session.sets as? Set<WorkoutSet>) ?? []
        session.totalVolumeKg = sets.reduce(0.0) { $0 + ($1.weightKg * Double($1.reps)) }
    }

    // =========================================================
    // MARK: - WorkoutSet CRUD
    // =========================================================

    func fetchSets(for session: WorkoutSession) throws -> [WorkoutSet] {
        let request = WorkoutSet.fetchRequest()
        request.predicate = NSPredicate(format: "session == %@", session)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSet.setOrder, ascending: true)]
        return try context.fetch(request)
    }

    func fetchSets(for exercise: Exercise, in session: WorkoutSession) throws -> [WorkoutSet] {
        let request = WorkoutSet.fetchRequest()
        request.predicate = NSPredicate(format: "session == %@ AND exercise == %@", session, exercise)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSet.setOrder, ascending: true)]
        return try context.fetch(request)
    }

    @discardableResult
    func addSet(
        to session: WorkoutSession,
        exercise: Exercise,
        weightKg: Double,
        reps: Int32,
        setOrder: Int32,
        note: String? = nil
    ) throws -> WorkoutSet {
        let workoutSet = WorkoutSet(context: context)
        workoutSet.id = UUID()
        workoutSet.weightKg = weightKg
        workoutSet.reps = reps
        workoutSet.setOrder = setOrder
        workoutSet.note = note
        workoutSet.createdAt = Date()
        workoutSet.session = session
        workoutSet.exercise = exercise

        recalculateTotalVolume(for: session)
        try save()
        return workoutSet
    }

    func updateSet(_ set: WorkoutSet, weightKg: Double? = nil, reps: Int32? = nil, note: String? = nil) throws {
        if let weightKg { set.weightKg = weightKg }
        if let reps { set.reps = reps }
        if let note { set.note = note }
        if let session = set.session {
            recalculateTotalVolume(for: session)
        }
        try save()
    }

    func deleteSet(_ set: WorkoutSet) throws {
        let session = set.session
        context.delete(set)
        if let session {
            recalculateTotalVolume(for: session)
        }
        try save()
    }

    // =========================================================
    // MARK: - Badge CRUD
    // =========================================================

    func fetchAllBadges() throws -> [Badge] {
        let request = Badge.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Badge.badgeType, ascending: true)]
        return try context.fetch(request)
    }

    func fetchUnlockedBadges() throws -> [Badge] {
        let request = Badge.fetchRequest()
        request.predicate = NSPredicate(format: "unlockedAt != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Badge.unlockedAt, ascending: false)]
        return try context.fetch(request)
    }

    func unlockBadge(type: String, title: String) throws {
        let request = Badge.fetchRequest()
        request.predicate = NSPredicate(format: "badgeType == %@", type)
        request.fetchLimit = 1

        if let existing = try context.fetch(request).first {
            guard existing.unlockedAt == nil else { return }
            existing.unlockedAt = Date()
        } else {
            let badge = Badge(context: context)
            badge.id = UUID()
            badge.badgeType = type
            badge.title = title
            badge.unlockedAt = Date()
        }
        try save()
    }

    // =========================================================
    // MARK: - UserStats
    // =========================================================

    func fetchOrCreateUserStats() throws -> UserStats {
        let request = UserStats.fetchRequest()
        request.fetchLimit = 1

        if let existing = try context.fetch(request).first {
            return existing
        }

        let stats = UserStats(context: context)
        stats.id = UUID()
        stats.currentStreak = 0
        stats.longestStreak = 0
        stats.lastWorkoutDate = nil
        stats.weightUnit = "kg"
        try save()
        return stats
    }

    func updateStreak(for stats: UserStats, workoutDate: Date) throws {
        let today = Calendar.current.startOfDay(for: workoutDate)

        if let lastDate = stats.lastWorkoutDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let daysDiff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

            switch daysDiff {
            case 0:
                // Same day — no change
                break
            case 1:
                // Consecutive day
                stats.currentStreak += 1
            default:
                // Streak broken
                stats.currentStreak = 1
            }
        } else {
            stats.currentStreak = 1
        }

        if stats.currentStreak > stats.longestStreak {
            stats.longestStreak = stats.currentStreak
        }
        stats.lastWorkoutDate = today
        try save()
    }

    func updateWeightUnit(_ unit: String) throws {
        let stats = try fetchOrCreateUserStats()
        stats.weightUnit = unit
        try save()
    }

    // =========================================================
    // MARK: - Seed Preset Exercises
    // =========================================================

    func seedPresetExercisesIfNeeded() {
        let key = "StreakLift_SeedCompleted_v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let presets: [PresetExercise] = [
            // 胸
            PresetExercise(name: "ベンチプレス", bodyPart: "胸"),
            PresetExercise(name: "インクラインベンチプレス", bodyPart: "胸"),
            PresetExercise(name: "ダンベルフライ", bodyPart: "胸"),
            // 背中
            PresetExercise(name: "デッドリフト", bodyPart: "背中"),
            PresetExercise(name: "懸垂（チンアップ）", bodyPart: "背中"),
            PresetExercise(name: "ラットプルダウン", bodyPart: "背中"),
            PresetExercise(name: "ベントオーバーロウ", bodyPart: "背中"),
            PresetExercise(name: "シーテッドロウ", bodyPart: "背中"),
            // 脚
            PresetExercise(name: "スクワット", bodyPart: "脚"),
            PresetExercise(name: "レッグプレス", bodyPart: "脚"),
            PresetExercise(name: "レッグカール", bodyPart: "脚"),
            PresetExercise(name: "レッグエクステンション", bodyPart: "脚"),
            PresetExercise(name: "カーフレイズ", bodyPart: "脚"),
            PresetExercise(name: "ルーマニアンデッドリフト", bodyPart: "脚"),
            // 肩
            PresetExercise(name: "ショルダープレス", bodyPart: "肩"),
            PresetExercise(name: "サイドレイズ", bodyPart: "肩"),
            PresetExercise(name: "フロントレイズ", bodyPart: "肩"),
            PresetExercise(name: "フェイスプル", bodyPart: "肩"),
            PresetExercise(name: "アーノルドプレス", bodyPart: "肩"),
            // 腕（二頭）
            PresetExercise(name: "バーベルカール", bodyPart: "腕"),
            PresetExercise(name: "ダンベルカール", bodyPart: "腕"),
            PresetExercise(name: "ハンマーカール", bodyPart: "腕"),
            // 腕（三頭）
            PresetExercise(name: "トライセプスプレスダウン", bodyPart: "腕"),
            PresetExercise(name: "スカルクラッシャー", bodyPart: "腕"),
            PresetExercise(name: "オーバーヘッドエクステンション", bodyPart: "腕"),
            // 体幹
            PresetExercise(name: "プランク", bodyPart: "体幹"),
            PresetExercise(name: "クランチ", bodyPart: "体幹"),
            PresetExercise(name: "レッグレイズ", bodyPart: "体幹"),
            PresetExercise(name: "ロシアンツイスト", bodyPart: "体幹"),
            // 有酸素
            PresetExercise(name: "ランニング", bodyPart: "有酸素"),
            PresetExercise(name: "バイク", bodyPart: "有酸素")
        ]

        let now = Date()
        for preset in presets {
            let exercise = Exercise(context: context)
            exercise.id = UUID()
            exercise.name = preset.name
            exercise.bodyPart = preset.bodyPart
            exercise.isCustom = false
            exercise.isDeleted = false
            exercise.createdAt = now
        }

        do {
            try save()
            UserDefaults.standard.set(true, forKey: key)
        } catch {
            print("Failed to seed preset exercises: \(error)")
        }
    }

    // =========================================================
    // MARK: - Statistics Helpers
    // =========================================================

    func fetchTotalVolume(from startDate: Date, to endDate: Date) throws -> Double {
        let request = WorkoutSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        let sessions = try context.fetch(request)
        return sessions.reduce(0.0) { $0 + $1.totalVolumeKg }
    }

    func fetchPersonalRecord(for exercise: Exercise) throws -> WorkoutSet? {
        let request = WorkoutSet.fetchRequest()
        request.predicate = NSPredicate(format: "exercise == %@", exercise)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSet.weightKg, ascending: false)]
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func fetchWorkoutDates(year: Int, month: Int) throws -> [Date] {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard
            let startDate = Calendar.current.date(from: components),
            let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)
        else { return [] }

        let request = WorkoutSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSession.date, ascending: true)]
        return try context.fetch(request).map { $0.date }
    }
}
