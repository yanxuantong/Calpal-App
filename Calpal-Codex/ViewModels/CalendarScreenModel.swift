import Foundation
import Observation
import SwiftUI
import EventKit
import Speech
import AVFAudio

@Observable
final class CalendarScreenModel {
    private enum StorageKeys {
        static let preferredCalendarIdentifier = "preferredCalendarIdentifier"
        static let systemDefaultCalendarIdentifier = "__system_default__"
    }

    var selectedDate: Date
    var visibleDates: [DayPage]
    var events: [CalendarEventUIModel]
    var fabState: FABState
    var showingTextInput: Bool
    var textDraft: String
    var activeConversation: ConversationContext?
    var activeConfirmation: ConfirmationContext?
    var showingSettings: Bool
    var scrollToHour: Int?
    var statusMessage: String?
    var latestTranscript: String
    var calendarPermission: PermissionState
    var speechPermission: PermissionState
    var microphonePermission: PermissionState
    var localAIStatusText: String
    var writableCalendars: [WritableCalendarOption]
    var preferredCalendarIdentifier: String
    var preferredCalendarDisplayName: String
    var isWorking: Bool
    var pendingIntent: CalendarIntent?
    var pendingDeleteEvent: CalendarEventUIModel?
    var language: AppLanguage
    var confirmationTitleDraft: String
    var confirmationStartDateDraft: Date
    var confirmationEndDateDraft: Date

    @ObservationIgnored private let calendarManager = CalendarManager()
    @ObservationIgnored private let voiceInputManager = VoiceInputManager()
    @ObservationIgnored private let intentParser = AIIntentParser()
    @ObservationIgnored private var statusDismissTask: Task<Void, Never>?

    init(
        language: AppLanguage = .chinese,
        selectedDate: Date = .now,
        visibleDates: [DayPage] = [],
        events: [CalendarEventUIModel] = [],
        fabState: FABState = .idle,
        showingTextInput: Bool = false,
        textDraft: String = "",
        activeConversation: ConversationContext? = nil,
        activeConfirmation: ConfirmationContext? = nil,
        showingSettings: Bool = false
    ) {
        let normalizedDate = DateUtils.startOfDay(selectedDate)
        self.selectedDate = normalizedDate
        self.visibleDates = visibleDates
        self.events = events
        self.fabState = fabState
        self.showingTextInput = showingTextInput
        self.textDraft = textDraft
        self.activeConversation = activeConversation
        self.activeConfirmation = activeConfirmation
        self.showingSettings = showingSettings
        self.statusMessage = nil
        self.latestTranscript = ""
        self.calendarPermission = .needsAttention
        self.speechPermission = .needsAttention
        self.microphonePermission = .needsAttention
        self.localAIStatusText = language.ui("检测中", "Checking")
        self.writableCalendars = []
        self.preferredCalendarIdentifier = UserDefaults.standard.string(forKey: StorageKeys.preferredCalendarIdentifier) ?? StorageKeys.systemDefaultCalendarIdentifier
        self.preferredCalendarDisplayName = language.ui("跟随系统默认", "Follow System Default")
        self.isWorking = false
        self.pendingIntent = nil
        self.pendingDeleteEvent = nil
        self.language = language
        self.confirmationTitleDraft = ""
        self.confirmationStartDateDraft = normalizedDate
        self.confirmationEndDateDraft = normalizedDate.addingTimeInterval(3600)

        if (visibleDates.isEmpty || events.isEmpty) && ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            seedMockData()
        } else if visibleDates.isEmpty {
            refreshVisibleDates(around: normalizedDate)
        }

