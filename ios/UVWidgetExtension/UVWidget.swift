import WidgetKit
import SwiftUI

extension WidgetConfiguration {
    func widgetContentMarginsDisabledIfAvailable() -> some WidgetConfiguration {
        if #available(iOSApplicationExtension 15.0, *) {
            return self.contentMarginsDisabled()
        } else {
            return self
        }
    }
}

// MARK: - Data Model

struct UVWidgetEntry: TimelineEntry {
    let date: Date
    let uvIndex: Int
    let uvStatus: String
    let burnTime: String
    let timerRunning: Bool
    let timerEndTime: Date?
    let sessionsText: String
    let protectionStatus: String

    var isLow: Bool { uvIndex <= 2 }

    var sessionsCompleted: Int {
        Int(sessionsText.split(separator: "/").first ?? "0") ?? 0
    }

    var sessionsTotal: Int {
        Int(sessionsText.split(separator: "/").last ?? "0") ?? 0
    }

    var sessionsFraction: Double {
        guard sessionsTotal > 0 else { return 0 }
        return min(max(Double(sessionsCompleted) / Double(sessionsTotal), 0), 1)
    }

    var timerLabel: String {
        if !timerRunning { return "Ready" }
        return protectionStatus == "Expiring Soon" ? "Expiring" : "Active"
    }

    var timerText: String? {
        guard timerRunning, timerEndTime != nil else { return nil }
        return nil
    }

    var burnTimeDisplayText: String {
        let normalized = burnTime.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if uvIndex == 0 || normalized.isEmpty || normalized.contains("inf") {
            return "No sunburn"
        }

        return burnTime
    }
}

// MARK: - Design Tokens

struct WidgetPalette {
    let primary: Color
    let ringEnd: Color
    let glow: Color
    let pillFill: Color
    let pillStroke: Color
}

enum WidgetTheme {
    static let glass = Color.white.opacity(0.06)
    static let glassBorder = Color.white.opacity(0.11)
    static let innerGlass = Color.white.opacity(0.05)
    static let innerBorder = Color.white.opacity(0.09)

    static let textPrimary = Color.white.opacity(0.93)
    static let textSecondary = Color.white.opacity(0.54)
    static let textMuted = Color.white.opacity(0.30)
    static let headerText = Color.white.opacity(0.34)

    static let green = Color(red: 0.29, green: 0.87, blue: 0.50)
    static let cyan = Color(red: 0.13, green: 0.83, blue: 0.93)
    static let amber = Color(red: 0.98, green: 0.75, blue: 0.14)
    static let orange = Color(red: 0.98, green: 0.45, blue: 0.09)
    static let red = Color(red: 0.97, green: 0.44, blue: 0.44)

    static func palette(for index: Int) -> WidgetPalette {
        switch index {
        case ...2:
            return WidgetPalette(
                primary: green,
                ringEnd: cyan,
                glow: green.opacity(0.30),
                pillFill: green.opacity(0.15),
                pillStroke: green.opacity(0.35)
            )
        case 3...5:
            return WidgetPalette(
                primary: amber,
                ringEnd: orange,
                glow: amber.opacity(0.24),
                pillFill: amber.opacity(0.16),
                pillStroke: amber.opacity(0.35)
            )
        default:
            return WidgetPalette(
                primary: orange,
                ringEnd: red,
                glow: orange.opacity(0.26),
                pillFill: orange.opacity(0.16),
                pillStroke: orange.opacity(0.35)
            )
        }
    }

    static func protectionColor(for status: String) -> Color {
        switch status {
        case "Protected", "Done for today", "UV is low":
            return green
        default:
            return red
        }
    }
}

// MARK: - Shared Components

struct WidgetGlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let glowColor: Color
    let glowAlignment: Alignment
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(WidgetTheme.glass)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(WidgetTheme.glassBorder, lineWidth: 0.8)

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.06), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )

            RadialGradient(
                colors: [glowColor, Color.clear],
                center: .center,
                startRadius: 4,
                endRadius: 110
            )
            .frame(width: 150, height: 100)
            .blur(radius: 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: glowAlignment)
            .offset(y: -24)

            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct UVSunLabel: View {
    let compact: Bool

    var body: some View {
        HStack(spacing: compact ? 7 : 8) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: compact ? 16 : 18, weight: .regular))
                .foregroundColor(Color.white.opacity(0.48))

            if compact {
                Text("UV")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(WidgetTheme.headerText)
            } else {
                VStack(alignment: .leading, spacing: -1) {
                    Text("UV")
                    Text("INDEX")
                }
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(WidgetTheme.headerText)
            }
        }
    }
}

