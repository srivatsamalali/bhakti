import WidgetKit
import SwiftUI
import AppIntents
import AVFoundation

// MARK: - Dynamic Data Models

struct BhaktiTrack: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let duration: String
    let category: String
    let emoji: String
    let audioUrl: String?

    init(id: String, title: String, subtitle: String, duration: String, category: String, emoji: String, audioUrl: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.duration = duration
        self.category = category
        self.emoji = emoji
        self.audioUrl = audioUrl
    }
}

struct BhaktiData {
    static let defaultCategories = ["All", "Sahasranamam", "Daily Chants", "Meditation"]

    static let defaultAllTracks: [BhaktiTrack] = [
        BhaktiTrack(
            id: "lalitha_sahasranamam",
            title: "Sri Lalitha Sahasranama",
            subtitle: "Goddess Lalitha",
            duration: "29:39",
            category: "Sahasranamam",
            emoji: "🌺",
            audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3"
        ),
        BhaktiTrack(
            id: "govinda_namavali",
            title: "Sri Govinda Namavali",
            subtitle: "Lord Venkateswara",
            duration: "22:37",
            category: "Meditation",
            emoji: "👑",
            audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3"
        ),
        BhaktiTrack(
            id: "hanuman_chalisa",
            title: "Hanuman Chalisa",
            subtitle: "God Hanuman",
            duration: "09:41",
            category: "Daily Chants",
            emoji: "🚩",
            audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3"
        ),
        BhaktiTrack(
            id: "gayathri_mantra",
            title: "Gayathri mantra",
            subtitle: "Goddess Gayathri",
            duration: "00:35",
            category: "Daily Chants",
            emoji: "🪷",
            audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
        )
    ]

    static func getCategories() -> [String] {
        let userDefaults = UserDefaults(suiteName: "group.com.bhakti.bhakti")
        if let jsonString = userDefaults?.string(forKey: "widget_categories_json"),
           let jsonData = jsonString.data(using: .utf8) {
            do {
                let cats = try JSONDecoder().decode([String].self, from: jsonData)
                if !cats.isEmpty {
                    return Array(cats.prefix(4))
                }
            } catch {}
        }
        return defaultCategories
    }

    static func getAllSongs() -> [BhaktiTrack] {
        let userDefaults = UserDefaults(suiteName: "group.com.bhakti.bhakti")
        if let jsonString = userDefaults?.string(forKey: "widget_songs_json"),
           let jsonData = jsonString.data(using: .utf8) {
            do {
                let allSongs = try JSONDecoder().decode([BhaktiTrack].self, from: jsonData)
                if !allSongs.isEmpty {
                    return allSongs
                }
            } catch {}
        }
        return defaultAllTracks
    }

    static func getSongs(for category: String) -> [BhaktiTrack] {
        let allSongs = getAllSongs()
        if category.lowercased() == "all" {
            return Array(allSongs.prefix(4))
        }

        let catLow = category.lowercased()
        let filtered = allSongs.filter { song in
            let c = song.category.lowercased()
            if c == catLow { return true }
            if catLow == "sahasranamam" && (c.contains("sahasranama") || song.title.lowercased().contains("sahasranama")) { return true }
            if catLow.contains("daily") && (c.contains("daily") || c.contains("mantra") || c.contains("chalisa") || song.title.lowercased().contains("gayatri") || song.title.lowercased().contains("gayathri")) { return true }
            if catLow.contains("meditation") && (c.contains("meditation") || c.contains("stotra") || song.title.lowercased().contains("govinda")) { return true }
            return false
        }

        if !filtered.isEmpty {
            return Array(filtered.prefix(4))
        }
        return Array(allSongs.prefix(4))
    }
}

// MARK: - Native Audio Player Engine for Widget

final class BhaktiAudioPlayer {
    static let shared = BhaktiAudioPlayer()
    private var player: AVPlayer?

    private init() {}

    func play(track: BhaktiTrack) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session configuration error: \(error)")
        }

        let urlString = track.audioUrl ?? "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
        guard let url = URL(string: urlString) else { return }

        let playerItem = AVPlayerItem(url: url)
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
        player?.play()
    }
}

// MARK: - Zero-App-Launch In-Widget Interactive Audio Playback App Intents

