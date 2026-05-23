# ClaudeGUI

A native macOS GUI for managing multiple Claude Code sessions with terminal integration, dark/light themes, and bilingual support.

English | [中文](README_CN.md)

## Features

- **Multi-session management** — Sidebar lists all background agent sessions, grouped by status (Awaiting Input, Working, Completed, Idle)
- **New session** — Enter a task description and select a working directory, runs `claude --bg "task"` in the background
- **Terminal integration** — Each session has an independent terminal via SwiftTerm PTY, run `claude attach <id>` to enter
- **Drag & drop** — Drop files from Finder into the terminal, auto-formatted as `@/path/to/file`
- **Auto sync** — Polls `claude agents --json` every 5 seconds to refresh session list
- **Theme switching** — Three color schemes: Basic (dark), Clear Dark (translucent dark), Clear Light (bright)
- **Bilingual** — Chinese / English toggle, all UI text supports both languages
- **Keyboard shortcuts** — `Cmd+R` refresh, `Cmd+1~9` switch sessions

## Installation

Download `ClaudeGUI.app` from this repository and drag it to your Applications folder.

> Requires macOS 14.0+ and [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed.

## Prerequisites

Before running ClaudeGUI, make sure the following are set up:

1. **Node.js** — Claude Code is a Node.js CLI tool. Install via [nvm](https://github.com/nvm-sh/nvm) or [Homebrew](https://brew.sh)
   ```bash
   # Using nvm (recommended)
   nvm install --lts

   # Or using Homebrew
   brew install node
   ```

2. **Claude Code CLI** — Install globally via npm
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

3. **Claude Code authentication** — Run `claude` once in Terminal to complete the initial login
   ```bash
   claude
   ```
   This will open the browser for authentication. Complete the login flow, then exit.

4. **Verify installation** — Confirm these commands work in Terminal:
   ```bash
   claude --version        # Should print the version number
   claude agents           # Should show a TUI list of agents (empty if none running)
   claude agents --json    # Should output a JSON array
   ```

If `claude` is not found, the app will also search `~/.nvm/versions/node/*/bin/claude` automatically.

## Build from Source

```bash
# Clone the repo
git clone <repo-url>
cd ClaudeGUI

# Build with Swift Package Manager
swift build

# Or open in Xcode
open ClaudeGUI.xcodeproj
```

## Project Structure

```
ClaudeGUI/
├── ClaudeGUI.app/              # Prebuilt application
├── ClaudeGUI.xcodeproj/        # Xcode project
├── Package.swift               # SPM dependencies (SwiftTerm)
├── Sources/ClaudeGUI/
│   ├── ClaudeGUIApp.swift      # App entry point
│   ├── Theme.swift             # Theme system (Basic / Clear Dark / Clear Light)
│   ├── Localization.swift      # Bilingual support (zh/en)
│   ├── MainWindowController.swift  # Main window + terminal management
│   ├── Models/
│   │   ├── Session.swift       # Session data model
│   │   └── SessionManager.swift    # Session list + UserDefaults persistence
│   ├── Views/
│   │   ├── ContentView.swift   # Root layout (sidebar + terminal)
│   │   ├── TabBarView.swift    # Sidebar with session groups
│   │   ├── TerminalView.swift  # SwiftTerm SwiftUI wrapper
│   │   ├── WelcomeView.swift   # Empty state view
│   │   └── DragDropTerminalView.swift  # Terminal with file drag & drop
│   └── Services/
│       └── TerminalService.swift   # Terminal lifecycle management
├── DESIGN.md                   # Design system documentation
├── FEATURES.md                 # Feature overview
└── IMPLEMENTATION.md           # Implementation reference
```

## Architecture

```
MainWindowController (NSWindowController)
  └── NSSplitView
        ├── SidebarSessionView (SwiftUI via NSHostingView)
        │     ├── Theme toggle / Language toggle
        │     ├── Session groups (collapsible)
        │     └── New session button
        └── Terminal Container
              ├── Overview terminal (claude agents)
              └── Session terminals (claude attach <id>)
```

## TODO

- [ ] **Environment detection** — Auto-check Node.js, Claude Code CLI, and auth status on launch; display results in the top-right corner of the app
- [ ] **Workspaces** — Introduce Workspace concept: group sessions by working directory, each workspace has its own four status groups (Awaiting Input, Working, Completed, Idle), with individual sessions nested under each group

## License

MIT
