import SwiftUI

struct OnboardingFlowView: View {
    @State private var currentStep = 0
    @State private var language: AppLanguage
    @State private var isRequestingPermissions = false
    let onFinish: (AppLanguage) -> Void

    init(selectedLanguage: AppLanguage, onFinish: @escaping (AppLanguage) -> Void) {
        _language = State(initialValue: selectedLanguage)
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentStep) {
                OnboardingIntroStep(language: $language)
                    .tag(0)
                OnboardingPermissionStep(language: language)
                    .tag(1)
                OnboardingAIStatusStep(language: language)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == currentStep ? CalendarTheme.accentBlue : CalendarTheme.tertiaryFill)
                            .frame(width: index == currentStep ? 26 : 8, height: 8)
                    }
                }

                Button(currentStep == 2 ? language.ui("开始使用", "Get Started") : language.ui("继续", "Continue")) {
                    if currentStep == 1 {
                        isRequestingPermissions = true
                        Task {
                            await PermissionBootstrap.requestPhaseOnePermissions()
                            await MainActor.run {
                                isRequestingPermissions = false
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                                    currentStep += 1
                                }
                            }
                        }
                    } else if currentStep == 2 {
                        onFinish(language)
                    } else {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                            currentStep += 1
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(CalendarTheme.accentBlue)
                .controlSize(.large)
                .disabled(isRequestingPermissions)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

private struct OnboardingIntroStep: View {
    @Binding var language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 32)

            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(CalendarTheme.accentBlue)

                Text("CalPal")
                    .font(.largeTitle.bold())

                Text(language.ui("本地 AI 驱动的私人日程助理，专注把一句话快速变成 Apple Calendar 里的事件。", "A private on-device scheduling assistant that turns one sentence into an Apple Calendar event."))
                    .font(.title3)
                    .foregroundStyle(CalendarTheme.subtleText)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text(language.ui("选择界面语言", "Choose App Language"))
                    .font(.headline)

                Picker(language.ui("语言", "Language"), selection: $language) {
                    ForEach(AppLanguage.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                FeatureCallout(title: language.ui("语音优先", "Voice First"), subtitle: language.ui("长按说一句，松手自动提交识别结果。", "Press and hold to speak, then release to submit the transcript automatically."))
                FeatureCallout(title: language.ui("隐私优先", "Privacy First"), subtitle: language.ui("V1 全程本地处理，不走任何云端 AI。", "Version 1 keeps the full loop on device without cloud AI."))
                FeatureCallout(title: language.ui("日历优先", "Calendar First"), subtitle: language.ui("写入、修改、删除全部围绕 Apple Calendar。", "Adding, editing, and deleting all center around Apple Calendar."))
            }

            Spacer()
        }
        .padding(24)
    }
}

private struct OnboardingPermissionStep: View {
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer(minLength: 32)

            Text(language.ui("只申请三项必要权限", "Only Three Essential Permissions"))
                .font(.largeTitle.bold())

            Text(language.ui("phase 1 只聚焦最小可用闭环，所以不会额外请求联系人、定位或通知权限。", "Phase 1 focuses on the minimum usable loop, so it won't request contacts, location, or notifications."))
                .font(.body)
                .foregroundStyle(CalendarTheme.subtleText)

            VStack(spacing: 14) {
                PermissionCard(icon: "calendar", title: language.ui("日历", "Calendar"), detail: language.ui("读取和写入 Apple Calendar 事件", "Read and write Apple Calendar events"), state: .ready, language: language)
                PermissionCard(icon: "mic.fill", title: language.ui("麦克风", "Microphone"), detail: language.ui("支持长按 PTT 语音输入", "Support push-to-talk voice input"), state: .ready, language: language)
                PermissionCard(icon: "waveform", title: language.ui("语音识别", "Speech Recognition"), detail: language.ui("将中文或英文语音转换为文本", "Convert spoken Chinese or English into text"), state: .ready, language: language)
            }

            Spacer()
        }
        .padding(24)
    }
}

private struct OnboardingAIStatusStep: View {
    let language: AppLanguage

    var body: some View {
        let aiStatus = AIIntentParser().availabilitySummary(language: language)
        VStack(alignment: .leading, spacing: 20) {
            Spacer(minLength: 32)

            Text(language.ui("检查本地 AI 状态", "Check On-Device AI"))
                .font(.largeTitle.bold())

            Text(language.ui("CalPal 的解析能力依赖 Apple Intelligence。若设备未开启，V1 只会保留界面与本地日历浏览能力。", "CalPal's parsing depends on Apple Intelligence. If it isn't enabled, Phase 1 will keep only the interface and local calendar browsing."))
                .foregroundStyle(CalendarTheme.subtleText)

            VStack(alignment: .leading, spacing: 14) {
                StatusRow(title: "Apple Intelligence", state: aiStatus.0, detail: aiStatus.1, language: language)
                StatusRow(title: "Claude API", state: .needsAttention, detail: language.ui("仅保留入口占位，phase 1 不启用", "Placeholder only. Not enabled in Phase 1"), language: language)
            }
            .padding(18)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text(language.ui("你可以先体验完整的本地闭环，后续再接入更复杂的规划与复盘能力。", "You can start with the complete local loop first, then add richer planning and review features later."))
                .font(.footnote)
                .foregroundStyle(CalendarTheme.subtleText)

            Spacer()
        }
        .padding(24)
    }
}

private struct FeatureCallout: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .foregroundStyle(CalendarTheme.subtleText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct PermissionCard: View {
    let icon: String
    let title: String
    let detail: String
    let state: PermissionState
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 34, height: 34)
                .foregroundStyle(CalendarTheme.accentBlue)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(CalendarTheme.subtleText)
            }

            Spacer()

            Text(state.title(in: language))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(state.color)
        }
        .padding(18)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct StatusRow: View {
    let title: String
    let state: PermissionState
    let detail: String
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Label(state.title(in: language), systemImage: state == .ready ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(state.color)
            }
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(CalendarTheme.subtleText)
        }
    }
}

#Preview {
    OnboardingFlowView(selectedLanguage: .chinese, onFinish: { _ in })
}
