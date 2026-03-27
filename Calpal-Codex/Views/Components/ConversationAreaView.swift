import SwiftUI

struct ConversationAreaView: View {
    let context: ConversationContext

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(context.language.ui("对话", "Conversation"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CalendarTheme.subtleText)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(context.messages) { message in
                        ConversationBubbleView(message: message)
                    }
                }
                .padding(20)
            }

            HStack {
                Spacer()
                Circle()
                    .fill(CalendarTheme.accentBlue)
                    .frame(width: LayoutMetrics.compactFabSize, height: LayoutMetrics.compactFabSize)
                    .overlay(
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.white)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    ConversationAreaView(
        context: SampleCalendarData.makeConversation(
            variant: .review,
            language: .chinese,
            previewDate: .now,
            previewEvents: SampleCalendarData.makeEvents(anchorDate: .now)
        )
    )
}
