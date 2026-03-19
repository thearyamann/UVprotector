import WidgetKit
import SwiftUI

// MARK: - THEME COLORS & HELPERS
struct WidgetTheme {
    static let baseBg = Color(red: 10/255, green: 10/255, blue: 10/255) // #0a0a0a
    
    static func riskColor(for index: Int) -> Color {
        if index >= 8 { return Color(red: 248/255, green: 113/255, blue: 113/255) } // Red
        if index >= 6 { return Color(red: 249/255, green: 115/255, blue: 22/255) } // Orange
        if index >= 3 { return Color(red: 251/255, green: 191/255, blue: 36/255) } // Amber
        return Color(red: 74/255, green: 222/255, blue: 128/255) // Green
    }
    
    static func glowColor(for index: Int) -> Color {
        if index >= 8 { return Color(red: 220/255, green: 38/255, blue: 38/255).opacity(0.35) }
        if index >= 6 { return Color(red: 234/255, green: 88/255, blue: 12/255).opacity(0.35) }
        if index >= 3 { return Color(red: 217/255, green: 119/255, blue: 6/255).opacity(0.30) }
        return Color(red: 22/255, green: 163/255, blue: 74/255).opacity(0.28)
    }
    
    static func pillStyle(for index: Int) -> (bg: Color, text: Color, border: Color) {
        if index >= 8 {
            return (Color(red: 220/255, green: 38/255, blue: 38/255).opacity(0.22), riskColor(for: index), Color(red: 220/255, green: 38/255, blue: 38/255).opacity(0.4))
        } else if index >= 6 {
             return (Color(red: 234/255, green: 88/255, blue: 12/255).opacity(0.22), riskColor(for: index), Color(red: 234/255, green: 88/255, blue: 12/255).opacity(0.4))
        } else if index >= 3 {
            return (Color(red: 217/255, green: 119/255, blue: 6/255).opacity(0.22), riskColor(for: index), Color(red: 217/255, green: 119/255, blue: 6/255).opacity(0.4))
        }
        return (Color(red: 22/255, green: 163/255, blue: 74/255).opacity(0.22), riskColor(for: index), Color(red: 22/255, green: 163/255, blue: 74/255).opacity(0.4))
    }
    
    static func pillStyle(isGood: Bool) -> (bg: Color, text: Color, border: Color) {
        if isGood {
             return (Color(red: 22/255, green: 163/255, blue: 74/255).opacity(0.22), Color(red: 74/255, green: 222/255, blue: 128/255), Color(red: 22/255, green: 163/255, blue: 74/255).opacity(0.4))
        } else {
            return (Color(red: 220/255, green: 38/255, blue: 38/255).opacity(0.22), Color(red: 248/255, green: 113/255, blue: 113/255), Color(red: 220/255, green: 38/255, blue: 38/255).opacity(0.4))
        }
    }
}

// MARK: - COMPONENTS
struct StatusPill: View {
    let text: String
    let style: (bg: Color, text: Color, border: Color)
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(style.text)
                .frame(width: 5, height: 5)
            
            Text(text.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundColor(style.text)
        }
        .padding(.vertical, 3)
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .background(style.bg)
        .overlay(
            RoundedRectangle(cornerRadius: 100)
                .stroke(style.border, lineWidth: 1)
        )
        .cornerRadius(100)
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct CircularProgressRing: View {
    let uvIndex: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 5)
                .rotationEffect(.degrees(-90))
            
            // Map 0-11 to 0-1
            let progress = min(Double(uvIndex) / 11.0, 1.0)
            
            // Gradient based on risk
            let riskColor = WidgetTheme.riskColor(for: uvIndex)
            let startColor = WidgetTheme.riskColor(for: max(0, uvIndex - 2))
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(LinearGradient(colors: [startColor, riskColor], startPoint: .top, endPoint: .bottom), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text(String(uvIndex))
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(riskColor)
        }
        .frame(width: 72, height: 72)
    }
}