struct WidgetStatusPill: View {
    let text: String
    let color: Color
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 5 : 7) {
            Circle()
                .fill(color)
                .frame(width: compact ? 7 : 8, height: compact ? 7 : 8)

            Text(text.uppercased())
                .font(.system(size: compact ? 8.5 : 10, weight: .bold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .padding(.horizontal, compact ? 10 : 14)
        .padding(.vertical, compact ? 6 : 8)
        .background(color.opacity(0.16))
        .overlay(
            Capsule()
                .stroke(color.opacity(0.35), lineWidth: 0.8)
        )
        .clipShape(Capsule())
    }
}

struct WidgetCountdownText: View {
    let endTime: Date?
    let fontSize: CGFloat

    var body: some View {
        Group {
            if let endTime {
                Text(endTime, style: .timer)
            } else {
                Text("--:--:--")
            }
        }
        .font(.system(size: fontSize, weight: .medium, design: .monospaced))
    }
}

struct WidgetProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [WidgetTheme.green, WidgetTheme.cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(18, geo.size.width * progress))
            }
        }
        .frame(height: 6)
    }
}

struct WidgetRingView: View {
    let value: Int
    let palette: WidgetPalette
    let size: CGFloat
    let lineWidth: CGFloat
    let fontSize: CGFloat

