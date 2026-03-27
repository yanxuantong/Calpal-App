import Foundation

enum CalendarAction: String, Codable {
    case add
    case delete
    case modify
}

struct CalendarIntent: Codable, Hashable {
    let action: CalendarAction
    let title: String
    let startDate: Date?
    let endDate: Date?
    let isRecurring: Bool
    let recurrenceRule: String?
    let location: String?
    let notes: String?
    let originalText: String
}

struct CalendarExecutionResult {
    let message: String
    let affectedTitle: String
}

enum CalendarIntentError: LocalizedError {
    case emptyInput
    case unsupportedAction
    case missingCalendarAccess
    case missingTitle
    case missingStartDate
    case eventNotFound
    case localAINotAvailable(String)
    case speechRecognizerUnavailable
    case speechRecognizerTemporarilyUnavailable(String)
    case speechAuthorizationDenied
    case microphonePermissionDenied
    case recordingAlreadyInProgress
    case noTranscription

    func message(in language: AppLanguage) -> String {
        switch self {
        case .emptyInput:
            return language.ui("请输入一句完整的话，告诉我你想安排什么日程。", "Please describe the event in one complete sentence.")
        case .unsupportedAction:
            return language.ui("暂时只支持新增、修改和删除日程。", "Only add, modify, and delete actions are supported for now.")
        case .missingCalendarAccess:
            return language.ui("还没有获得日历权限，无法写入 Apple Calendar。", "Calendar access is not granted yet, so CalPal can't write to Apple Calendar.")
        case .missingTitle:
            return language.ui("我没有识别出事件标题，请再说得具体一点。", "I couldn't detect the event title. Please be a little more specific.")
        case .missingStartDate:
            return language.ui("我没有识别出开始时间，请补充日期和时间。", "I couldn't detect the start time. Please include a date and time.")
        case .eventNotFound:
            return language.ui("没有找到要修改或删除的事件。", "I couldn't find the event to modify or delete.")
        case .localAINotAvailable(let detail):
            return detail
        case .speechRecognizerUnavailable:
            return language.ui("当前设备暂时无法使用语音识别。", "Speech recognition is currently unavailable on this device.")
        case .speechRecognizerTemporarilyUnavailable(let detail):
            return detail
        case .speechAuthorizationDenied:
            return language.ui("语音识别权限未开启。", "Speech recognition permission is not enabled.")
        case .microphonePermissionDenied:
            return language.ui("麦克风权限未开启。", "Microphone permission is not enabled.")
        case .recordingAlreadyInProgress:
            return language.ui("当前已经在录音中了。", "Recording is already in progress.")
        case .noTranscription:
            return language.ui("没有识别到有效语音，请再试一次。", "No valid speech was detected. Please try again.")
        }
    }

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "请输入一句完整的话，告诉我你想安排什么日程。"
        case .unsupportedAction:
            return "暂时只支持新增、修改和删除日程。"
        case .missingCalendarAccess:
            return "还没有获得日历权限，无法写入 Apple Calendar。"
        case .missingTitle:
            return "我没有识别出事件标题，请再说得具体一点。"
        case .missingStartDate:
            return "我没有识别出开始时间，请补充日期和时间。"
        case .eventNotFound:
            return "没有找到要修改或删除的事件。"
        case .localAINotAvailable(let detail):
            return detail
        case .speechRecognizerUnavailable:
            return "当前设备暂时无法使用语音识别。"
        case .speechRecognizerTemporarilyUnavailable(let detail):
            return detail
        case .speechAuthorizationDenied:
            return "语音识别权限未开启。"
        case .microphonePermissionDenied:
            return "麦克风权限未开启。"
        case .recordingAlreadyInProgress:
            return "当前已经在录音中了。"
        case .noTranscription:
            return "没有识别到有效语音，请再试一次。"
        }
    }
}
