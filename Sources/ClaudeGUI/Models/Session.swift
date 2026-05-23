import Foundation

struct Session: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var shortId: String  // First part of sessionId before first dash
    let createdAt: Date
    var workingDirectory: String
    var status: String  // "waiting", "working", "completed", "idle"

    init(id: UUID = UUID(), name: String = "New Session", shortId: String = "", workingDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path, createdAt: Date = Date(), status: String = "idle") {
        self.id = id
        self.name = name
        self.shortId = shortId
        self.createdAt = createdAt
        self.workingDirectory = workingDirectory
        self.status = status
    }
}
