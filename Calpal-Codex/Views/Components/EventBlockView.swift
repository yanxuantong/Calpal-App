import SwiftUI

struct EventBlockView: View {
    let event: CalendarEventUIModel
    @AppStorage("preferredLanguage") private var preferredLanguage = AppLanguage.chinese.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.footnote.weight(.semibold))
                .lineLimit(2)

            Text(DateUtils.eventTimeRange(start: event.start, end: event.end, language: AppLanguage(rawValue: preferredLanguage) ?? .chinese))
                .font(.caption2)
                .foregroundStyle(.primary.opacity(0.7))
                .lineLimit(1)

            if let location = event.location, event.duration > 3600 {
                Text(location)
                    .font(.caption2)
                    .foregroundStyle(.primary.opacity(0.65))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(borderColor, lineWidth: event.isSuggested ? 1.2 : 0)
        )
    }

    private var backgroundColor: Color {
        event.isSuggested ? CalendarTheme.suggestedFill : event.color.opacity(0.22)
    }

    private var borderColor: Color {
        event.isSuggested ? CalendarTheme.accentBlue : .clear
    }
}

#Preview {
    EventBlockView(event: SampleCalendarData.makeEvents(anchorDate: .now)[1])
        .padding()
}
