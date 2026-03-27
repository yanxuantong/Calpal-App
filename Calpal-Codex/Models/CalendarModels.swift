import Foundation
import SwiftUI

enum FABState {
    case idle
    case recording
    case processing
}

enum ConversationVariant: String, CaseIterable, Identifiable {
    case planning
    case review

    var id: String { rawValue }

    func badgeTitle(in language: AppLanguage) -> String {
        switch self {
        case .planning:
            return language.ui("规划建议", "Planning")
        case .review:
            return language.ui("复盘建议", "Review")
        }
    }
}

enum InputMode: String, CaseIterable, Identifiable {
    case voice
    case text

    var id: String { rawValue }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese
    case english

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chinese:
            return "中文"
        case .english:
            return "English"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .chinese:
            return "zh_CN"
        case .english:
            return "en_US"
        }
    }
}

enum PermissionState: String {
    case ready
    case needsAttention

    func title(in language: AppLanguage) -> String {
        switch self {
        case .ready:
            return language.ui("已启用", "Enabled")
        case .needsAttention:
            return language.ui("待开启", "Needs Setup")
        }
    }

    var color: Color {
        switch self {
        case .ready:
            return .green
        case .needsAttention:
            return .orange
        }
    }
}

struct DayPage: Identifiable, Hashable {
    let date: Date
    let hasEvents: Bool

    var id: Date { Calendar.current.startOfDay(for: date) }
}

struct WritableCalendarOption: Identifiable, Hashable {
    let id: String
    let title: String
    let sourceTitle: String
    let isDefault: Bool
}

struct CalendarEventUIModel: Identifiable, Hashable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let color: Color
    let isSuggested: Bool
    let isRecurring: Bool
    let location: String?
    let calendarName: String

    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}

struct ConversationBubble: Identifiable, Hashable {
    let id = UUID()
    let sender: BubbleSender
    let text: String
}

enum BubbleSender: Hashable {
    case assistant
    case user
}

struct ConversationActionSet: Hashable {
    let primaryTitle: String
    let secondaryTitle: String
    let tertiaryTitle: String
}

struct ConversationContext: Identifiable, Hashable {
    let id = UUID()
    let variant: ConversationVariant
    let language: AppLanguage
    let previewTitle: String
    let previewDate: Date
    let previewEvents: [CalendarEventUIModel]
    let messages: [ConversationBubble]
    let actions: ConversationActionSet
}

struct ConfirmationContext: Identifiable, Hashable {
    enum Style: Hashable {
        case add
        case delete
        case recurringDelete
    }

    let id = UUID()
    let style: Style
    let title: String
    let subtitle: String
    let eventTitle: String
    let detail: String
}
