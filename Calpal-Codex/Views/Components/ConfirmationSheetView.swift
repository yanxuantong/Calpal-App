import SwiftUI

struct ConfirmationSheetView: View {
    let language: AppLanguage
    let context: ConfirmationContext
    @Binding var editableTitle: String
    @Binding var editableStartDate: Date
    @Binding var editableEndDate: Date
    let showsEditor: Bool
    let onPrimaryAction: () -> Void
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(CalendarTheme.tertiaryFill)
                .frame(width: 42, height: 5)
                .padding(.top, 10)

            VStack(alignment: .leading, spacing: 8) {
                Text(context.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(titleColor)

                Text(context.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(CalendarTheme.subtleText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsEditor {
                VStack(alignment: .leading, spacing: 12) {
                    TextField(language.ui("事件标题", "Event title"), text: $editableTitle)
                        .textFieldStyle(.roundedBorder)

                    DatePicker(language.ui("日期", "Date"), selection: $editableStartDate, displayedComponents: .date)
                        .datePickerStyle(.compact)

                    HStack(spacing: 12) {
                        DatePicker(language.ui("开始", "Start"), selection: $editableStartDate, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                        DatePicker(language.ui("结束", "End"), selection: $editableEndDate, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(context.eventTitle)
                        .font(.headline)
                    Text(context.detail)
                        .font(.subheadline)
                        .foregroundStyle(CalendarTheme.subtleText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            VStack(spacing: 10) {
                switch context.style {
                case .add:
                    actionButton(language.ui("确认添加", "Confirm Add"), tint: CalendarTheme.accentBlue, action: onPrimaryAction)
                    inlineButtons(second: language.ui("稍后处理", "Later"), third: language.ui("取消", "Cancel"))
                case .delete:
                    actionButton(language.ui("删除事件", "Delete Event"), tint: CalendarTheme.currentTimeRed, action: onPrimaryAction)
                    actionButton(language.ui("取消", "Cancel"), tint: .gray, filled: false, action: onDismiss)
                case .recurringDelete:
                    actionButton(language.ui("仅删除此次", "Delete This Event"), tint: CalendarTheme.currentTimeRed, filled: false, action: onPrimaryAction)
                    actionButton(language.ui("删除此后所有", "Delete This and Future"), tint: CalendarTheme.currentTimeRed, filled: false, action: onPrimaryAction)
                    actionButton(language.ui("删除全部", "Delete All"), tint: CalendarTheme.currentTimeRed, action: onPrimaryAction)
                    actionButton(language.ui("取消", "Cancel"), tint: .gray, filled: false, action: onDismiss)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color(uiColor: .systemBackground))
    }

    private var titleColor: Color {
        switch context.style {
        case .add:
            return CalendarTheme.accentBlue
        case .delete, .recurringDelete:
            return CalendarTheme.currentTimeRed
        }
    }

    private func actionButton(_ title: String, tint: Color, filled: Bool = true, action: @escaping () -> Void) -> some View {
        Group {
            if filled {
                Button(title) {
                    dismiss()
                    action()
                }
                .buttonStyle(.borderedProminent)
                .tint(tint)
            } else {
                Button(title) {
                    dismiss()
                    action()
                }
                .buttonStyle(.bordered)
                .tint(tint)
            }
        }
        .frame(maxWidth: .infinity)
        .controlSize(.large)
    }

    private func inlineButtons(second: String, third: String) -> some View {
        HStack(spacing: 10) {
            actionButton(second, tint: .gray, filled: false, action: onDismiss)
            actionButton(third, tint: .gray, filled: false, action: onDismiss)
        }
    }
}

#Preview {
    ConfirmationSheetView(
        language: .chinese,
        context: ConfirmationContext(
            style: .add,
            title: "✦ 添加事件",
            subtitle: "无冲突，可直接写入 Apple Calendar",
            eventTitle: "深度工作",
            detail: "3月27日 · 下午 1:30-3:00"
        ),
        editableTitle: .constant("深度工作"),
        editableStartDate: .constant(.now),
        editableEndDate: .constant(.now.addingTimeInterval(3600)),
        showsEditor: true,
        onPrimaryAction: {},
        onDismiss: {}
    )
}
