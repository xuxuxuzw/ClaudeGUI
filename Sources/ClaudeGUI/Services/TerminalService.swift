import Foundation
import SwiftTerm

/// Tracks running terminal processes so they can be terminated when sessions close.
final class TerminalService {
    static let shared = TerminalService()

    private var terminalViews: [UUID: LocalProcessTerminalView] = [:]

    private init() {}

    /// Register a terminal view for a session.
    func register(terminalView: LocalProcessTerminalView, for sessionId: UUID) {
        terminalViews[sessionId] = terminalView
    }

    /// Terminate the process and remove the terminal view for a given session.
    func terminateProcess(for sessionId: UUID) {
        guard let tv = terminalViews.removeValue(forKey: sessionId) else { return }
        tv.terminate()
    }

    /// Get the terminal view for a session (for copy/paste forwarding).
    func getTerminalView(for sessionId: UUID) -> LocalProcessTerminalView? {
        return terminalViews[sessionId]
    }

    /// Get the shell path from the environment.
    func getShell() -> String {
        return ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
    }

    /// Get the full path to the claude binary.
    func getClaudePath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        // Check common nvm node bin locations
        let versionsDir = "\(home)/.nvm/versions/node"
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: versionsDir) {
            // Sort descending to get latest version
            let sorted = contents.sorted(by: >)
            for version in sorted {
                let path = "\(versionsDir)/\(version)/bin/claude"
                if FileManager.default.isExecutableFile(atPath: path) {
                    return path
                }
            }
        }
        // Fallback
        return "claude"
    }
}
