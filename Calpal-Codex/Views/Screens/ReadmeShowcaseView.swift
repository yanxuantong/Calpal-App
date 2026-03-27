import SwiftUI

struct ReadmeShowcaseView: View {
    enum Mode {
        case dashboard
        case smartScheduling
    }

    let mode: Mode

    private let language: AppLanguage = .english
    private let anchorDate = DateUtils.startOfDay(.now)

    var body: some View {
        Group {
            switch mode {
            case .dashboard:
                dashboardShowcase
            case .smartScheduling:
                planningShowcase
            }
        }
        .tint(CalendarTheme.accentBlue)
        .background(Color(uiColor: .systemBackground))
    }

    private var dashboardShowcase: some View {
        let visibleDates = (-2...2).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: anchorDate) ?? anchorDate
            return DayPage(date: date, hasEvents: offset != -2)
        }
        let events = showcaseEvents

        return GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    CalendarHeaderView(
                        language: language,
                        monthTitle: DateUtils.monthTitle(for: anchorDate, language: language),
                        onTodayTap: {},
                        onMenuTap: {}
                    )

                    DatePagerView(
                        language: language,
                        selectedDate: anchorDate,
                        visibleDates: visibleDates,
                        onSelectDate: { _ in },
                        onSwipePrevious: {},
                        onSwipeNext: {}
                    )
                    .frame(height: LayoutMetrics.dayPagerHeight)

                    Divider()

                    TimelineView(
                        selectedDate: anchorDate,
                        events: events.filter { Calendar.current.isDate($0.start, inSameDayAs: anchorDate) },
                        scrollToHour: 8
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                FloatingInputBar(
                    language: language,
                    fabState: .idle,
                    onTypeTap: {},
                    onTapPlanning: {},
                    onTapReview: {},
                    onTapDelete: {},
                    onPressBegan: {},
                    onPressEnded: {},
                    onCancelRecording: {},
                    bottomPadding: proxy.safeAreaInsets.bottom + LayoutMetrics.floatingBarBottomPadding
                )
            }
        }
    }

    private var planningShowcase: some View {
        let events = showcaseEvents.filter(\.isSuggested)
        let context = SampleCalendarData.makeConversation(
            variant: .planning,
            language: language,
            previewDate: anchorDate,
            previewEvents: events
        )

        return NavigationStack {
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    SplitPreviewCard(
                        context: context,
                        onPrimaryAction: {},
                        onSecondaryAction: {},
                        onTertiaryAction: {}
                    )
                    .frame(height: proxy.size.height * LayoutMetrics.splitPreviewRatio)

                    Divider()
                        .overlay(CalendarTheme.accentBlue.frame(height: 2))

                    ConversationAreaView(context: context)
                }
                .background(Color(uiColor: .systemBackground))
            }
            .navigationTitle("Smart Scheduling")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {}
                }
            }
        }
    }

    private var showcaseEvents: [CalendarEventUIModel] {
        SampleCalendarData.makeEvents(anchorDate: anchorDate).map { event in
            let localizedTitle: String
            switch event.id {
            case "standup":
                localizedTitle = "Team standup"
            case "focus":
                localizedTitle = "Deep work block"
            case "lunch":
                localizedTitle = "Lunch with Jason"
            case "run":
                localizedTitle = "Monday run"
            default:
                localizedTitle = event.title
            }

            return CalendarEventUIModel(
                id: event.id,
                title: localizedTitle,
                start: event.start,
                end: event.end,
                color: event.color,
                isSuggested: event.isSuggested,
                isRecurring: event.isRecurring,
                location: event.location,
                calendarName: event.calendarName
            )
        }
    }
}

#Preview("Dashboard") {
    ReadmeShowcaseView(mode: .dashboard)
}

#Preview("Smart Scheduling") {
    ReadmeShowcaseView(mode: .smartScheduling)
}