    var progress: CGFloat {
        min(max(CGFloat(value) / 11.0, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [palette.primary, palette.ringEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(value)")
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(palette.primary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Timeline Provider

struct UVWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> UVWidgetEntry {
        UVWidgetEntry(
            date: Date(),
            uvIndex: 6,
            uvStatus: "High",
            burnTime: "11 mins",
            timerRunning: true,
            timerEndTime: Date().addingTimeInterval(3600),
            sessionsText: "1/3",
            protectionStatus: "Protected"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (UVWidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UVWidgetEntry>) -> Void) {
        let entry = loadEntry()
        var nextUpdate = Date().addingTimeInterval(15 * 60)
        if let end = entry.timerEndTime, end < nextUpdate {
            nextUpdate = end.addingTimeInterval(60)
        }
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> UVWidgetEntry {
        let ud = UserDefaults(suiteName: "group.com.thearyamann.uvprotector")

        return UVWidgetEntry(
            date: Date(),
            uvIndex: ud?.integer(forKey: "uv_index") ?? 0,
            uvStatus: ud?.string(forKey: "uv_status") ?? "Low",
            burnTime: ud?.string(forKey: "burn_time") ?? "0 mins",
            timerRunning: ud?.bool(forKey: "timer_running") ?? false,
            timerEndTime: {
                let ms = ud?.integer(forKey: "timer_end_time") ?? 0
                return ms > 0 ? Date(timeIntervalSince1970: Double(ms) / 1000.0) : nil
            }(),
            sessionsText: ud?.string(forKey: "sessions_text") ?? "0/0",
            protectionStatus: ud?.string(forKey: "protection_status") ?? "Not Applied"
        )
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: UVWidgetEntry
    let palette: WidgetPalette

    var body: some View {
        WidgetGlassCard(cornerRadius: 26, glowColor: palette.glow, glowAlignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    UVSunLabel(compact: false)
                    Spacer(minLength: 10)
                    WidgetStatusPill(text: entry.uvStatus, color: palette.primary, compact: true)
                }
                .frame(maxWidth: .infinity, alignment: .top)

                Spacer(minLength: 8)

                Text("\(entry.uvIndex)")
                    .font(.system(size: 66, weight: .bold))
                    .foregroundColor(palette.primary)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 10)

                if entry.isLow {
                    SmallLowCard()
                } else {
                    SmallTimerCard(entry: entry)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SmallLowCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("No cream needed")
                .font(.system(size: 8.5, weight: .bold))
                .foregroundColor(WidgetTheme.green)
                .lineLimit(1)

            Text("Check when heading outside")
                .font(.system(size: 7.5))
                .foregroundColor(WidgetTheme.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(WidgetTheme.green.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(WidgetTheme.green.opacity(0.18), lineWidth: 0.8)
                )
        )
    }
}

struct SmallTimerCard: View {
    let entry: UVWidgetEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.46))

            WidgetCountdownText(endTime: entry.timerEndTime, fontSize: 11.5)
                .foregroundColor(WidgetTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 8)

            Text(entry.timerLabel)
                .font(.system(size: 7.5, weight: .medium))
                .foregroundColor(WidgetTheme.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(WidgetTheme.innerGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(WidgetTheme.innerBorder, lineWidth: 0.8)
                )
        )
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: UVWidgetEntry
    let palette: WidgetPalette

    var body: some View {
        WidgetGlassCard(cornerRadius: 28, glowColor: palette.glow, glowAlignment: .top) {
            HStack(spacing: 12) {
                VStack(spacing: 0) {
                    UVSunLabel(compact: false)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Spacer(minLength: 6)

                    WidgetRingView(
                        value: entry.uvIndex,
                        palette: palette,
                        size: 76,
                        lineWidth: 7,
                        fontSize: 26
                    )
                    .frame(maxWidth: .infinity, alignment: .center)

                    Spacer(minLength: 8)

                    HStack(spacing: 6) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.white.opacity(0.48))

                        Text("Burn in")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(WidgetTheme.textSecondary)

                        Text(entry.burnTimeDisplayText)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(palette.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(width: 108)

                if entry.isLow {
                    MediumLowPanel(entry: entry)
                } else {
                    MediumActivePanel(entry: entry)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MediumLowPanel: View {
    let entry: UVWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetStatusPill(text: "UV is low", color: WidgetTheme.green, compact: true)

            Spacer(minLength: 10)

            Text("No cream needed at the\nmoment")
                .font(.system(size: 14.5, weight: .bold))
                .foregroundColor(WidgetTheme.green)
                .lineSpacing(1)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 6)

            Text("Check again when you head\noutside")
                .font(.system(size: 8.8, weight: .medium))
                .foregroundColor(WidgetTheme.textSecondary)
                .lineSpacing(1)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 8)

            Text("0 / \(entry.sessionsTotal) Sessions")
                .font(.system(size: 8.8, weight: .medium))
                .foregroundColor(WidgetTheme.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(WidgetTheme.green.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(WidgetTheme.green.opacity(0.18), lineWidth: 0.8)
                )
        )
    }
}

struct MediumActivePanel: View {
    let entry: UVWidgetEntry

    var statusColor: Color {
        WidgetTheme.protectionColor(for: entry.protectionStatus)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetStatusPill(text: entry.protectionStatus, color: statusColor, compact: true)

            Spacer(minLength: 10)

            WidgetCountdownText(endTime: entry.timerEndTime, fontSize: 28)
                .foregroundColor(entry.timerRunning ? WidgetTheme.textPrimary : Color.white.opacity(0.25))
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Spacer(minLength: 10)

            Text("\(entry.sessionsCompleted) / \(entry.sessionsTotal) Sessions")
                .font(.system(size: 8.8, weight: .medium))
                .foregroundColor(WidgetTheme.textMuted)
                .lineLimit(1)

            Spacer(minLength: 6)

            WidgetProgressBar(progress: entry.sessionsFraction)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(WidgetTheme.innerGlass)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(WidgetTheme.innerBorder, lineWidth: 0.8)
                )
        )
    }
}

// MARK: - Entry View

struct UVWidgetEntryView: View {
    let entry: UVWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let palette = WidgetTheme.palette(for: entry.uvIndex)

        ZStack {
            Color.black.opacity(0.92)

            if family == .systemSmall {
                SmallWidgetView(entry: entry, palette: palette)
            } else {
                MediumWidgetView(entry: entry, palette: palette)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget

struct UVProtectorWidget: Widget {
    let kind = "UVProtectorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UVWidgetProvider()) { entry in
            UVWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("UV Protector")
        .description("Real-time UV index and SPF timer.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .widgetContentMarginsDisabledIfAvailable()
    }
}