// MARK: - WIDGET PROVIDER
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), uvIndex: 6, uvStatus: "High", burnTime: "11", timerRunning: true, timerEndTime: Date().addingTimeInterval(3600), sessionsCompleted: 1, sessionsTotal: 3, protectionStatus: "Protected", isLowUv: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        // Timeline expires every hour, but Flutter background task updates it more frequently.
        completion(Timeline(entries: [loadEntry()], policy: .atEnd))
    }
    
    private func loadEntry() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.thearyamann.uvprotector")
        let uvIndex = userDefaults?.integer(forKey: "uv_index") ?? 0
        let uvStatus = userDefaults?.string(forKey: "uv_status") ?? "Low"
        let burnTime = userDefaults?.string(forKey: "burn_time") ?? "0"
        let timerRunning = userDefaults?.bool(forKey: "timer_running") ?? false
        let timerEndMs = userDefaults?.integer(forKey: "timer_end_time") ?? 0
        let sessionsCompleted = userDefaults?.integer(forKey: "sessions_completed") ?? 0
        let sessionsTotal = userDefaults?.integer(forKey: "sessions_total") ?? 0
        let protectionStatus = userDefaults?.string(forKey: "protection_status") ?? "Unprotected"
        let isLowUv = userDefaults?.bool(forKey: "is_low_uv") ?? false
        
        var timerEndTime: Date? = nil
        if timerEndMs > 0 { timerEndTime = Date(timeIntervalSince1970: Double(timerEndMs) / 1000.0) }
        
        return SimpleEntry(date: Date(), uvIndex: uvIndex, uvStatus: uvStatus, burnTime: burnTime, timerRunning: timerRunning, timerEndTime: timerEndTime, sessionsCompleted: sessionsCompleted, sessionsTotal: sessionsTotal, protectionStatus: protectionStatus, isLowUv: isLowUv)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let uvIndex: Int
    let uvStatus: String
    let burnTime: String
    let timerRunning: Bool
    let timerEndTime: Date?
    let sessionsCompleted: Int
    let sessionsTotal: Int
    let protectionStatus: String
    let isLowUv: Bool
}

