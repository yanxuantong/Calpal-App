import SwiftUI

struct TimelineView: View {
    let selectedDate: Date
    let events: [CalendarEventUIModel]
    let scrollToHour: Int?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    timelineGrid
                    eventLayer
                    currentTimeLayer
                }
                .frame(height: LayoutMetrics.hourHeight * 24)
            }
            .background(Color(uiColor: .systemBackground))
            .onAppear {
                scrollToIfNeeded(with: proxy)
            }
            .onChange(of: scrollToHour) { _, _ in
                scrollToIfNeeded(with: proxy)
            }
        }
    }

    private var timelineGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                HStack(spacing: 0) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(hour == 0 ? "12" : "\(hour <= 12 ? hour : hour - 12)")
                            .font(.caption2)
                        Text(hour < 12 ? "AM" : "PM")
                            .font(.caption2)
                            .foregroundStyle(CalendarTheme.subtleText)
                    }
                    .frame(width: 50, alignment: .trailing)
                    .padding(.trailing, 8)

                    Rectangle()
                        .fill(CalendarTheme.timelineLine.opacity(0.75))
                        .frame(height: 0.5)
                }
                .frame(height: LayoutMetrics.hourHeight)
                .id(hour)
            }
        }
        .padding(.horizontal, LayoutMetrics.timelineTrailingInset)
    }

    private var eventLayer: some View {
        GeometryReader { geometry in
            ForEach(events) { event in
                EventBlockView(event: event)
                    .frame(
                        width: geometry.size.width - LayoutMetrics.timelineLeadingInset - LayoutMetrics.timelineTrailingInset,
                        height: eventHeight(event)
                    )
                    .offset(
                        x: LayoutMetrics.timelineLeadingInset,
                        y: eventOffset(event)
                    )
            }
        }
    }

    @ViewBuilder
    private var currentTimeLayer: some View {
        if Calendar.current.isDateInToday(selectedDate) {
            let offset = currentTimeOffset()
            ZStack(alignment: .leading) {
                Circle()
                    .fill(CalendarTheme.currentTimeRed)
                    .frame(width: 8, height: 8)
                    .offset(x: 56, y: offset - 4)

                Rectangle()
                    .fill(CalendarTheme.currentTimeRed)
                    .frame(height: 1.5)
                    .offset(x: LayoutMetrics.timelineLeadingInset, y: offset)
            }
        }
    }

    private func eventOffset(_ event: CalendarEventUIModel) -> CGFloat {
        let hour = Calendar.current.component(.hour, from: event.start)
        let minute = Calendar.current.component(.minute, from: event.start)
        return CGFloat(hour) * LayoutMetrics.hourHeight + CGFloat(minute) / 60 * LayoutMetrics.hourHeight
    }

    private func eventHeight(_ event: CalendarEventUIModel) -> CGFloat {
        max(CGFloat(event.duration / 3600) * LayoutMetrics.hourHeight, LayoutMetrics.timelineEventMinHeight)
    }

    private func currentTimeOffset() -> CGFloat {
        let hour = Calendar.current.component(.hour, from: .now)
        let minute = Calendar.current.component(.minute, from: .now)
        return CGFloat(hour) * LayoutMetrics.hourHeight + CGFloat(minute) / 60 * LayoutMetrics.hourHeight
    }

    private func scrollToIfNeeded(with proxy: ScrollViewProxy) {
        let targetHour = scrollToHour ?? max(Calendar.current.component(.hour, from: .now) - 1, 0)
        proxy.scrollTo(targetHour, anchor: .top)
    }
}

#Preview {
    TimelineView(
        selectedDate: .now,
        events: SampleCalendarData.makeEvents(anchorDate: .now),
        scrollToHour: 8
    )
}
