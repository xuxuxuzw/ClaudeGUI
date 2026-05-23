import SwiftUI

struct WelcomeView: View {
    let onCreateSession: () -> Void
    @ObservedObject var localization = Localization.shared

    private let surface = AppTheme.bgSurface
    private let textPrimary = AppTheme.textPrimary
    private let textSecondary = AppTheme.textSecondary

    var body: some View {
        VStack(spacing: 28) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 80, height: 80)
                Image(systemName: "terminal.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 8) {
                Text("Claude GUI")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(textPrimary)

                Text(L10n.welcomeSubtitle)
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(textSecondary)
                    .lineSpacing(4)
            }

            Button(action: onCreateSession) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text(L10n.newSession)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            HStack(spacing: 24) {
                ShortcutHint(key: "R", description: L10n.allSessions)
                ShortcutHint(key: "1-9", description: L10n.switchTab)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.bgBase)
    }
}

struct ShortcutHint: View {
    let key: String
    let description: String

    private let keyBg = AppTheme.bgElevated
    private let textSecondary = AppTheme.textSecondary

    var body: some View {
        HStack(spacing: 6) {
            Text("⌘")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(textSecondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(keyBg)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(key)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(textSecondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(keyBg)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(description)
                .font(.system(size: 11))
                .foregroundStyle(textSecondary)
        }
    }
}