        refreshStatusIndicators()
    }

    var monthTitle: String {
        DateUtils.monthTitle(for: selectedDate, language: language)
    }

    var selectedDateEvents: [CalendarEventUIModel] {
        events
            .filter { Calendar.current.isDate($0.start, inSameDayAs: selectedDate) }
            .sorted { $0.start < $1.start }
    }

    func seedMockData() {
        let today = DateUtils.startOfDay(.now)
        selectedDate = today
        visibleDates = (-2...2).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: today) ?? today
            return DayPage(date: date, hasEvents: offset != -2)
        }
        events = SampleCalendarData.makeEvents(anchorDate: today)
    }

    func refreshStatusIndicators() {
        calendarPermission = mapCalendarPermission(calendarManager.authorizationStatus())
        speechPermission = mapSpeechPermission(voiceInputManager.speechAuthorizationStatus())
        microphonePermission = mapMicrophonePermission(voiceInputManager.microphonePermission())
        localAIStatusText = intentParser.availabilitySummary(language: language).1
        refreshWritableCalendars()
    }

    func loadInitialData() async {
        refreshStatusIndicators()

        if calendarManager.authorizationStatus() == .notDetermined {
            do {
                _ = try await calendarManager.requestAccess()
            } catch {
                showStatus(localizedMessage(for: error))
            }
            refreshStatusIndicators()
        }

        await refreshEvents()
    }

    func refreshWritableCalendars() {
        writableCalendars = calendarManager.fetchWritableCalendars()
        preferredCalendarDisplayName = calendarManager.selectedCalendarTitle(for: preferredCalendarIdentifier, language: language)
    }

    func selectPreferredCalendar(_ identifier: String) {
        preferredCalendarIdentifier = identifier
        UserDefaults.standard.set(identifier, forKey: StorageKeys.preferredCalendarIdentifier)
        preferredCalendarDisplayName = calendarManager.selectedCalendarTitle(for: identifier, language: language)
    }

    func selectDate(_ date: Date) {
        selectedDate = DateUtils.startOfDay(date)
        refreshVisibleDates(around: selectedDate)
    }

    func jumpToToday() {
        selectDate(.now)
        scrollToHour = Calendar.current.component(.hour, from: .now)
    }

    func refreshVisibleDates(around centerDate: Date) {
        visibleDates = (-2...2).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: centerDate) ?? centerDate
            let hasEvents = events.contains { Calendar.current.isDate($0.start, inSameDayAs: date) }
            return DayPage(date: date, hasEvents: hasEvents)
        }
    }

    func openConversation(for variant: ConversationVariant) {
        let previewEvents = selectedDateEvents.filter(\.isSuggested)
        let fallbackEvent = selectedDateEvents.first.map { [$0] } ?? []
        activeConversation = SampleCalendarData.makeConversation(
            variant: variant,
            language: language,
            previewDate: selectedDate,
            previewEvents: previewEvents.isEmpty ? fallbackEvent : previewEvents
        )
    }

    func openAddConfirmation() {
        guard let firstSuggested = selectedDateEvents.first(where: \.isSuggested) else { return }
        pendingIntent = CalendarIntent(
            action: .add,
            title: firstSuggested.title,
            startDate: firstSuggested.start,
            endDate: firstSuggested.end,
            isRecurring: false,
            recurrenceRule: nil,
            location: firstSuggested.location,
            notes: nil,
            originalText: firstSuggested.title
        )
        confirmationTitleDraft = firstSuggested.title
        confirmationStartDateDraft = firstSuggested.start
        confirmationEndDateDraft = firstSuggested.end
        activeConfirmation = ConfirmationContext(
            style: .add,
            title: language.ui("✦ 添加事件", "✦ Add Event"),
            subtitle: language.ui("无冲突，可直接写入 Apple Calendar", "No conflicts found. This can be written directly to Apple Calendar."),
            eventTitle: firstSuggested.title,
            detail: DateUtils.sheetDetail(start: firstSuggested.start, end: firstSuggested.end, language: language)
        )
    }

    func openDeleteConfirmation() {
        guard let event = selectedDateEvents.first else { return }
        pendingDeleteEvent = event
        activeConfirmation = event.isRecurring
            ? calendarManager.makeRecurringDeleteConfirmation(for: event, language: language)
            : ConfirmationContext(
                style: .delete,
                title: language.ui("确认删除", "Confirm Delete"),
                subtitle: language.ui("删除任何事件都需要二次确认", "Deleting an event requires one more confirmation."),
                eventTitle: event.title,
                detail: DateUtils.sheetDetail(start: event.start, end: event.end, language: language)
            )
        confirmationTitleDraft = event.title
        confirmationStartDateDraft = event.start
        confirmationEndDateDraft = event.end
    }

    func beginRecording() async {
        refreshStatusIndicators()

        if calendarManager.authorizationStatus() == .notDetermined {
            _ = try? await calendarManager.requestAccess()
            refreshStatusIndicators()
        }

        if voiceInputManager.microphonePermission() == .undetermined {
            _ = await voiceInputManager.requestMicrophoneAccess()
            refreshStatusIndicators()
        }

        if voiceInputManager.speechAuthorizationStatus() == .notDetermined {
            _ = await voiceInputManager.requestSpeechAuthorization()
            refreshStatusIndicators()
        }

        do {
            try voiceInputManager.startRecording(localeIdentifier: language.localeIdentifier, language: language) { [weak self] text in
                Task { @MainActor in
                    self?.latestTranscript = text
                }
            }
            latestTranscript = ""
            showStatus(language.ui("正在聆听...", "Listening..."), autoDismiss: false)
            fabState = .recording
        } catch {
            showStatus(localizedMessage(for: error))
            fabState = .idle
        }
    }

    func cancelRecording() {
        voiceInputManager.cancelRecording()
        latestTranscript = ""
        showStatus(language.ui("已取消录音", "Recording cancelled"))
        fabState = .idle
    }

    @MainActor
    func finishRecording() async {
        guard fabState == .recording else { return }
        fabState = .processing

        do {
            let transcript = try await voiceInputManager.stopRecording()
            latestTranscript = transcript
            try await handleUserInput(transcript, mode: .voice)
        } catch {
            showStatus(localizedMessage(for: error))
        }

        fabState = .idle
    }

    @MainActor
    func submitTextIntent() async {
        let input = textDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        showingTextInput = false
        fabState = .processing

        do {
            try await handleUserInput(input, mode: .text)
            textDraft = ""
        } catch {
            showStatus(localizedMessage(for: error))
        }

        fabState = .idle
    }

    @MainActor
    func confirmPendingIntent() async {
        if let pendingIntent {
            do {
                let editedIntent = CalendarIntent(
                    action: pendingIntent.action,
                    title: confirmationTitleDraft.trimmingCharacters(in: .whitespacesAndNewlines),
                    startDate: pendingIntent.action == .delete ? pendingIntent.startDate : confirmationStartDateDraft,
                    endDate: pendingIntent.action == .delete ? pendingIntent.endDate : max(confirmationEndDateDraft, confirmationStartDateDraft.addingTimeInterval(900)),
                    isRecurring: pendingIntent.isRecurring,
                    recurrenceRule: pendingIntent.recurrenceRule,
                    location: pendingIntent.location,
                    notes: pendingIntent.notes,
                    originalText: pendingIntent.originalText
                )
                try await applyIntent(editedIntent)
            } catch {
                showStatus(localizedMessage(for: error))
            }
            self.pendingIntent = nil
        } else if let pendingDeleteEvent {
            let intent = CalendarIntent(
                action: .delete,
                title: pendingDeleteEvent.title,
                startDate: pendingDeleteEvent.start,
                endDate: nil,
                isRecurring: false,
                recurrenceRule: nil,
                location: nil,
                notes: nil,
                originalText: pendingDeleteEvent.title
            )
            do {
                try await applyIntent(intent)
            } catch {
                showStatus(localizedMessage(for: error))
            }
            self.pendingDeleteEvent = nil
        }
        activeConfirmation = nil
    }

    func dismissConfirmation() {
        activeConfirmation = nil
        pendingIntent = nil
        pendingDeleteEvent = nil
    }

    @MainActor
    func refreshEvents() async {
        refreshStatusIndicators()
        let previousEventIDs = Set(events.map(\.id))

        if calendarManager.hasAccess() {
            let fetched = calendarManager.fetchEvents(around: selectedDate)
            events = fetched
            refreshVisibleDates(around: selectedDate)

            if fetched.isEmpty {
                if !previousEventIDs.isEmpty {
                    showStatus(language.ui("当前时间范围内没有事件。", "There are no events in the current time range."))
                }
            } else if !previousEventIDs.isEmpty && previousEventIDs != Set(fetched.map(\.id)) {
                showStatus(language.ui("日历已同步更新。", "Calendar content has been refreshed."))
            }
        } else {
            events = []
            refreshVisibleDates(around: selectedDate)
            showStatus(language.ui("尚未获得日历权限，当前不会显示 demo 数据。", "Calendar access is not granted, so no demo data will be shown."))
        }
    }

    @MainActor
    private func handleUserInput(_ input: String, mode: InputMode) async throws {
        let intent = try await intentParser.parseIntent(from: input, referenceDate: selectedDate, language: language)
        try validate(intent)

        if mode == .voice {
            showStatus(language.ui("已识别：\(input)", "Recognized: \(input)"))
        } else {
            showStatus(language.ui("正在解析...", "Parsing..."), autoDismiss: false)
        }

        if requiresConfirmation(for: intent) {
            pendingIntent = intent
            activeConfirmation = makeConfirmationContext(for: intent)
        } else {
            try await applyIntent(intent)
        }
    }

    private func validate(_ intent: CalendarIntent) throws {
        if intent.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw CalendarIntentError.missingTitle
        }

        if intent.action != .delete && intent.startDate == nil {
            throw CalendarIntentError.missingStartDate
        }
    }

    private func requiresConfirmation(for intent: CalendarIntent) -> Bool {
        if intent.action == .delete {
            return true
        }
        if intent.isRecurring {
            return true
        }
        guard let start = intent.startDate, let end = intent.endDate else {
            return true
        }

        if intent.action == .modify, let matched = calendarManager.findBestMatch(for: intent) {
            return !calendarManager.conflictingEvents(start: start, end: end, excluding: matched.calendarItemIdentifier).isEmpty
        }

        return !calendarManager.conflictingEvents(start: start, end: end).isEmpty
    }

    private func makeConfirmationContext(for intent: CalendarIntent) -> ConfirmationContext {
        switch intent.action {
        case .delete:
            confirmationTitleDraft = intent.title
            confirmationStartDateDraft = intent.startDate ?? selectedDate
            confirmationEndDateDraft = intent.endDate ?? (intent.startDate ?? selectedDate).addingTimeInterval(3600)
            return ConfirmationContext(
                style: .delete,
                title: language.ui("确认删除", "Confirm Delete"),
                subtitle: language.ui("删除任何事件都需要二次确认", "Deleting an event requires one more confirmation."),
                eventTitle: intent.title,
                detail: detailText(for: intent)
            )
        case .modify:
            confirmationTitleDraft = intent.title
            confirmationStartDateDraft = intent.startDate ?? selectedDate
            confirmationEndDateDraft = intent.endDate ?? confirmationStartDateDraft.addingTimeInterval(3600)
            return ConfirmationContext(
                style: .add,
                title: language.ui("确认修改", "Confirm Changes"),
                subtitle: language.ui("检测到时间冲突或需要确认的改动", "A conflict or important change was detected."),
                eventTitle: intent.title,
                detail: detailText(for: intent)
            )
        case .add:
            confirmationTitleDraft = intent.title
            confirmationStartDateDraft = intent.startDate ?? selectedDate
            confirmationEndDateDraft = intent.endDate ?? confirmationStartDateDraft.addingTimeInterval(3600)
            return ConfirmationContext(
                style: intent.isRecurring ? .add : .add,
                title: intent.isRecurring ? language.ui("确认创建周期事件", "Confirm Recurring Event") : language.ui("确认添加", "Confirm Add"),
                subtitle: intent.isRecurring ? language.ui("周期事件首次创建建议确认一次", "Recurring events should be confirmed once before creation.") : language.ui("检测到冲突或需要确认的添加操作", "A conflict or confirmation-worthy add action was detected."),
                eventTitle: intent.title,
                detail: detailText(for: intent)
            )
        }
    }

    private func detailText(for intent: CalendarIntent) -> String {
        guard let start = intent.startDate else { return language.ui("时间待确认", "Time needs confirmation") }
        return DateUtils.sheetDetail(start: start, end: intent.endDate ?? start.addingTimeInterval(3600), language: language)
    }

    @MainActor
    private func applyIntent(_ intent: CalendarIntent) async throws {
        if !calendarManager.hasAccess() {
            let granted = try await calendarManager.requestAccess()
            if !granted {
                throw CalendarIntentError.missingCalendarAccess
            }
        }

        isWorking = true
        defer { isWorking = false }

        let result = try calendarManager.execute(intent, language: language, preferredCalendarIdentifier: preferredCalendarIdentifier)
        showStatus(language.ui("\(result.message)：\(result.affectedTitle)", "\(result.message): \(result.affectedTitle)"))
        await refreshEvents()
    }

    private func localizedMessage(for error: Error) -> String {
        if let calendarError = error as? CalendarIntentError {
            return calendarError.message(in: language)
        }
        if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
            return description
        }
        return error.localizedDescription
    }

    func clearStatus() {
        statusDismissTask?.cancel()
        statusMessage = nil
    }

    private func showStatus(_ message: String, autoDismiss: Bool = true) {
        statusDismissTask?.cancel()
        statusMessage = message

        guard autoDismiss else { return }
        statusDismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            self?.statusMessage = nil
        }
    }

    private func mapCalendarPermission(_ status: EKAuthorizationStatus) -> PermissionState {
        switch status {
        case .fullAccess, .writeOnly:
            return .ready
        default:
            return .needsAttention
        }
    }

    private func mapSpeechPermission(_ status: SFSpeechRecognizerAuthorizationStatus) -> PermissionState {
        status == .authorized ? .ready : .needsAttention
    }

    private func mapMicrophonePermission(_ status: AVAudioApplication.recordPermission) -> PermissionState {
        status == .granted ? .ready : .needsAttention
    }
}

