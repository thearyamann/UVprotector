import WidgetKit
import SwiftUI

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
        return Double(sessionsCompleted) / Double(sessionsTotal)
    }
}

// MARK: - Design Tokens

struct WidgetColors {
    static let glassBg = Color.white.opacity(0.08)
    static let glassBorder = Color.white.opacity(0.15)
    static let innerCardBg = Color.white.opacity(0.06)
    static let innerCardBorder = Color.white.opacity(0.12)
    
    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.55)
    static let textMuted = Color.white.opacity(0.38)
    static let labelMuted = Color.white.opacity(0.35)
    
    static let greenBg = Color(red: 0.29, green: 0.87, blue: 0.50).opacity(0.08)
    static let greenBorder = Color(red: 0.29, green: 0.87, blue: 0.50).opacity(0.25)
}

struct WidgetTheme {
    static func riskColor(_ index: Int) -> Color {
        switch index {
        case 0...2: return Color(red: 0.29, green: 0.87, blue: 0.50)
        case 3...5: return Color(red: 0.98, green: 0.75, blue: 0.14)
        case 6...7: return Color(red: 0.98, green: 0.45, blue: 0.09)
        default:    return Color(red: 0.97, green: 0.44, blue: 0.44)
        }
    }
    
    static func glowColor(_ index: Int) -> Color {
        switch index {
        case 0...2: return Color(red: 0.29, green: 0.87, blue: 0.50).opacity(0.15)
        case 3...5: return Color(red: 0.98, green: 0.75, blue: 0.14).opacity(0.15)
        case 6...7: return Color(red: 0.98, green: 0.45, blue: 0.09).opacity(0.18)
        default:    return Color(red: 0.97, green: 0.44, blue: 0.44).opacity(0.18)
        }
    }
}

// MARK: - Components

struct GlassCard: View {
    let bgColor: Color
    let borderColor: Color
    let cornerRadius: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(bgColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 0.5)
            )
    }
}

struct StatusPill: View {
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text(text.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
                .foregroundColor(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .overlay(
            Capsule()
                .stroke(color.opacity(0.3), lineWidth: 0.5)
        )
        .clipShape(Capsule())
    }
}

struct SunIcon: View {
    var body: some View {
        Image(systemName: "sun.max.fill")
            .font(.system(size: 12))
            .foregroundColor(Color.white.opacity(0.6))
    }
}

struct ShieldIcon: View {
    var body: some View {
        Image(systemName: "shield.fill")
            .font(.system(size: 11))
            .foregroundColor(Color.white.opacity(0.5))
    }
}

struct FlameIcon: View {
    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: 9))
            .foregroundColor(Color.white.opacity(0.5))
    }
}

struct UVLabel: View {
    var body: some View {
        Text("UV INDEX")
            .font(.system(size: 8, weight: .semibold))
            .tracking(1.5)
            .foregroundColor(WidgetColors.labelMuted)
    }
}

struct BurnTimeRow: View {
    let burnTime: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            FlameIcon()
            Text("Burn in ")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(WidgetColors.textSecondary)
            Text(burnTime)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
        }
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
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
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
    let riskColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header Row
            HStack {
                HStack(spacing: 5) {
                    SunIcon()
                    UVLabel()
                }
                Spacer()
                StatusPill(text: entry.uvStatus, color: riskColor)
            }
            
            Spacer()
            
            // UV Number
            Text("\(entry.uvIndex)")
                .font(.system(size: 56, weight: .bold))
                .tracking(-4)
                .foregroundColor(riskColor)
            
            Spacer()
            
            // Bottom Card
            if entry.isLow {
                LowUVCard()
            } else {
                TimerCard(entry: entry)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct LowUVCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("No cream needed")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(WidgetTheme.riskColor(1))
            Text("Check when heading outside")
                .font(.system(size: 9))
                .foregroundColor(WidgetColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(GlassCard(bgColor: WidgetColors.greenBg, borderColor: WidgetColors.greenBorder, cornerRadius: 10))
    }
}

struct TimerCard: View {
    let entry: UVWidgetEntry
    
    var body: some View {
        HStack(spacing: 8) {
            ShieldIcon()
            
            if entry.timerRunning, let end = entry.timerEndTime {
                Text(end, style: .timer)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(WidgetColors.textPrimary)
            } else {
                Text("--:--")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(WidgetColors.textPrimary)
            }
            
            Spacer()
            
            Text(timerLabel)
                .font(.system(size: 9))
                .foregroundColor(WidgetColors.textMuted)
        }
        .padding(10)
        .background(GlassCard(bgColor: WidgetColors.innerCardBg, borderColor: WidgetColors.innerCardBorder, cornerRadius: 10))
    }
    
