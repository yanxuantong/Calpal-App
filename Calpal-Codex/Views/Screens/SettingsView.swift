import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("preferredLanguage") private var storedLanguage = AppLanguage.chinese.rawValue
    @State private var selectedLanguage: AppLanguage
    @State private var selectedCalendarIdentifier: String
    let calendarPermission: PermissionState
    let speechPermission: PermissionState
    let microphonePermission: PermissionState
    let localAIStatusText: String
    let writableCalendars: [WritableCalendarOption]
    let onCalendarSelection: (String) -> Void

    init(
        selectedLanguage: AppLanguage,
        calendarPermission: PermissionState,
        speechPermission: PermissionState,
        microphonePermission: PermissionState,
        localAIStatusText: String,
        writableCalendars: [WritableCalendarOption],
        selectedCalendarIdentifier: String,
        onCalendarSelection: @escaping (String) -> Void
    ) {
        _selectedLanguage = State(initialValue: selectedLanguage)
        _selectedCalendarIdentifier = State(initialValue: selectedCalendarIdentifier)
        self.calendarPermission = calendarPermission
        self.speechPermission = speechPermission
        self.microphonePermission = microphonePermission
        self.localAIStatusText = localAIStatusText
        self.writableCalendars = writableCalendars
        self.onCalendarSelection = onCalendarSelection
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(selectedLanguage.ui("日历", "Calendar")) {
                    SettingsRow(title: selectedLanguage.ui("已连接日历", "Connected Calendar"), value: "Apple Calendar")

                    Picker(selectedLanguage.ui("默认写入日历", "Default Write Calendar"), selection: $selectedCalendarIdentifier) {
                        Text(selectedLanguage.ui("跟随系统默认", "Follow System Default"))
                            .tag("__system_default__")

                        ForEach(writableCalendars) { calendar in
                            Text(calendarLabel(for: calendar))
                                .tag(calendar.id)
                        }
                    }
                    .onChange(of: selectedCalendarIdentifier) { _, newValue in
                        onCalendarSelection(newValue)
                    }
                }

                Section(selectedLanguage.ui("AI 设置", "AI")) {
                    Picker(selectedLanguage.ui("界面与输入语言", "App and Input Language"), selection: $selectedLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.title).tag(language)
                        }
                    }
                    .onChange(of: selectedLanguage) { _, newValue in
                        storedLanguage = newValue.rawValue
                    }

                    SettingsRow(title: selectedLanguage.ui("本地 AI 状态", "On-device AI"), value: localAIStatusText)
                    SettingsRow(title: "Claude API", value: selectedLanguage.ui("占位入口", "Placeholder"))
                        .foregroundStyle(CalendarTheme.subtleText)
                }

                Section(selectedLanguage.ui("权限与隐私", "Permissions & Privacy")) {
                    SettingsRow(title: selectedLanguage.ui("数据存储", "Data Storage"), value: selectedLanguage.ui("仅本地", "Local only"))
                    SettingsRow(title: selectedLanguage.ui("日历权限", "Calendar Permission"), value: calendarPermission.title(in: selectedLanguage))
                    SettingsRow(title: selectedLanguage.ui("麦克风权限", "Microphone Permission"), value: microphonePermission.title(in: selectedLanguage))
                    SettingsRow(title: selectedLanguage.ui("语音识别权限", "Speech Recognition Permission"), value: speechPermission.title(in: selectedLanguage))
                    SettingsRow(title: selectedLanguage.ui("隐私说明", "Privacy"), value: selectedLanguage.ui("不上传语音与日历内容", "Voice and calendar content stay on device"))
                }
            }
            .navigationTitle(selectedLanguage.ui("设置", "Settings"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(selectedLanguage.ui("完成", "Done")) { dismiss() }
                }
            }
        }
    }
}

private extension SettingsView {
    func calendarLabel(for calendar: WritableCalendarOption) -> String {
        if calendar.isDefault {
            return "\(calendar.title) · \(calendar.sourceTitle) (\(selectedLanguage.ui("系统默认", "Default")))"
        }
        return "\(calendar.title) · \(calendar.sourceTitle)"
    }
}

private struct SettingsRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(CalendarTheme.subtleText)
        }
    }
}

#Preview {
    SettingsView(
        selectedLanguage: .chinese,
        calendarPermission: .ready,
        speechPermission: .ready,
        microphonePermission: .needsAttention,
        localAIStatusText: "已启用",
        writableCalendars: [],
        selectedCalendarIdentifier: "__system_default__",
        onCalendarSelection: { _ in }
    )
}
