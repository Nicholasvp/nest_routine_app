import WidgetKit
import SwiftUI

struct WidgetEntry: TimelineEntry {
    let date: Date
    let babyName: String
    let isSleeping: Bool
    let isFeeding: Bool
    let lastSleepTime: String?
    let lastFeedTime: String?
    let sleepToday: String
    let locale: String
}

struct WidgetProvider: TimelineProvider {
    private let defaults = UserDefaults(suiteName: "group.com.nestroutine.nestroutine")

    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            babyName: "Baby",
            isSleeping: false,
            isFeeding: false,
            lastSleepTime: nil,
            lastFeedTime: nil,
            sleepToday: "0h",
            locale: "en"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> WidgetEntry {
        let babyName = defaults?.string(forKey: "widget_baby_name") ?? "Baby"
        let isSleeping = defaults?.bool(forKey: "widget_is_sleeping") ?? false
        let isFeeding = defaults?.bool(forKey: "widget_is_feeding") ?? false
        let lastSleepTime = defaults?.string(forKey: "widget_last_sleep_time")
        let lastFeedTime = defaults?.string(forKey: "widget_last_feed_time")
        let sleepToday = defaults?.string(forKey: "widget_sleep_today") ?? "0h"
        let locale = defaults?.string(forKey: "widget_locale") ?? "en"

        return WidgetEntry(
            date: Date(),
            babyName: babyName,
            isSleeping: isSleeping,
            isFeeding: isFeeding,
            lastSleepTime: lastSleepTime,
            lastFeedTime: lastFeedTime,
            sleepToday: sleepToday,
            locale: locale
        )
    }
}