    private var timerLabel: String {
        if !entry.timerRunning { return "Ready" }
        return entry.protectionStatus == "Expiring Soon" ? "Expiring" : "Active"
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: UVWidgetEntry
    let riskColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Left Column
            VStack(alignment: .leading, spacing: 8) {
                UVLabel()
                
                Spacer()
                
                // Ring with UV Number
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        .frame(width: 76, height: 76)
                    
                    Circle()
                        .trim(from: 0, to: min(Double(entry.uvIndex) / 11.0, 1.0))
                        .stroke(
                            LinearGradient(
                                colors: [riskColor.opacity(0.7), riskColor],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 76, height: 76)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(entry.uvIndex)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(riskColor)
                }
                
                Spacer()
                
                BurnTimeRow(burnTime: entry.burnTime, color: riskColor)
            }
            .frame(width: 95)
            
            // Right Panel
            if entry.isLow {
                MediumLowUVPanel(sessionsTotal: entry.sessionsTotal)
            } else {
                MediumActivePanel(entry: entry)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MediumLowUVPanel: View {
    let sessionsTotal: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatusPill(text: "UV is low", color: WidgetTheme.riskColor(1))
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("No cream needed")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(WidgetTheme.riskColor(1))
                Text("Check again when you head outside")
                    .font(.system(size: 10))
                    .foregroundColor(WidgetColors.textSecondary)
            }
            
            Spacer()
            
            Text("0 / \(sessionsTotal) Sessions")
                .font(.system(size: 9))
                .foregroundColor(WidgetColors.textMuted)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(GlassCard(bgColor: WidgetColors.greenBg, borderColor: WidgetColors.greenBorder, cornerRadius: 14))
    }
}

struct MediumActivePanel: View {
    let entry: UVWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatusPill(text: entry.protectionStatus, color: pillColor)
            
            Spacer()
            
            if entry.timerRunning, let end = entry.timerEndTime {
                Text(end, style: .timer)
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundColor(WidgetColors.textPrimary)
                    .tracking(-1)
            } else {
                Text("--:--:--")
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.25))
                    .tracking(-1)
            }
            
            Spacer()
            
            // Sessions Progress
            VStack(alignment: .leading, spacing: 5) {
                Text("\(entry.sessionsCompleted) / \(entry.sessionsTotal) Sessions")
                    .font(.system(size: 9))
                    .foregroundColor(WidgetColors.textSecondary)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.29, green: 0.87, blue: 0.50),
                                        Color(red: 0.13, green: 0.83, blue: 0.93)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geo.size.width * entry.sessionsFraction, 6), height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(GlassCard(bgColor: WidgetColors.innerCardBg, borderColor: WidgetColors.innerCardBorder, cornerRadius: 14))
    }
    
    private var pillColor: Color {
        switch entry.protectionStatus {
        case "Protected", "Done for today":
            return WidgetTheme.riskColor(1)
        default:
            return WidgetTheme.riskColor(8)
        }
    }
}

// MARK: - Widget Entry View

struct UVWidgetEntryView: View {
    var entry: UVWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        let riskColor = WidgetTheme.riskColor(entry.uvIndex)
        
        ZStack {
            // Glass Background Layer
            Color.white.opacity(0.08)
            
            // Glow Effect
            RadialGradient(
                gradient: Gradient(colors: [WidgetTheme.glowColor(entry.uvIndex), Color.clear]),
                center: family == .systemSmall ? .topLeading : .leading,
                startRadius: 0,
                endRadius: family == .systemSmall ? 80 : 100
            )
            
            // Subtle Glass Overlay
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.clear],
                startPoint: .topLeading,
                endPoint: .center
            )
            
            // Content
            if family == .systemSmall {
                SmallWidgetView(entry: entry, riskColor: riskColor)
            } else {
                MediumWidgetView(entry: entry, riskColor: riskColor)
            }
        }
    }
}

// MARK: - Widget

struct UVProtectorWidget: Widget {
    let kind = "UVProtectorWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UVWidgetProvider()) { entry in
            UVWidgetEntryView(entry: entry)
                .background(Color.white.opacity(0.08))
        }
        .configurationDisplayName("UV Protector")
        .description("Real-time UV index and SPF timer.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