@available(iOS 17.0, *)
struct BhaktiTogglePlayIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Toggle Play/Pause"
    static var description = IntentDescription("Toggles playback state directly inside widget without opening app")
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let userDefaults = UserDefaults(suiteName: "group.com.bhakti.bhakti")
        let isPlaying = userDefaults?.bool(forKey: "widget_is_playing") ?? false
        let newPlayingState = !isPlaying
        userDefaults?.set(newPlayingState, forKey: "widget_is_playing")

        let songId = userDefaults?.string(forKey: "widget_active_song_id") ?? ""
        let songs = BhaktiData.getAllSongs()
        if let current = songs.first(where: { $0.id == songId }) ?? songs.first {
            if newPlayingState {
                BhaktiAudioPlayer.shared.play(track: current)
            } else {
                BhaktiAudioPlayer.shared.pause()
            }
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "BhaktiWidget")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

@available(iOS 17.0, *)
struct BhaktiSelectSongIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Select Song"
    static var description = IntentDescription("Switches active song directly inside widget and plays without opening app")
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Song ID")
    var songId: String

    @Parameter(title: "Category")
    var category: String

    init() {
        self.songId = "lalitha_sahasranamam"
        self.category = "All"
    }

    init(songId: String, category: String) {
        self.songId = songId
        self.category = category
    }

    static func selectAndPlay(songId: String, category: String) {
        let userDefaults = UserDefaults(suiteName: "group.com.bhakti.bhakti")
        let allSongs = BhaktiData.getAllSongs()
        if let selected = allSongs.first(where: { $0.id == songId }) {
            userDefaults?.set(selected.id, forKey: "widget_active_song_id")
            userDefaults?.set(selected.title, forKey: "widget_title")
            userDefaults?.set(selected.subtitle, forKey: "widget_subtitle")
            userDefaults?.set(selected.duration, forKey: "widget_duration")
            userDefaults?.set(selected.emoji, forKey: "widget_emoji")
            userDefaults?.set(category, forKey: "widget_active_category")
            userDefaults?.set(true, forKey: "widget_is_playing")

            BhaktiAudioPlayer.shared.play(track: selected)
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "BhaktiWidget")
        WidgetCenter.shared.reloadAllTimelines()
    }

    func perform() async throws -> some IntentResult {
        BhaktiSelectSongIntent.selectAndPlay(songId: songId, category: category)
        return .result()
    }
}

@available(iOS 17.0, *)
struct BhaktiNextIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Next Song"
    static var description = IntentDescription("Plays next track directly in widget without opening app")
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let userDefaults = UserDefaults(suiteName: "group.com.bhakti.bhakti")
        let activeCategory = userDefaults?.string(forKey: "widget_active_category") ?? "All"
        let currentId = userDefaults?.string(forKey: "widget_active_song_id") ?? ""
        let playlist = BhaktiData.getSongs(for: activeCategory)

        var nextIndex = 0
        if let idx = playlist.firstIndex(where: { $0.id == currentId }) {
            nextIndex = (idx + 1) % playlist.count
        }
        if nextIndex < playlist.count {
            BhaktiSelectSongIntent.selectAndPlay(songId: playlist[nextIndex].id, category: activeCategory)
        }
        return .result()
    }
}

@available(iOS 17.0, *)
struct BhaktiPrevIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Previous Song"
    static var description = IntentDescription("Plays previous track directly in widget without opening app")
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let userDefaults = UserDefaults(suiteName: "group.com.bhakti.bhakti")
        let activeCategory = userDefaults?.string(forKey: "widget_active_category") ?? "All"
        let currentId = userDefaults?.string(forKey: "widget_active_song_id") ?? ""
        let playlist = BhaktiData.getSongs(for: activeCategory)

        var prevIndex = 0
        if let idx = playlist.firstIndex(where: { $0.id == currentId }) {
            prevIndex = (idx - 1 + playlist.count) % playlist.count
        }
        if prevIndex < playlist.count {
            BhaktiSelectSongIntent.selectAndPlay(songId: playlist[prevIndex].id, category: activeCategory)
        }
        return .result()
    }
}

