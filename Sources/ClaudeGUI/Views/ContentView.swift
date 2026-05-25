import SwiftUI

struct ContentView: View {
    @StateObject private var sessionManager = SessionManager()

    var body: some View {
        HSplitView {
            // Left sidebar — session list
            SidebarView(sessionManager: sessionManager)
                .frame(minWidth: 200, idealWidth: 240, maxWidth: 300)

            // Right — terminal area
            GeometryReader { geometry in
                ZStack {
                    if sessionManager.sessions.isEmpty {
                        WelcomeView {
                            sessionManager.createSession()
                        }
                    } else if let activeId = sessionManager.activeSessionId {
                        ForEach(sessionManager.sessions) { session in
                            TerminalViewRepresentable(
                                sessionId: session.id,
                                workingDirectory: session.workingDirectory,
                                isActive: session.id == activeId
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .opacity(session.id == activeId ? 1 : 0)
                            .allowsHitTesting(session.id == activeId)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            if sessionManager.sessions.isEmpty {
                sessionManager.createSession()
            }
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @ObservedObject var sessionManager: SessionManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Sessions")
                    .font(.headline)
                Spacer()
                Button(action: { sessionManager.createSession() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(.plain)
                .help("New Session (Cmd+T)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Session list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(sessionManager.sessions) { session in
                        SessionRow(
                            session: session,
                            isActive: sessionManager.activeSessionId == session.id,
                            onSelect: { sessionManager.switchToSession(id: session.id) },
                            onClose: { sessionManager.closeSession(id: session.id) },
                            onRename: { newName in sessionManager.renameSession(id: session.id, to: newName) }
                        )
                    }
                }
                .padding(.vertical, 8)
            }

            Divider()

            // Bottom info
            HStack {
                Image(systemName: "terminal")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(sessionManager.sessions.count) session\(sessionManager.sessions.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: Session
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void
    let onRename: (String) -> Void

    @State private var isHovering = false
    @State private var isEditing = false
    @State private var editingName = ""

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isActive ? "circle.fill" : "circle")
                .font(.system(size: 8))
                .foregroundColor(isActive ? .accentColor : .clear)

            if isEditing {
                TextField("Name", text: $editingName, onCommit: {
                    let trimmed = editingName.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        onRename(trimmed)
                    }
                    isEditing = false
                })
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onExitCommand { isEditing = false }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.name)
                        .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                        .lineLimit(1)

                    Text(session.createdAt, style: .relative)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isHovering && !isEditing {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive
                    ? Color.accentColor.opacity(0.12)
                    : (isHovering ? AppTheme.hoverBg : Color.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onTapGesture(count: 2) {
            editingName = session.name
            isEditing = true
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
        .padding(.horizontal, 8)
    }
}
