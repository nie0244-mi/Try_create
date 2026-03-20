import Foundation
import Combine

// MARK: - DataStore

class DataStore: ObservableObject {

    // Published state
    @Published var exercises: [Exercise] = Exercise.defaultExercises
    @Published var sessions: [WorkoutSession] = []
    @Published var currentSession: WorkoutSession?

    // Persistence keys
    private let sessionsKey = "ft_sessions_v1"

    init() {
        loadSessions()
    }

    // MARK: - Session Management

    func startSession() {
        currentSession = WorkoutSession()
    }

    func endSession() {
        guard var session = currentSession else { return }
        session.endedAt = Date()
        if !session.sets.isEmpty {
            sessions.insert(session, at: 0)
            saveSessions()
        }
        currentSession = nil
    }

    func discardSession() {
        currentSession = nil
    }

    // MARK: - Set Management

    func addSet(_ set: WorkoutSet) {
        if currentSession == nil { startSession() }
        currentSession?.sets.append(set)
    }

    func removeSet(id: UUID) {
        currentSession?.sets.removeAll { $0.id == id }
    }

    func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
        saveSessions()
    }

    // MARK: - Exercise Helpers

    func exercise(for id: UUID) -> Exercise? {
        exercises.first { $0.id == id }
    }

    /// Most recent weight used for an exercise across saved sessions
    func lastWeight(for exerciseId: UUID) -> Double {
        for session in sessions {
            if let set = session.sets.last(where: { $0.exerciseId == exerciseId }) {
                return set.weight
            }
        }
        return 0
    }

    /// Most recent rep count for an exercise
    func lastReps(for exerciseId: UUID) -> Int {
        for session in sessions {
            if let set = session.sets.last(where: { $0.exerciseId == exerciseId }) {
                return set.reps
            }
        }
        return 10
    }

    /// All sets for an exercise across all sessions (for progress charts)
    func allSets(for exerciseId: UUID) -> [WorkoutSet] {
        sessions.flatMap { $0.sets }.filter { $0.exerciseId == exerciseId }
    }

    // MARK: - Persistence

    private func saveSessions() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: sessionsKey)
    }

    private func loadSessions() {
        guard
            let data = UserDefaults.standard.data(forKey: sessionsKey),
            let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data)
        else { return }
        sessions = decoded
    }
}
