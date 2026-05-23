import SwiftUI

struct AboutView: View {
    @ObservedObject var localization = Localization.shared

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Text("ClaudeGUI")
                .font(.system(size: 18, weight: .bold))

            Text("v\(appVersion) (build \(buildNumber))")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Text(localization.current == .chinese
                 ? "macOS 原生的 Claude Code 多会话管理工具"
                 : "A native macOS GUI for managing multiple Claude Code sessions")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 240)

            Divider()
                .frame(width: 180)

            Text("MIT License")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Button(action: {
                NSWorkspace.shared.open(URL(string: "https://github.com/xuxuxuzw/ClaudeGUI")!)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 11))
                    Text("github.com/xuxuxuzw/ClaudeGUI")
                        .font(.system(size: 11))
                }
            }
            .buttonStyle(.link)
        }
        .padding(24)
    }
}

final class AboutWindowController: NSObject {
    private var window: NSWindow?

    func show() {
        if window == nil {
            let aboutView = AboutView()
            let hostingView = NSHostingView(rootView: aboutView)
            let targetSize = NSSize(width: 360, height: 400)
            hostingView.frame = NSRect(origin: .zero, size: targetSize)

            let win = NSWindow(
                contentRect: NSRect(origin: .zero, size: targetSize),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            win.contentView = hostingView
            win.title = "About ClaudeGUI"
            win.center()
            win.isReleasedWhenClosed = false
            window = win
        }
        window?.title = "About ClaudeGUI"
        window?.makeKeyAndOrderFront(nil)
    }
}
