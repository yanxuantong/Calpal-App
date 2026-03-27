import SwiftUI

struct UnifiedConversationScreen: View {
    let context: ConversationContext
    let onPrimaryAction: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    SplitPreviewCard(
                        context: context,
                        onPrimaryAction: {
                            dismiss()
                            onPrimaryAction()
                        },
                        onSecondaryAction: {},
                        onTertiaryAction: { dismiss() }
                    )
                    .frame(height: proxy.size.height * LayoutMetrics.splitPreviewRatio)

                    Divider()
                        .overlay(CalendarTheme.accentBlue.frame(height: 2))

                    ConversationAreaView(context: context)
                }
                .background(Color(uiColor: .systemBackground))
            }
            .navigationTitle(context.variant.badgeTitle(in: context.language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(context.language.ui("关闭", "Close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    UnifiedConversationScreen(
        context: SampleCalendarData.makeConversation(
            variant: .planning,
            language: .chinese,
            previewDate: .now,
            previewEvents: SampleCalendarData.makeEvents(anchorDate: .now).filter(\.isSuggested)
        ),
        onPrimaryAction: {}
    )
}
