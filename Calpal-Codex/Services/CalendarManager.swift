import EventKit
import SwiftUI

final class CalendarManager {
    private let store = EKEventStore()
    let systemDefaultCalendarIdentifier = "__system_default__"

    func authorizationStatus() -> EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    func hasAccess() -> Bool {
        authorizationStatus() == .fullAccess || authorizationStatus() == .writeOnly
    }

    func requestAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            store.requestFullAccessToEvents { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func fetchEvents(around centerDate: Date, daySpan: Int = 10) -> [CalendarEventUIModel] {
        guard hasAccess() else { return [] }
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -daySpan, to: DateUtils.startOfDay(centerDate)) ?? centerDate
        let end = calendar.date(byAdding: .day, value: daySpan, to: DateUtils.startOfDay(centerDate)) ?? centerDate
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate)
            .map(mapEvent)
            .sorted { $0.start < $1.start }
    }

    func fetchWritableCalendars() -> [WritableCalendarOption] {
        guard hasAccess() else { return [] }
        let defaultIdentifier = store.defaultCalendarForNewEvents?.calendarIdentifier

        return store.calendars(for: .event)
            .filter(\.allowsContentModifications)
            .map { calendar in
                WritableCalendarOption(
                    id: calendar.calendarIdentifier,
                    title: calendar.title,
                    sourceTitle: calendar.source.title,
                    isDefault: calendar.calendarIdentifier == defaultIdentifier
                )
            }
            .sorted { lhs, rhs in
                if lhs.isDefault != rhs.isDefault {
                    return lhs.isDefault
                }
                if lhs.sourceTitle != rhs.sourceTitle {
                    return lhs.sourceTitle.localizedCaseInsensitiveCompare(rhs.sourceTitle) == .orderedAscending
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
    }

    func selectedCalendarTitle(for identifier: String?, language: AppLanguage) -> String {
        guard hasAccess() else { return language.ui("不可用", "Unavailable") }
        guard let identifier, identifier != systemDefaultCalendarIdentifier else {
            if let defaultCalendar = store.defaultCalendarForNewEvents {
                return "\(defaultCalendar.title) · \(defaultCalendar.source.title)"
            }
            return language.ui("跟随系统默认", "Follow System Default")
        }

        if let calendar = store.calendar(withIdentifier: identifier) {
            return "\(calendar.title) · \(calendar.source.title)"
        }

        return language.ui("未找到所选日历", "Selected calendar not found")
    }

    func conflictingEvents(start: Date, end: Date, excluding identifier: String? = nil) -> [CalendarEventUIModel] {
        guard hasAccess() else { return [] }
        let predicate = store.predicateForEvents(withStart: start.addingTimeInterval(-3600), end: end.addingTimeInterval(3600), calendars: nil)
        return store.events(matching: predicate)
            .filter { event in
                if let identifier, event.calendarItemIdentifier == identifier {
                    return false
                }
                return event.startDate < end && event.endDate > start
            }
            .map(mapEvent)
    }

    func execute(_ intent: CalendarIntent, language: AppLanguage, preferredCalendarIdentifier: String?) throws -> CalendarExecutionResult {
        guard hasAccess() else {
            throw CalendarIntentError.missingCalendarAccess
        }

        switch intent.action {
        case .add:
            return try addEvent(from: intent, language: language, preferredCalendarIdentifier: preferredCalendarIdentifier)
        case .delete:
            return try deleteEvent(from: intent, language: language)
        case .modify:
            return try modifyEvent(from: intent, language: language)
        }
    }

    func findBestMatch(for intent: CalendarIntent) -> EKEvent? {
        guard hasAccess() else { return nil }
        let calendar = Calendar.current
        let anchor = intent.startDate ?? .now
        let start = calendar.date(byAdding: .day, value: -14, to: DateUtils.startOfDay(anchor)) ?? anchor
        let end = calendar.date(byAdding: .day, value: 14, to: DateUtils.startOfDay(anchor)) ?? anchor
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let normalizedTarget = normalizeTitle(intent.title)

        return store.events(matching: predicate)
            .sorted { lhs, rhs in
                let leftScore = matchScore(for: lhs, targetTitle: normalizedTarget, anchorDate: intent.startDate)
                let rightScore = matchScore(for: rhs, targetTitle: normalizedTarget, anchorDate: intent.startDate)
                return leftScore > rightScore
            }
            .first(where: { matchScore(for: $0, targetTitle: normalizedTarget, anchorDate: intent.startDate) > 0 })
    }

    func makeRecurringDeleteConfirmation(for event: CalendarEventUIModel, language: AppLanguage) -> ConfirmationContext {
        ConfirmationContext(
            style: .recurringDelete,
            title: language.ui("删除周期事件", "Delete Recurring Event"),
            subtitle: language.ui("请选择要删除的范围", "Choose how much of the series to delete"),
            eventTitle: event.title,
            detail: DateUtils.sheetDetail(start: event.start, end: event.end, language: language)
        )
    }

    private func addEvent(from intent: CalendarIntent, language: AppLanguage, preferredCalendarIdentifier: String?) throws -> CalendarExecutionResult {
        guard let startDate = intent.startDate else { throw CalendarIntentError.missingStartDate }
        guard !intent.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw CalendarIntentError.missingTitle }

        let event = EKEvent(eventStore: store)
        event.calendar = preferredCalendar(for: preferredCalendarIdentifier)
        event.title = intent.title
        event.startDate = startDate
        event.endDate = intent.endDate ?? startDate.addingTimeInterval(3600)
        event.location = intent.location
        event.notes = intent.notes
        event.recurrenceRules = recurrenceRules(from: intent)

        try save(event: event, span: .thisEvent)
        return CalendarExecutionResult(message: language.ui("已添加到 Apple Calendar", "Added to Apple Calendar"), affectedTitle: event.title)
    }

    private func deleteEvent(from intent: CalendarIntent, language: AppLanguage) throws -> CalendarExecutionResult {
        guard let event = findBestMatch(for: intent) else { throw CalendarIntentError.eventNotFound }
        let span: EKSpan = event.hasRecurrenceRules ? .thisEvent : .thisEvent
        try remove(event: event, span: span)
        return CalendarExecutionResult(message: language.ui("已删除事件", "Deleted event"), affectedTitle: event.title)
    }

    private func modifyEvent(from intent: CalendarIntent, language: AppLanguage) throws -> CalendarExecutionResult {
        guard let event = findBestMatch(for: intent) else { throw CalendarIntentError.eventNotFound }
        let originalDuration = event.endDate.timeIntervalSince(event.startDate)

        if !intent.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            event.title = intent.title
        }
        if let start = intent.startDate {
            event.startDate = start
            event.endDate = intent.endDate ?? start.addingTimeInterval(originalDuration)
        }
        if let end = intent.endDate {
            event.endDate = end
        }
        if let location = intent.location {
            event.location = location
        }
        if let notes = intent.notes {
            event.notes = notes
        }
        if intent.isRecurring {
            event.recurrenceRules = recurrenceRules(from: intent)
        }

        try save(event: event, span: event.hasRecurrenceRules ? .futureEvents : .thisEvent)
        return CalendarExecutionResult(message: language.ui("已更新事件", "Updated event"), affectedTitle: event.title)
    }

    private func save(event: EKEvent, span: EKSpan) throws {
        try store.save(event, span: span)
    }

    private func remove(event: EKEvent, span: EKSpan) throws {
        try store.remove(event, span: span)
    }

    private func preferredCalendar(for identifier: String?) -> EKCalendar? {
        if let identifier, identifier != systemDefaultCalendarIdentifier,
           let calendar = store.calendar(withIdentifier: identifier),
           calendar.allowsContentModifications {
            return calendar
        }

        if let defaultCalendar = store.defaultCalendarForNewEvents, defaultCalendar.allowsContentModifications {
            return defaultCalendar
        }

        return store.calendars(for: .event).first(where: \.allowsContentModifications)
    }

    private func recurrenceRules(from intent: CalendarIntent) -> [EKRecurrenceRule]? {
        guard intent.isRecurring, let rawRule = intent.recurrenceRule?.lowercased() else { return nil }

        if rawRule.contains("daily") || rawRule.contains("每天") {
            return [EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil)]
        }
        if rawRule.contains("weekly") || rawRule.contains("每周") {
            return [EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: nil)]
        }
        if rawRule.contains("monthly") || rawRule.contains("每月") {
            return [EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: nil)]
        }

        return nil
    }

    private func mapEvent(_ event: EKEvent) -> CalendarEventUIModel {
        let uiColor = event.calendar.cgColor.map { UIColor(cgColor: $0) } ?? .systemBlue

        return CalendarEventUIModel(
            id: event.calendarItemIdentifier,
            title: event.title,
            start: event.startDate,
            end: event.endDate,
            color: Color(uiColor),
            isSuggested: false,
            isRecurring: event.hasRecurrenceRules,
            location: event.location,
            calendarName: event.calendar.title
        )
    }

    private func normalizeTitle(_ title: String) -> String {
        title
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "：", with: "")
            .replacingOccurrences(of: ":", with: "")
    }

    private func matchScore(for event: EKEvent, targetTitle: String, anchorDate: Date?) -> Int {
        let eventTitle = normalizeTitle(event.title)
        var score = 0

        if eventTitle == targetTitle {
            score += 100
        } else if eventTitle.contains(targetTitle) || targetTitle.contains(eventTitle) {
            score += 60
        }

        if let anchorDate {
            let dayDelta = abs(Calendar.current.dateComponents([.day], from: DateUtils.startOfDay(event.startDate), to: DateUtils.startOfDay(anchorDate)).day ?? 99)
            score += max(0, 20 - dayDelta)
        }

        return score
    }
}