enum SampleCalendarData {
    static func makeEvents(anchorDate: Date) -> [CalendarEventUIModel] {
        let calendar = Calendar.current
        let today = DateUtils.startOfDay(anchorDate)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let dayAfter = calendar.date(byAdding: .day, value: 2, to: today) ?? today

        return [
            CalendarEventUIModel(
                id: "standup",
                title: "Team standup",
                start: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today,
                end: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: today) ?? today,
                color: .mint,
                isSuggested: false,
                isRecurring: false,
                location: "Zoom",
                calendarName: "Apple Calendar"
            ),
            CalendarEventUIModel(
                id: "focus",
                title: "深度工作",
                start: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: today) ?? today,
                end: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today) ?? today,
                color: CalendarTheme.accentBlue,
                isSuggested: true,
                isRecurring: false,
                location: nil,
                calendarName: "Apple Calendar"
            ),
            CalendarEventUIModel(
                id: "lunch",
                title: "Lunch with Jason",
                start: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: tomorrow) ?? tomorrow,
                end: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: tomorrow) ?? tomorrow,
                color: .orange,
                isSuggested: false,
                isRecurring: false,
                location: "Cupertino",
                calendarName: "Apple Calendar"
            ),
            CalendarEventUIModel(
                id: "run",
                title: "每周一跑步",
                start: calendar.date(bySettingHour: 7, minute: 30, second: 0, of: dayAfter) ?? dayAfter,
                end: calendar.date(bySettingHour: 8, minute: 15, second: 0, of: dayAfter) ?? dayAfter,
                color: .purple,
                isSuggested: false,
                isRecurring: true,
                location: "Stevens Creek Trail",
                calendarName: "Apple Calendar"
            )
        ]
    }

    static func makeConversation(
        variant: ConversationVariant,
        language: AppLanguage,
        previewDate: Date,
        previewEvents: [CalendarEventUIModel]
    ) -> ConversationContext {
        switch variant {
        case .planning:
            return ConversationContext(
                variant: .planning,
                language: language,
                previewTitle: language.ui("今天下午建议锁一段完整专注时间", "A solid focus block fits well this afternoon"),
                previewDate: previewDate,
                previewEvents: previewEvents,
                messages: [
                    ConversationBubble(sender: .assistant, text: language.ui("你今天 1:30 到 3:00 有一段比较完整的空档，适合安排深度工作。", "You have a fairly open block from 1:30 to 3:00 today that would work well for focused work.")),
                    ConversationBubble(sender: .user, text: language.ui("可以，帮我先预留出来。", "Sounds good. Hold that time for me.")),
                    ConversationBubble(sender: .assistant, text: language.ui("我已经准备好了预览，确认后会直接写入 Apple Calendar。", "I've prepared a preview. Once you confirm, it will be written directly to Apple Calendar."))
                ],
                actions: ConversationActionSet(primaryTitle: language.ui("采纳", "Apply"), secondaryTitle: language.ui("改时间", "Adjust Time"), tertiaryTitle: language.ui("略过", "Skip"))
            )
        case .review:
            return ConversationContext(
                variant: .review,
                language: language,
                previewTitle: language.ui("今天没完成的任务，建议明早优先补上", "The unfinished work from today should be prioritized tomorrow morning"),
                previewDate: previewDate,
                previewEvents: previewEvents,
                messages: [
                    ConversationBubble(sender: .assistant, text: language.ui("你今天的深度工作被会议打断了，明早 8:30 前有 45 分钟空档。", "Your focus session got interrupted by meetings today, and there is a 45-minute opening before 8:30 tomorrow morning.")),
                    ConversationBubble(sender: .user, text: language.ui("那就先放到明天早上吧。", "Then let's move it to tomorrow morning.")),
                    ConversationBubble(sender: .assistant, text: language.ui("可以，我会把这段补排成一个高优先级专注块。", "Great. I'll turn that into a high-priority focus block."))
                ],
                actions: ConversationActionSet(primaryTitle: language.ui("采纳", "Apply"), secondaryTitle: language.ui("稍后", "Later"), tertiaryTitle: language.ui("忽略", "Ignore"))
            )
        }
    }
}
