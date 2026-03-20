import Foundation
import SwiftUI

// MARK: - Muscle Group

enum MuscleGroup: String, CaseIterable, Codable {
    case chest = "胸"
    case back = "背中"
    case shoulders = "肩"
    case arms = "腕"
    case legs = "脚"
    case core = "体幹"
    case cardio = "有酸素"

    var icon: String {
        switch self {
        case .chest:     return "figure.strengthtraining.traditional"
        case .back:      return "figure.rowing"
        case .shoulders: return "figure.arms.open"
        case .arms:      return "dumbbell.fill"
        case .legs:      return "figure.run"
        case .core:      return "figure.core.training"
        case .cardio:    return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .chest:     return .red
        case .back:      return .blue
        case .shoulders: return .orange
        case .arms:      return .purple
        case .legs:      return .green
        case .core:      return Color(red: 0.9, green: 0.7, blue: 0.1)
        case .cardio:    return .pink
        }
    }
}

// MARK: - Exercise

struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let muscleGroup: MuscleGroup
    let isBodyweight: Bool

    init(id: UUID = UUID(), name: String, muscleGroup: MuscleGroup, isBodyweight: Bool = false) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.isBodyweight = isBodyweight
    }
}

// MARK: - Default Exercise List (30種目)

extension Exercise {
    static let defaultExercises: [Exercise] = [
        // 胸
        Exercise(name: "ベンチプレス",          muscleGroup: .chest),
        Exercise(name: "プッシュアップ",         muscleGroup: .chest, isBodyweight: true),
        Exercise(name: "ダンベルフライ",         muscleGroup: .chest),
        Exercise(name: "インクラインプレス",      muscleGroup: .chest),
        Exercise(name: "チェストディップス",      muscleGroup: .chest, isBodyweight: true),
        // 背中
        Exercise(name: "チンアップ",             muscleGroup: .back, isBodyweight: true),
        Exercise(name: "ラットプルダウン",        muscleGroup: .back),
        Exercise(name: "バーベルロウ",           muscleGroup: .back),
        Exercise(name: "ダンベルロウ",           muscleGroup: .back),
        Exercise(name: "デッドリフト",           muscleGroup: .back),
        // 肩
        Exercise(name: "アーノルドプレス",    muscleGroup: .shoulders),
        Exercise(name: "ラテラルレイズ",         muscleGroup: .shoulders),
        Exercise(name: "フロントレイズ",         muscleGroup: .shoulders),
        Exercise(name: "リアデルトフライ",        muscleGroup: .shoulders),
        // 腕
        Exercise(name: "バイセップカール",        muscleGroup: .arms),
        Exercise(name: "ハンマーカール",          muscleGroup: .arms),
        Exercise(name: "トライセップエクステンション", muscleGroup: .arms),
        Exercise(name: "トライセップディップス",   muscleGroup: .arms, isBodyweight: true),
        // 脚
        Exercise(name: "ダンベルブルガリアンスクワット",             muscleGroup: .legs),
        Exercise(name: "レッグプレス",           muscleGroup: .legs),
        Exercise(name: "ランジ",                 muscleGroup: .legs, isBodyweight: true),
        Exercise(name: "レッグカール",           muscleGroup: .legs),
        Exercise(name: "レッグエクステンション",  muscleGroup: .legs),
        Exercise(name: "カーフレイズ",           muscleGroup: .legs, isBodyweight: true),
        // 体幹
        Exercise(name: "プランク",               muscleGroup: .core, isBodyweight: true),
        Exercise(name: "クランチ",               muscleGroup: .core, isBodyweight: true),
        Exercise(name: "ロシアンツイスト",        muscleGroup: .core, isBodyweight: true),
        Exercise(name: "レッグレイズ",           muscleGroup: .core, isBodyweight: true),
        // 有酸素
        Exercise(name: "ラン",    muscleGroup: .cardio, isBodyweight: true),
        Exercise(name: "バイク",               muscleGroup: .cardio, isBodyweight: true),
    ]
}

// MARK: - Workout Set

struct WorkoutSet: Identifiable, Codable {
    let id: UUID
    var exerciseId: UUID
    var weight: Double    // kg (0 for bodyweight)
    var reps: Int
    var notes: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        exerciseId: UUID,
        weight: Double = 0,
        reps: Int = 10,
        notes: String = ""
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.weight = weight
        self.reps = reps
        self.notes = notes
        self.createdAt = Date()
    }
}

// MARK: - Workout Session

struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    var sets: [WorkoutSet]
    var notes: String
    let startedAt: Date
    var endedAt: Date?

    init(id: UUID = UUID(), sets: [WorkoutSet] = [], notes: String = "") {
        self.id = id
        self.sets = sets
        self.notes = notes
        self.startedAt = Date()
    }

    var duration: TimeInterval? {
        guard let ended = endedAt else { return nil }
        return ended.timeIntervalSince(startedAt)
    }

    var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }
}

// MARK: - HIIT Config

struct HIITConfig: Codable, Equatable {
    var workSeconds: Int
    var restSeconds: Int
    var rounds: Int

    static let tabata     = HIITConfig(workSeconds: 20, restSeconds: 10, rounds: 8)
    static let standard   = HIITConfig(workSeconds: 40, restSeconds: 20, rounds: 8)
    static let endurance  = HIITConfig(workSeconds: 45, restSeconds: 15, rounds: 6)
}

// MARK: - Timer Phase

enum TimerPhase: Equatable {
    case idle
    case work
    case rest
    case finished
}