@available(iOS 16.0, *)
struct BhaktiSelectCategoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Category Tab"
    static var description = IntentDescription("Switches category tab directly in widget without opening app")
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Category")
    var category: String

    init() {
        self.category = "All"
    }

    init(category: String) {
        self.category = category
    }

    func perform() async throws -> some IntentResult {
        let userDefaults = UserDefaults(suiteName: "group.com.bhakti.bhakti")
        userDefaults?.set(category, forKey: "widget_active_category")
        userDefaults?.set(0, forKey: "widget_active_index")

        let songs = BhaktiData.getSongs(for: category)
        if let first = songs.first {
            userDefaults?.set(first.title, forKey: "widget_title")
            userDefaults?.set(first.subtitle, forKey: "widget_subtitle")
            userDefaults?.set(first.duration, forKey: "widget_duration")
            userDefaults?.set(first.emoji, forKey: "widget_emoji")
            userDefaults?.set(first.id, forKey: "widget_active_song_id")
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "BhaktiWidget")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

@available(iOS 16.0, *)
struct BhaktiToggleFavIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Favorite"
    static var description = IntentDescription("Toggles favorite status in widget without opening app")
    static var isDiscoverable: Bool = false
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        let userDefaults = UserDefaults(suiteName: "group.com.bhakti.bhakti")
        let isFav = userDefaults?.bool(forKey: "widget_is_favorite") ?? false
        userDefaults?.set(!isFav, forKey: "widget_is_favorite")
        WidgetCenter.shared.reloadTimelines(ofKind: "BhaktiWidget")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BhaktiEntry {
        let allSongs = BhaktiData.getAllSongs()
        let first = allSongs.first ?? BhaktiData.defaultAllTracks[0]
        return BhaktiEntry(
            date: Date(),
            songId: first.id,
            title: first.title,
            subtitle: first.subtitle,
            duration: first.duration,
            currentTime: "01:24",
            emoji: first.emoji,
            isPlaying: true,
            isFavorite: true,
            activeIndex: 0,
            activeCategory: "All"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BhaktiEntry) -> ()) {
        completion(getEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func getEntry() -> BhaktiEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.bhakti.bhakti")
        let activeCategory = userDefaults?.string(forKey: "widget_active_category") ?? "All"
        let activeIndex = userDefaults?.integer(forKey: "widget_active_index") ?? 0
        let songs = BhaktiData.getSongs(for: activeCategory)
        let fallbackTrack = (activeIndex < songs.count) ? songs[activeIndex] : (songs.first ?? BhaktiData.defaultAllTracks[0])

        let songId = userDefaults?.string(forKey: "widget_active_song_id") ?? fallbackTrack.id
        let title = userDefaults?.string(forKey: "widget_title") ?? fallbackTrack.title
        let subtitle = userDefaults?.string(forKey: "widget_subtitle") ?? fallbackTrack.subtitle
        let duration = userDefaults?.string(forKey: "widget_duration") ?? fallbackTrack.duration
        let emoji = userDefaults?.string(forKey: "widget_emoji") ?? fallbackTrack.emoji
        let currentTime = userDefaults?.string(forKey: "widget_current_time") ?? "01:24"
        let isPlaying = userDefaults?.bool(forKey: "widget_is_playing") ?? true
        let isFavorite = userDefaults?.bool(forKey: "widget_is_favorite") ?? true

        return BhaktiEntry(
            date: Date(),
            songId: songId,
            title: title,
            subtitle: subtitle,
            duration: duration,
            currentTime: currentTime,
            emoji: emoji,
            isPlaying: isPlaying,
            isFavorite: isFavorite,
            activeIndex: activeIndex,
            activeCategory: activeCategory
        )
    }
}

struct BhaktiEntry: TimelineEntry {
    let date: Date
    let songId: String
    let title: String
    let subtitle: String
    let duration: String
    let currentTime: String
    let emoji: String
    let isPlaying: Bool
    let isFavorite: Bool
    let activeIndex: Int
    let activeCategory: String
}

// MARK: - Medium Narrow Horizontal Widget View

struct BhaktiWidgetsEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        let dynamicCategories = BhaktiData.getCategories()
        let currentPlaylist = BhaktiData.getSongs(for: entry.activeCategory)

        ZStack {
            // Sacred Deep Maroon Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.36, green: 0.04, blue: 0.10),
                    Color(red: 0.20, green: 0.02, blue: 0.05),
                    Color(red: 0.10, green: 0.01, blue: 0.02)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 7) {
                // ==================== LEFT CARD: MUSIC PLAYER ====================
                VStack(alignment: .leading, spacing: 5) {
                    // Header: 🕉️ BHAKTI & Heart Favorite Icon
                    HStack {
                        HStack(spacing: 3) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.58, green: 0.12, blue: 0.68))
                                    .frame(width: 14, height: 14)
                                Text("ॐ")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Text("BHAKTI")
                                .font(.system(size: 9.5, weight: .black))
                                .foregroundColor(Color(red: 0.98, green: 0.82, blue: 0.45))
                                .tracking(1.1)
                        }

                        Spacer()

                        // Favorite Heart Button (Zero App Launch)
                        if #available(iOS 17.0, *) {
                            Button(intent: BhaktiToggleFavIntent()) {
                                Image(systemName: entry.isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundColor(entry.isFavorite ? Color(red: 0.95, green: 0.22, blue: 0.28) : .white.opacity(0.6))
                                    .frame(width: 20, height: 20)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        } else {
                            Image(systemName: entry.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(entry.isFavorite ? Color(red: 0.95, green: 0.22, blue: 0.28) : .white.opacity(0.6))
                        }
                    }

                    // Album Art & Song Info (Zero App Launch)
                    if #available(iOS 17.0, *) {
                        Button(intent: BhaktiTogglePlayIntent()) {
                            albumArtAndTitleView()
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        albumArtAndTitleView()
                    }

                    // Progress Bar
                    VStack(spacing: 1) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.20))
                                    .frame(height: 2.5)

                                Capsule()
                                    .fill(Color(red: 0.98, green: 0.82, blue: 0.45))
                                    .frame(width: geo.size.width * 0.36, height: 2.5)

                                Circle()
                                    .fill(Color(red: 0.98, green: 0.82, blue: 0.45))
                                    .frame(width: 5.5, height: 5.5)
                                    .offset(x: (geo.size.width * 0.36) - 2.75)
                                    .shadow(color: Color(red: 0.98, green: 0.82, blue: 0.45), radius: 2)
                            }
                        }
                        .frame(height: 5.5)

                        HStack {
                            Text(entry.currentTime)
                                .font(.system(size: 7.5, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.60))
                            Spacer()
                            Text(entry.duration)
                                .font(.system(size: 7.5, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.60))
                        }
                    }

                    // Playback Controls Row: Shuffle | Prev | Play/Pause | Next | Repeat (All in-widget)
                    HStack {
                        Image(systemName: "shuffle")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.65))

                        Spacer()

                        if #available(iOS 17.0, *) {
                            Button(intent: BhaktiPrevIntent()) {
                                Image(systemName: "backward.end.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 22, height: 22)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        } else {
                            Image(systemName: "backward.end.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        // Play/Pause Circular Button (Zero App Launch)
                        if #available(iOS 17.0, *) {
                            Button(intent: BhaktiTogglePlayIntent()) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.98, green: 0.85, blue: 0.45),
                                                    Color(red: 0.88, green: 0.68, blue: 0.28)
                                                ]),
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 26, height: 26)
                                        .shadow(color: Color(red: 0.98, green: 0.82, blue: 0.45).opacity(0.4), radius: 3)

                                    Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundColor(Color(red: 0.28, green: 0.04, blue: 0.08))
                                }
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.98, green: 0.85, blue: 0.45))
                                    .frame(width: 26, height: 26)
                                Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(Color(red: 0.28, green: 0.04, blue: 0.08))
                            }
                        }

                        Spacer()

                        if #available(iOS 17.0, *) {
                            Button(intent: BhaktiNextIntent()) {
                                Image(systemName: "forward.end.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 22, height: 22)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        } else {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Image(systemName: "repeat")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.65))
                    }
                }
                .padding(7)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 13)
                        .fill(Color.black.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 13)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )

                // ==================== RIGHT CARD: SACRED PLAYLIST ====================
                VStack(alignment: .leading, spacing: 3.5) {
                    // Category Tabs Row: All | Sahasranamam | Daily Chants | Meditation
                    HStack(spacing: 2.5) {
                        ForEach(dynamicCategories, id: \.self) { cat in
                            let isSelected = (cat == entry.activeCategory)
                            if #available(iOS 17.0, *) {
                                Button(intent: BhaktiSelectCategoryIntent(category: cat)) {
                                    Text(cat)
                                        .font(.system(size: 7.2, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? Color(red: 0.28, green: 0.04, blue: 0.08) : Color.white.opacity(0.80))
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(isSelected ? Color(red: 0.98, green: 0.82, blue: 0.45) : Color.clear)
                                        )
                                        .contentShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text(cat)
                                    .font(.system(size: 7.2, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? Color(red: 0.28, green: 0.04, blue: 0.08) : Color.white.opacity(0.80))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? Color(red: 0.98, green: 0.82, blue: 0.45) : Color.clear)
                                    )
                            }
                        }
                    }

                    // 4 Songs List from Dynamic Playlist (Clicking directly plays without opening app)
                    VStack(spacing: 2.5) {
                        ForEach(0..<currentPlaylist.count, id: \.self) { index in
                            let track = currentPlaylist[index]
                            let isActive = (track.id == entry.songId || index == entry.activeIndex)

                            if #available(iOS 17.0, *) {
                                Button(intent: BhaktiSelectSongIntent(songId: track.id, category: entry.activeCategory)) {
                                    songRow(track: track, isActive: isActive, isPlaying: entry.isPlaying)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            } else {
                                songRow(track: track, isActive: isActive, isPlaying: entry.isPlaying)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
            }
            .padding(7)
        }
        .unredacted()
        .applyWidgetBackground()
    }

    @ViewBuilder
    private func albumArtAndTitleView() -> some View {
        HStack(spacing: 6) {
            // Glowing Golden Album Art
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.55, green: 0.28, blue: 0.05),
                                Color(red: 0.22, green: 0.08, blue: 0.02)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color(red: 0.98, green: 0.82, blue: 0.45), lineWidth: 1)
                    )
                    .shadow(color: Color(red: 0.98, green: 0.82, blue: 0.45).opacity(0.30), radius: 3)

                VStack(spacing: -2) {
                    Text("ॐ")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(red: 0.98, green: 0.85, blue: 0.45))
                    Text(entry.emoji)
                        .font(.system(size: 9))
                }
            }

            // Title & Subtitle
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.title)
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(entry.subtitle)
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.70))
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private func songRow(track: BhaktiTrack, isActive: Bool, isPlaying: Bool) -> some View {
        HStack(spacing: 4) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        isActive
                            ? Color(red: 0.65, green: 0.35, blue: 0.05)
                            : Color.white.opacity(0.12)
                    )
                    .frame(width: 18, height: 18)
                Text(track.emoji)
                    .font(.system(size: 10))
            }

            // Title & Subtitle
            VStack(alignment: .leading, spacing: 0) {
                Text(track.title)
                    .font(.system(size: 8.5, weight: isActive ? .bold : .semibold))
                    .foregroundColor(isActive ? Color(red: 0.98, green: 0.85, blue: 0.45) : .white)
                    .lineLimit(1)

                Text(track.subtitle)
                    .font(.system(size: 7, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.60))
                    .lineLimit(1)
            }

            Spacer(minLength: 2)

            // Equalizer or Play Circle
            if isActive && isPlaying {
                HStack(spacing: 1.2) {
                    RoundedRectangle(cornerRadius: 1).fill(Color(red: 0.98, green: 0.82, blue: 0.45)).frame(width: 1.6, height: 5.5)
                    RoundedRectangle(cornerRadius: 1).fill(Color(red: 0.98, green: 0.82, blue: 0.45)).frame(width: 1.6, height: 9.5)
                    RoundedRectangle(cornerRadius: 1).fill(Color(red: 0.98, green: 0.82, blue: 0.45)).frame(width: 1.6, height: 4.5)
                }
                .padding(.trailing, 1)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 14, height: 14)
                    Image(systemName: "play.fill")
                        .font(.system(size: 6))
                        .foregroundColor(.white)
                }
            }

            // 3-dots
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .font(.system(size: 6.5))
                .foregroundColor(Color.white.opacity(0.35))
        }
        .padding(.horizontal, 4.5)
        .padding(.vertical, 2.2)
        .background(
            RoundedRectangle(cornerRadius: 5.5)
                .fill(isActive ? Color(red: 0.98, green: 0.82, blue: 0.45).opacity(0.18) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 5.5)
                        .stroke(isActive ? Color(red: 0.98, green: 0.82, blue: 0.45).opacity(0.35) : Color.clear, lineWidth: 0.8)
                )
        )
    }
}

extension View {
    @ViewBuilder
    func applyWidgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) {
                Color(red: 0.28, green: 0.04, blue: 0.08)
            }
        } else {
            self.background(Color(red: 0.28, green: 0.04, blue: 0.08))
        }
    }
}

@main
struct BhaktiWidgets: Widget {
    let kind: String = "BhaktiWidget"

    var body: some WidgetConfiguration {
        buildConfiguration()
    }

    private func buildConfiguration() -> some WidgetConfiguration {
        let config = StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BhaktiWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("Bhakti Sacred Player")
        .description("Play sacred chants, switch tracks, and browse library directly from your home screen without opening app.")
        .supportedFamilies([.systemMedium])

        if #available(iOS 17.0, *) {
            return config.contentMarginsDisabled()
        } else {
            return config
        }
    }
}
