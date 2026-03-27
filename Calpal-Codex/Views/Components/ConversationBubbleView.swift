import SwiftUI

struct ConversationBubbleView: View {
    let message: ConversationBubble

    var body: some View {
        HStack {
            if message.sender == .user {
                Spacer(minLength: 40)
            }

            bubbleText

            if message.sender == .assistant {
                Spacer(minLength: 40)
            }
        }
    }

    private var bubbleText: some View {
        Text(message.text)
            .font(.body)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: 280, alignment: message.sender == .assistant ? .leading : .trailing)
            .background(background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var background: Color {
        message.sender == .assistant ? Color(uiColor: .secondarySystemBackground) : CalendarTheme.accentBlue.opacity(0.18)
    }
}

#Preview {
    VStack {
        ConversationBubbleView(message: ConversationBubble(sender: .assistant, text: "我建议你保留这段空档。"))
        ConversationBubbleView(message: ConversationBubble(sender: .user, text: "好，先这么安排。"))
    }
    .padding()
}
