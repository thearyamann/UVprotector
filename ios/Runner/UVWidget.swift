import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), uvIndex: 0, uvStatus: "Low", burnTime: "--", timerRunning: false, timerEndTime: nil, sessionsText: "0/0", protectionStatus: "Not Applied")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
    
    private func loadEntry() -> SimpleEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.thearyamann.uvprotector")
        let uvIndex = userDefaults?.integer(forKey: "uv_index") ?? 0
        let uvStatus = userDefaults?.string(forKey: "uv_status") ?? "Low"
        let burnTime = userDefaults?.string(forKey: "burn_time") ?? "--"
        let timerRunning = userDefaults?.bool(forKey: "timer_running") ?? false
        let timerEndMs = userDefaults?.integer(forKey: "timer_end_time") ?? 0
        let sessionsText = userDefaults?.string(forKey: "sessions_text") ?? "0/0"
        let protectionStatus = userDefaults?.string(forKey: "protection_status") ?? "Not Applied"
        
        var timerEndTime: Date? = nil
        if timerEndMs > 0 {
            timerEndTime = Date(timeIntervalSince1970: Double(timerEndMs) / 1000.0)
        }
        
        return SimpleEntry(
            date: Date(),
            uvIndex: uvIndex,
            uvStatus: uvStatus,
            burnTime: burnTime,
            timerRunning: timerRunning,
            timerEndTime: timerEndTime,
            sessionsText: sessionsText,
            protectionStatus: protectionStatus
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let uvIndex: Int
    let uvStatus: String
    let burnTime: String
    let timerRunning: Bool
    let timerEndTime: Date?
    let sessionsText: String
    let protectionStatus: String
}

struct UVWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if family == .systemSmall {
                smallLayout
            } else {
                mediumLayout
            }
        }
        .padding()
        .foregroundColor(.white)
        .containerBackground(for: .widget) {
            ZStack {
                Color.black.opacity(0.85)
                Rectangle().fill(.ultraThinMaterial)
            }
        }
    }
    
    var smallLayout: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(String(entry.uvIndex))
                .font(.system(size: 32, weight: .bold))
            Text(entry.uvStatus.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(colorForUV(entry.uvIndex))
            
            Divider().background(Color.white.opacity(0.1))
            
            Text(entry.timerRunning ? "Active" : "Ready")
                .font(.system(size: 12, weight: .medium))
        }
    }
    
    var mediumLayout: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("UV INDEX")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                Text(String(entry.uvIndex))
                    .font(.system(size: 44, weight: .bold))
                Text(entry.uvStatus)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(colorForUV(entry.uvIndex))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.protectionStatus)
                    .font(.system(size: 14, weight: .bold))
                
                if entry.timerRunning, let endTime = entry.timerEndTime {
                    Text(endTime, style: .timer)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    Text("--:--")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Text(entry.sessionsText + " Sessions")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                
                Text("Burn in " + entry.burnTime)
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
        }
    }
    
    func colorForUV(_ index: Int) -> Color {
        if index >= 8 { return .red }
        if index >= 6 { return .orange }
        if index >= 3 { return .yellow }
        return .green
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
