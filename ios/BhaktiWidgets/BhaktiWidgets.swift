import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BhaktiEntry {
        BhaktiEntry(date: Date(), title: "Gayatri Mantra", subtitle: "Om Bhur Bhuvaḥ Swaḥ", panchanga: "Daily Panchanga", isPlaying: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (BhaktiEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func getEntry() -> BhaktiEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.bhakti.bhakti")
        let title = userDefaults?.string(forKey: "widget_title") ?? "Gayatri Maha Mantra"
        let subtitle = userDefaults?.string(forKey: "widget_subtitle") ?? "Om Bhur Bhuvaḥ Swaḥ • Tat Savitur Vareṇyaṁ"
        let panchanga = userDefaults?.string(forKey: "widget_panchanga") ?? "Daily Vedic Panchanga"
        let isPlaying = userDefaults?.bool(forKey: "widget_is_playing") ?? false

        return BhaktiEntry(date: Date(), title: title, subtitle: subtitle, panchanga: panchanga, isPlaying: isPlaying)
    }
}

struct BhaktiEntry: TimelineEntry {
    let date: Date
    let title: String
    let subtitle: String
    let panchanga: String
    let isPlaying: Bool
}

struct BhaktiWidgetsEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Sacred Deep Maroon to Gold Gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.35, green: 0.05, blue: 0.10),
                    Color(red: 0.18, green: 0.02, blue: 0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 6) {
                // Top Header: 🕉️ BHAKTI & Panchanga badge
                HStack {
                    Text("🕉️ BHAKTI")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.80, blue: 0.40))
                        .tracking(1.0)
                    Spacer()
                    if family != .systemSmall {
                        Text(entry.panchanga)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.75))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Center / Title
                Text(entry.title)
                    .font(.system(size: family == .systemSmall ? 14 : 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(entry.subtitle)
                    .font(.system(size: family == .systemSmall ? 11 : 12, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.8))
                    .lineLimit(family == .systemSmall ? 2 : 2)

                Spacer()

                // Bottom Status
                HStack {
                    Image(systemName: entry.isPlaying ? "waveform" : "sun.max.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.95, green: 0.80, blue: 0.40))
                    Text(entry.isPlaying ? "Now Playing" : "Daily Sacred Chant")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(red: 0.95, green: 0.80, blue: 0.40))
                }
            }
            .padding(14)
        }
        .applyWidgetBackground()
    }
}

extension View {
    @ViewBuilder
    func applyWidgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                Color(red: 0.25, green: 0.03, blue: 0.08)
            }
        } else {
            self.background(Color(red: 0.25, green: 0.03, blue: 0.08))
        }
    }
}

@main
struct BhaktiWidgets: Widget {
    let kind: String = "BhaktiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BhaktiWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Bhakti Sacred Widget")
        .description("Daily Shloka of the Day, Vedic Panchanga, and Now Playing Chants.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
