import SwiftUI

struct DatePagerView: View {
    let language: AppLanguage
    let selectedDate: Date
    let visibleDates: [DayPage]
    let onSelectDate: (Date) -> Void
    let onSwipePrevious: () -> Void
    let onSwipeNext: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(visibleDates) { item in
                Button {
                    onSelectDate(item.date)
                } label: {
                    VStack(spacing: 6) {
                        Text(DateUtils.weekdaySymbol(for: item.date, language: language))
                            .font(.caption)
                            .foregroundStyle(CalendarTheme.subtleText)

                        Text(DateUtils.dayNumber(for: item.date))
                            .font(.body.weight(.semibold))
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(Calendar.current.isDate(item.date, inSameDayAs: selectedDate) ? CalendarTheme.accentBlue : .clear)
                            )
                            .foregroundStyle(Calendar.current.isDate(item.date, inSameDayAs: selectedDate) ? .white : .primary)

                        Circle()
                            .fill(item.hasEvents ? CalendarTheme.accentBlue : .clear)
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .opacity(Calendar.current.isDate(item.date, inSameDayAs: selectedDate) ? 1 : 0.7)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    if value.translation.width < -28 {
                        onSwipeNext()
                    } else if value.translation.width > 28 {
                        onSwipePrevious()
                    }
                }
        )
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    DatePagerView(
        language: .chinese,
        selectedDate: .now,
        visibleDates: (-2...2).map { offset in
            DayPage(date: Calendar.current.date(byAdding: .day, value: offset, to: .now) ?? .now, hasEvents: offset != 0)
        },
        onSelectDate: { _ in },
        onSwipePrevious: {},
        onSwipeNext: {}
    )
}
