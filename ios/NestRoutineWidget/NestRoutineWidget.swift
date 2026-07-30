import WidgetKit
import SwiftUI

@main
struct NestRoutineWidget: Widget {
    let kind: String = "NestRoutineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                WidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("NestRoutine")
        .description("Quick actions for your baby's routine.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
