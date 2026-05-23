import Foundation
import Combine

final class SessionManager: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var activeSessionId: UUID?

    private let sessionsKey = "claudeGUI_sessions"

    init() {
        loadSessions()
    }

    // MARK: - Session CRUD

    @discardableResult
    func createSession(name: String = "New Session", workingDirectory: String? = nil) -> Session {
        let dir = workingDirectory ?? FileManager.default.homeDirectoryForCurrentUser.path
        let session = Session(name: name, workingDirectory: dir)
        sessions.append(session)
        activeSessionId = session.id
        saveSessions()
        return session
    }

    func closeSession(id: UUID) {
        TerminalService.shared.terminateProcess(for: id)
        sessions.removeAll { $0.id == id }
        if activeSessionId == id {
            activeSessionId = sessions.last?.id
        }
        saveSessions()
    }

    func switchToSession(id: UUID) {
        guard sessions.contains(where: { $0.id == id }) else { return }
        activeSessionId = id
    }

    func renameSession(id: UUID, to newName: String) {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].name = newName
        saveSessions()
    }

    // MARK: - Persistence

    private func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey),
              let decoded = try? JSONDecoder().decode([Session].self, from: data)
        else { return }
        sessions = decoded
    }

    private func saveSessions() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: sessionsKey)
    }
}
