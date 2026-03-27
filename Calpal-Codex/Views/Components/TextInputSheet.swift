import SwiftUI

struct TextInputSheet: View {
    let language: AppLanguage
    @Binding var textDraft: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(language.ui("用一句自然语言描述你的日程", "Describe your event in natural language"))
                    .font(.headline)

                TextField(language.ui("例如：明天下午 2 点和产品团队开会 1 小时", "For example: Meet with the product team tomorrow at 2 PM for 1 hour"), text: $textDraft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)

                Text(language.ui("Phase 1 目前优先打通本地解析与 EventKit 闭环。", "Phase 1 currently focuses on the local parsing and EventKit loop."))
                    .font(.footnote)
                    .foregroundStyle(CalendarTheme.subtleText)

                Spacer()
            }
            .padding(20)
            .navigationTitle(language.ui("输入", "Type"))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(language.ui("取消", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(language.ui("提交", "Submit")) {
                        dismiss()
                        onSubmit()
                    }
                    .disabled(textDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    TextInputSheet(language: .chinese, textDraft: .constant("明天下午 2 点和产品团队开会"), onSubmit: {})
}
