import SwiftUI
import EventKit

struct MainCalendarScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("preferredLanguage") private var preferredLanguage = AppLanguage.chinese.rawValue
    @State private var model: CalendarScreenModel
    let initialLanguage: AppLanguage

    init(initialLanguage: AppLanguage) {
        self.initialLanguage = initialLanguage
        _model = State(initialValue: CalendarScreenModel(language: initialLanguage))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    CalendarHeaderView(
                        language: model.language,
                        monthTitle: model.monthTitle,
                        onTodayTap: model.jumpToToday,
                        onMenuTap: { model.showingSettings = true }
                    )

                    DatePagerView(
                        language: model.language,
                        selectedDate: model.selectedDate,
                        visibleDates: model.visibleDates,
                        onSelectDate: { date in
                            withAnimation(.interactiveSpring(response: 0.34, dampingFraction: 0.86)) {
                                model.selectDate(date)
                            }
                        },
                        onSwipePrevious: {
                            guard let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: model.selectedDate) else { return }
                            withAnimation(.interactiveSpring(response: 0.34, dampingFraction: 0.86)) {
                                model.selectDate(previousDate)
                            }
                        },
                        onSwipeNext: {
                            guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: model.selectedDate) else { return }
                            withAnimation(.interactiveSpring(response: 0.34, dampingFraction: 0.86)) {
                                model.selectDate(nextDate)
                            }
                        }
                    )
                    .frame(height: LayoutMetrics.dayPagerHeight)

                    Divider()

                    TabView(selection: Binding(
                        get: { model.selectedDate },
                        set: { newValue in
                            withAnimation(.interactiveSpring(response: 0.34, dampingFraction: 0.86)) {
                                model.selectDate(newValue)
                            }
                        })
                    ) {
                        ForEach(model.visibleDates) { item in
                            TimelineView(
                                selectedDate: item.date,
                                events: model.events.filter { Calendar.current.isDate($0.start, inSameDayAs: item.date) },
                                scrollToHour: item.date == model.selectedDate ? model.scrollToHour : nil
                            )
                            .tag(item.date)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }

                if let statusMessage = model.statusMessage {
                    VStack {
                        StatusBannerView(
                            title: statusMessage,
                            transcript: model.latestTranscript.isEmpty ? nil : model.latestTranscript
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .allowsHitTesting(false)
                }

                FloatingInputBar(
                    language: model.language,
                    fabState: model.fabState,
                    onTypeTap: { model.showingTextInput = true },
                    onTapPlanning: { model.openConversation(for: .planning) },
                    onTapReview: { model.openConversation(for: .review) },
                    onTapDelete: model.openDeleteConfirmation,
                    onPressBegan: { Task { await model.beginRecording() } },
                    onPressEnded: { Task { await model.finishRecording() } },
                    onCancelRecording: model.cancelRecording
                )
            }
            .navigationBarHidden(true)
        }
        .tint(CalendarTheme.accentBlue)
        .sheet(item: $model.activeConversation) { context in
            UnifiedConversationScreen(context: context) {
                model.activeConversation = nil
                model.openAddConfirmation()
            }
            .presentationDetents([.large])
        }
        .sheet(item: $model.activeConfirmation) { context in
            ConfirmationSheetView(
                language: model.language,
                context: context,
                editableTitle: $model.confirmationTitleDraft,
                editableStartDate: $model.confirmationStartDateDraft,
                editableEndDate: $model.confirmationEndDateDraft,
                showsEditor: context.style == .add,
                onPrimaryAction: { Task { await model.confirmPendingIntent() } },
                onDismiss: model.dismissConfirmation
            )
            .presentationDetents([.height(context.style == .recurringDelete ? 360 : (context.style == .add ? 420 : 300))])
        }
        .sheet(isPresented: $model.showingTextInput) {
            TextInputSheet(
                language: model.language,
                textDraft: $model.textDraft,
                onSubmit: { Task { await model.submitTextIntent() } }
            )
            .presentationDetents([.height(260)])
        }
        .sheet(isPresented: $model.showingSettings) {
            SettingsView(
                selectedLanguage: model.language,
                calendarPermission: model.calendarPermission,
                speechPermission: model.speechPermission,
                microphonePermission: model.microphonePermission,
                localAIStatusText: model.localAIStatusText,
                writableCalendars: model.writableCalendars,
                selectedCalendarIdentifier: model.preferredCalendarIdentifier,
                onCalendarSelection: model.selectPreferredCalendar
            )
        }
        .task {
            await model.loadInitialData()
        }
        .onChange(of: preferredLanguage) { _, newValue in
            model.language = AppLanguage(rawValue: newValue) ?? .chinese
            model.refreshStatusIndicators()
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            Task { await model.refreshEvents() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
            Task { await model.refreshEvents() }
        }
    }
}

private struct StatusBannerView: View {
    let title: String
    let transcript: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            if let transcript {
                Text(transcript)
                    .font(.footnote)
                    .foregroundStyle(CalendarTheme.subtleText)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

#Preview {
    MainCalendarScreen(initialLanguage: .chinese)
}
