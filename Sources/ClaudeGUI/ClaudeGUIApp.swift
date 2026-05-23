import SwiftUI

@main
struct ClaudeGUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About ClaudeGUI") {
                    AppDelegate.aboutWindowController.show()
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: MainWindowController?
    static let aboutWindowController = AboutWindowController()

    func applicationWillFinishLaunching(_ notification: Notification) {
        // SwiftUI defaults to .accessory when no WindowGroup scene exists;
        // force regular policy so the app can become the frontmost app.
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        // Set app icon from bundle
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let icon = NSImage(contentsOfFile: iconPath) {
            NSApp.applicationIconImage = icon
        }

        windowController = MainWindowController()
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