// MARK: - WIDGET VIEWS
struct SmallWidgetLayout: View {
    var entry: SimpleEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Row
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "sun.max")
                    .resizable()
                    .frame(width: 14, height: 14)
                    .foregroundColor(Color.white.opacity(0.7))
                
                Text("UV")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(Color.white.opacity(0.3))
                
                Spacer()
                
                StatusPill(text: entry.uvStatus, style: WidgetTheme.pillStyle(for: entry.uvIndex))
            }
            
            Spacer()
            
            // Middle
            Text(String(entry.uvIndex))
                .font(.system(size: 52, weight: .bold))
                .tracking(-3)
                .foregroundColor(WidgetTheme.riskColor(for: entry.uvIndex))
            
            Spacer()
            
            // Bottom Card
            bottomCard
        }
        .padding(14)
    }
    
    @ViewBuilder
    var bottomCard: some View {
        if entry.isLowUv {
            VStack(alignment: .leading, spacing: 2) {
                Text("No cream needed")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(red: 74/255, green: 222/255, blue: 128/255))
                Text("Check when heading outside")
                    .font(.system(size: 8))
                    .foregroundColor(Color.white.opacity(0.38))
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 74/255, green: 222/255, blue: 128/255).opacity(0.07))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 74/255, green: 222/255, blue: 128/255).opacity(0.2), lineWidth: 0.5))
            .cornerRadius(10)
        } else {
            HStack(spacing: 6) {
                Image(systemName: "star.shield.fill")
                    .resizable()
                    .frame(width: 10, height: 10)
                    .foregroundColor(.white)
                
                if entry.timerRunning, let endTime = entry.timerEndTime {
                    Text(endTime, style: .timer)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .minimumScaleFactor(0.8)
                        .foregroundColor(.white)
                        .layoutPriority(1)
                    Spacer()
                    Text("Active")
                        .font(.system(size: 9))
                        .foregroundColor(Color.white.opacity(0.5))
                } else {
                    Text("--:--")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Text("Ready")
                        .font(.system(size: 9))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(Color.white.opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
            .cornerRadius(10)
        }
    }
}

struct MediumWidgetLayout: View {
    var entry: SimpleEntry
    
    var body: some View {
        HStack(spacing: 14) {
            // Left Column
            VStack(alignment: .leading, spacing: 0) {
                Text("UV INDEX")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(Color.white.opacity(0.32))
                
                Spacer()
                
                HStack {
                    Spacer()
                    CircularProgressRing(uvIndex: entry.uvIndex)
                    Spacer()
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .resizable()
                        .frame(width: 8, height: 10)
                        .foregroundColor(Color.white.opacity(0.55))
                    
                    Text("Burn in ")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.55))
                        + Text("\(entry.burnTime) mins")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(WidgetTheme.riskColor(for: entry.uvIndex))
                }
            }
            .frame(width: 110)
            
            // Right Column Card
            rightCard
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    var rightCard: some View {
        if entry.isLowUv {
            lowUvCard
        } else {
            activeProtectionCard
        }
    }
    
    var activeProtectionCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                let isGood = entry.protectionStatus.lowercased() == "protected" || entry.protectionStatus.lowercased().contains("done")
                StatusPill(text: entry.protectionStatus, style: WidgetTheme.pillStyle(isGood: isGood))
                Spacer()
            }
            
            Spacer()
            
            if entry.timerRunning, let endTime = entry.timerEndTime {
                Text(endTime, style: .timer)
                    .font(.system(size: 26, weight: .medium, design: .monospaced))
                    .tracking(-1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(Color.white.opacity(0.92))
            } else {
                Text("--:--:--")
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .tracking(-1)
                    .foregroundColor(Color.white.opacity(0.3))
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.sessionsCompleted) / \(entry.sessionsTotal) Sessions")
                    .font(.system(size: 9))
                    .foregroundColor(Color.white.opacity(0.5))
                    
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1)).frame(height: 3)
                        
                        let total = entry.sessionsTotal > 0 ? entry.sessionsTotal : 1
                        let progress = CGFloat(entry.sessionsCompleted) / CGFloat(total)
                        
                        Capsule()
                            .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 74/255, green: 222/255, blue: 128/255), Color(red: 34/255, green: 211/255, blue: 238/255)]), startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, min(geometry.size.width * progress, geometry.size.width)), height: 3)
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        .cornerRadius(14)
    }
    
    var lowUvCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                StatusPill(text: "UV IS LOW", style: WidgetTheme.pillStyle(isGood: true))
                Spacer()
            }
            
            Spacer()
            
            Text("No cream needed at the moment")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 74/255, green: 222/255, blue: 128/255))
                .fixedSize(horizontal: false, vertical: true)
            
            Text("Check again when you head outside")
                .font(.system(size: 10))
                .foregroundColor(Color.white.opacity(0.42))
                .padding(.top, 2)
            
            Spacer()
            
            Text("\(entry.sessionsCompleted) / \(entry.sessionsTotal) Sessions")
                .font(.system(size: 9))
                .foregroundColor(Color.white.opacity(0.25))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(red: 74/255, green: 222/255, blue: 128/255).opacity(0.06))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(red: 74/255, green: 222/255, blue: 128/255).opacity(0.18), lineWidth: 0.5))
        .cornerRadius(14)
    }
}

struct UVWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            if family == .systemSmall {
                SmallWidgetLayout(entry: entry)
            } else {
                MediumWidgetLayout(entry: entry)
            }
            
            // Top left glass sheen overlay (linear gradient)
            GeometryReader { geo in
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.07), Color.clear]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .mask(Rectangle().padding(.trailing, geo.size.width * 0.5))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground(
            ZStack {
                WidgetTheme.baseBg
                
                // Active Radial Glow
                GeometryReader { geo in
                    RadialGradient(
                        gradient: Gradient(colors: [WidgetTheme.glowColor(for: entry.uvIndex), Color.clear]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: family == .systemSmall ? geo.size.width * 1.5 : geo.size.width * 0.8
                    )
                }
                
                if #available(iOS 15.0, *) {
                    Rectangle().fill(.ultraThinMaterial)
                } else {
                    Rectangle().fill(Color.white.opacity(0.1))
                }
                
                // Extra faint white overlay matching prompt
                Rectangle().fill(Color.white.opacity(0.055))
            }
        )
    }
}

extension View {
    @ViewBuilder
    func widgetBackground<T: View>(_ backgroundView: T) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            self.background(backgroundView.edgesIgnoringSafeArea(.all))
        }
    }
}

struct UVWidget: Widget {
    let kind: String = "UVWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            UVWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("UV Protector")
        .description("Stay safe with real-time UV and SPF monitoring.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
