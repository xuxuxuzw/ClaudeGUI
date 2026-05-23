import Foundation
import Combine

enum CheckStatus {
    case pending
    case ok
    case fail
}

final class EnvironmentChecker: ObservableObject {
    static let shared = EnvironmentChecker()

    @Published var nodeStatus: CheckStatus = .pending
    @Published var cliStatus: CheckStatus = .pending
    @Published var loginStatus: CheckStatus = .pending
    @Published var isChecking = false

    var allOk: Bool {
        nodeStatus == .ok && cliStatus == .ok && loginStatus == .ok
    }

    var hasFail: Bool {
        nodeStatus == .fail || cliStatus == .fail || loginStatus == .fail
    }

    private init() {}

    func check() {
        isChecking = true
        nodeStatus = .pending
        cliStatus = .pending
        loginStatus = .pending

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // 1. Check Node.js
            let nodeOk = self?.runCheck("node --version") ?? false
            DispatchQueue.main.async { self?.nodeStatus = nodeOk ? .ok : .fail }

            // 2. Check Claude CLI
            let claudePath = self?.getClaudePath() ?? "claude"
            let cliOk = self?.runCheck("\(claudePath) --version") ?? false
            DispatchQueue.main.async { self?.cliStatus = cliOk ? .ok : .fail }

            // 3. Check login status (claude agents returns 0 if logged in)
            let loginOk = self?.runCheck("\(claudePath) agents") ?? false
            DispatchQueue.main.async {
                self?.loginStatus = loginOk ? .ok : .fail
                self?.isChecking = false
            }
        }
    }

    private func runCheck(_ command: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", command]

        let devNull = FileHandle.nullDevice
        process.standardOutput = devNull
        process.standardError = devNull

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func getClaudePath() -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let versionsDir = "\(home)/.nvm/versions/node"
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: versionsDir) {
            let sorted = contents.sorted(by: >)
            for version in sorted {
                let path = "\(versionsDir)/\(version)/bin/claude"
                if FileManager.default.isExecutableFile(atPath: path) {
                    return path
                }
            }
        }
        return "claude"
    }
}
