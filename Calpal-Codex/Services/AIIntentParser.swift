import Foundation
import FoundationModels

@Generable(description: "Structured calendar intent parsed from a natural language request.")
struct GeneratedCalendarIntent {
    let action: String
    let title: String
    let startISO: String?
    let endISO: String?
    let isRecurring: Bool
    let recurrenceRule: String?
    let location: String?
    let notes: String?
}

final class AIIntentParser {
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private let fallbackFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    func availabilitySummary(language: AppLanguage = .chinese) -> (PermissionState, String) {
        let model = SystemLanguageModel.default

        switch model.availability {
        case .available:
            return (.ready, language.ui("已启用", "Available"))
        case .unavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled:
                return (.needsAttention, language.ui("Apple Intelligence 未开启", "Apple Intelligence is not enabled"))
            case .deviceNotEligible:
                return (.needsAttention, language.ui("设备暂不支持", "This device is not supported"))
            case .modelNotReady:
                return (.needsAttention, language.ui("模型尚未准备好", "The model is not ready yet"))
            @unknown default:
                return (.needsAttention, language.ui("本地模型暂不可用", "The on-device model is currently unavailable"))
            }
        @unknown default:
            return (.needsAttention, language.ui("本地模型暂不可用", "The on-device model is currently unavailable"))
        }
    }

    func parseIntent(from text: String, referenceDate: Date, language: AppLanguage) async throws -> CalendarIntent {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CalendarIntentError.emptyInput }

        if SystemLanguageModel.default.isAvailable {
            do {
                return try await parseWithFoundationModels(from: trimmed, referenceDate: referenceDate, language: language)
            } catch {
                return try fallbackIntent(from: trimmed, referenceDate: referenceDate)
            }
        } else {
            return try fallbackIntent(from: trimmed, referenceDate: referenceDate)
        }
    }

    private func parseWithFoundationModels(from text: String, referenceDate: Date, language: AppLanguage) async throws -> CalendarIntent {
        let session = LanguageModelSession(instructions: """
        You convert calendar commands into structured event intents.
        Supported actions are add, modify, delete.
        Output concise calendar titles.
        Use ISO 8601 timestamps in the user's current timezone.
        If the user omitted an end time for add or modify, default to 60 minutes after the start.
        If time is ambiguous but there is a common-sense default, choose one.
        Preserve the user's language in the title and notes.
        If the user is deleting an event and the date or time is omitted, infer the closest likely match.
        Recurrence rule should be a concise natural-language string like weekly, daily, monthly.
        """)

        let nowString = fallbackFormatter.string(from: referenceDate)
        let prompt = """
        Current datetime: \(nowString)
        Current timezone: \(TimeZone.current.identifier)
        Preferred language: \(language.title)

        User request:
        \(text)
        """

        let response = try await session.respond(to: prompt, generating: GeneratedCalendarIntent.self)
        return CalendarIntent(
            action: CalendarAction(rawValue: response.content.action.lowercased()) ?? .add,
            title: response.content.title.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: parseISO(response.content.startISO),
            endDate: parseISO(response.content.endISO),
            isRecurring: response.content.isRecurring,
            recurrenceRule: response.content.recurrenceRule,
            location: response.content.location,
            notes: response.content.notes,
            originalText: text
        )
    }

    private func parseISO(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        return isoFormatter.date(from: value) ?? fallbackFormatter.date(from: value)
    }

    private func fallbackIntent(from text: String, referenceDate: Date) throws -> CalendarIntent {
        let action = inferAction(from: text)
        let startDate = inferStartDate(from: text, referenceDate: referenceDate)
        let duration = inferDuration(from: text)
        let title = inferTitle(from: text, action: action)
        let endDate = startDate.map { $0.addingTimeInterval(duration) }
        let recurrence = inferRecurrence(from: text)

        return CalendarIntent(
            action: action,
            title: title,
            startDate: startDate,
            endDate: action == .delete ? nil : endDate,
            isRecurring: recurrence != nil,
            recurrenceRule: recurrence,
            location: nil,
            notes: text,
            originalText: text
        )
    }

    private func inferAction(from text: String) -> CalendarAction {
        let lowercased = text.lowercased()
        if lowercased.contains("删除") || lowercased.contains("取消") || lowercased.contains("delete") || lowercased.contains("remove") {
            return .delete
        }
        if lowercased.contains("修改") || lowercased.contains("改到") || lowercased.contains("改成") || lowercased.contains("改为") || lowercased.contains("move") || lowercased.contains("reschedule") {
            return .modify
        }
        return .add
    }

    private func inferStartDate(from text: String, referenceDate: Date) -> Date? {
        let calendar = Calendar.current
        let lowercased = text.lowercased()
        var dayOffset = 0

        if lowercased.contains("明天") || lowercased.contains("tomorrow") {
            dayOffset = 1
        } else if lowercased.contains("后天") || lowercased.contains("day after tomorrow") {
            dayOffset = 2
        } else if lowercased.contains("昨天") {
            dayOffset = -1
        }

        let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: DateUtils.startOfDay(referenceDate)) ?? referenceDate
        let pattern = #"(?:^|[^\d])(\d{1,2})(?::(\d{2}))?"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let match = regex?.firstMatch(in: text, options: [], range: nsRange)

        var hour = 9
        var minute = 0

        if let match,
           let hourRange = Range(match.range(at: 1), in: text) {
            hour = Int(text[hourRange]) ?? hour
            if let minuteRange = Range(match.range(at: 2), in: text) {
                minute = Int(text[minuteRange]) ?? 0
            }
        }

        let containsPMHint = lowercased.contains("下午")
            || lowercased.contains("晚上")
            || lowercased.contains("傍晚")
            || lowercased.contains("pm")
            || lowercased.contains("evening")
            || lowercased.contains("afternoon")

        if containsPMHint && hour < 12 {
            hour += 12
        }

        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate)
    }

    private func inferDuration(from text: String) -> TimeInterval {
        let lowercased = text.lowercased()

        if let hourMatch = lowercased.range(of: #"(\d+)\s*(小时|hour|hours)"#, options: .regularExpression) {
            let raw = lowercased[hourMatch]
            let digits = raw.filter(\.isNumber)
            return Double(digits).map { $0 * 3600 } ?? 3600
        }

        if let minuteMatch = lowercased.range(of: #"(\d+)\s*(分钟|minute|minutes|mins)"#, options: .regularExpression) {
            let raw = lowercased[minuteMatch]
            let digits = raw.filter(\.isNumber)
            return Double(digits).map { $0 * 60 } ?? 3600
        }

        return 3600
    }

    private func inferRecurrence(from text: String) -> String? {
        let lowercased = text.lowercased()
        if lowercased.contains("每天") || lowercased.contains("daily") {
            return "daily"
        }
        if lowercased.contains("每周") || lowercased.contains("weekly") || lowercased.contains("每星期") {
            return "weekly"
        }
        if lowercased.contains("每月") || lowercased.contains("monthly") {
            return "monthly"
        }
        return nil
    }

    private func inferTitle(from text: String, action: CalendarAction) -> String {
        var candidate = text
        let removablePhrases = [
            "请帮我", "帮我", "安排", "添加", "新增", "创建", "删除", "取消", "修改", "改到", "改成",
            "please", "add", "schedule", "create", "delete", "remove", "modify", "move", "reschedule"
        ]

        removablePhrases.forEach { phrase in
            candidate = candidate.replacingOccurrences(of: phrase, with: "", options: .caseInsensitive)
        }

        candidate = candidate.replacingOccurrences(of: #"今天|明天|后天|tomorrow|today|day after tomorrow"#, with: "", options: .regularExpression)
        candidate = candidate.replacingOccurrences(of: #"\d{1,2}(:\d{2})?"#, with: "", options: .regularExpression)
        candidate = candidate.replacingOccurrences(of: #"下午|上午|晚上|pm|am|hour|hours|分钟|小时"#, with: "", options: .regularExpression)
        candidate = candidate.replacingOccurrences(of: "和", with: " ")
        candidate = candidate.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))

        if candidate.isEmpty {
            switch action {
            case .add:
                return "New Event"
            case .delete:
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            case .modify:
                return "Scheduled Event"
            }
        }

        return candidate
    }
}
