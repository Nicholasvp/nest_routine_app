import SwiftUI
import WidgetKit

struct WidgetEntryView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family

    private var pt: Bool { entry.locale == "pt" }

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
                    .font(.title3)
                Text(entry.babyName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
            }

            if entry.isSleeping {
                statusBadge(
                    icon: "moon.zzz.fill",
                    text: pt ? "Dormindo" : "Sleeping",
                    color: .purple
                )
            } else if entry.isFeeding {
                statusBadge(
                    icon: "fork.knife",
                    text: pt ? "Comendo" : "Eating",
                    color: .orange
                )
            } else {
                Text(pt ? "Sem atividade" : "No activity")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let sleep = entry.lastSleepTime {
                infoRow(icon: "moon.zzz.fill", text: sleep, color: .purple)
            }
            if let feed = entry.lastFeedTime {
                infoRow(icon: "drop.fill", text: feed, color: .orange)
            }

            HStack {
                Image(systemName: "bed.double.fill")
                    .font(.caption2)
                    .foregroundColor(.purple)
                Text(entry.sleepToday)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(14)
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
                    .font(.title3)
                Text(entry.babyName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if entry.isSleeping {
                    statusBadge(icon: "moon.zzz.fill", text: pt ? "Dormindo" : "Sleeping", color: .purple)
                } else if entry.isFeeding {
                    statusBadge(icon: "fork.knife", text: pt ? "Comendo" : "Eating", color: .orange)
                }
            }

            Divider()

            HStack(spacing: 12) {
                actionButton(
                    icon: "moon.zzz.fill",
                    label: entry.isSleeping
                        ? (pt ? "Acordar" : "Wake up")
                        : (pt ? "Dormir" : "Sleep"),
                    color: .purple,
                    url: entry.isSleeping
                        ? URL(string: "nestroutine://action/wake")!
                        : URL(string: "nestroutine://action/sleep")!
                )
                actionButton(
                    icon: "fork.knife",
                    label: pt ? "Comer" : "Feed",
                    color: .orange,
                    url: URL(string: "nestroutine://action/feed")!
                )
                actionButton(
                    icon: "drop.fill",
                    label: pt ? "Fralda" : "Diaper",
                    color: .teal,
                    url: URL(string: "nestroutine://action/diaper")!
                )
            }

            HStack(spacing: 16) {
                if let sleep = entry.lastSleepTime {
                    infoRow(icon: "moon.zzz.fill", text: sleep, color: .purple)
                }
                if let feed = entry.lastFeedTime {
                    infoRow(icon: "drop.fill", text: feed, color: .orange)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "bed.double.fill")
                        .font(.caption2)
                        .foregroundColor(.purple)
                    Text(entry.sleepToday)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
    }

    // MARK: - Components

    private func statusBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    private func actionButton(icon: String, label: String, color: Color, url: URL) -> some View {
        Link(destination: url) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func infoRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
