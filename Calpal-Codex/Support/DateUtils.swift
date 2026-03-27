import Foundation

enum DateUtils {
    static let calendar = Calendar.current

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func monthTitle(for date: Date, language: AppLanguage = .chinese) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.dateFormat = language == .chinese ? "yyyy年M月" : "MMMM yyyy"
        return formatter.string(from: date)
    }

    static func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    static func weekdaySymbol(for date: Date, language: AppLanguage = .chinese) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    static func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm"
        return formatter.string(from: date)
    }

    static func meridiem(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "a"
        return formatter.string(from: date)
    }

    static func eventTimeRange(start: Date, end: Date, language: AppLanguage = .chinese) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.dateFormat = language == .chinese ? "a h:mm" : "h:mm a"
        return "\(formatter.string(from: start))-\(formatter.string(from: end))"
    }

    static func sheetDetail(start: Date, end: Date, language: AppLanguage = .chinese) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.dateFormat = language == .chinese ? "M月d日 · a h:mm" : "MMM d · h:mm a"
        let endFormatter = DateFormatter()
        endFormatter.locale = Locale(identifier: language.localeIdentifier)
        endFormatter.dateFormat = "h:mm"
        return "\(formatter.string(from: start))-\(endFormatter.string(from: end))"
    }
}
