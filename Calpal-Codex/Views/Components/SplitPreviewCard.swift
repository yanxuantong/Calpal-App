import SwiftUI

struct SplitPreviewCard: View {
    let context: ConversationContext
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void
    let onTertiaryAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(context.variant.badgeTitle(in: context.language))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CalendarTheme.accentBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(CalendarTheme.suggestedFill, in: Capsule())

                Spacer()

                Text(DateUtils.monthTitle(for: context.previewDate, language: context.language))
                    .font(.subheadline)
                    .foregroundStyle(CalendarTheme.subtleText)
            }

            Text(context.previewTitle)
                .font(.title3.weight(.semibold))

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(context.previewEvents) { event in
                        EventBlockView(event: event)
                            .frame(height: 86)
                    }
                }
            }

            HStack(spacing: 10) {
                Button(context.actions.primaryTitle, action: onPrimaryAction)
                    .buttonStyle(.borderedProminent)
                    .tint(CalendarTheme.accentBlue)

                Button(context.actions.secondaryTitle, action: onSecondaryAction)
                    .buttonStyle(.bordered)

                Button(context.actions.tertiaryTitle, action: onTertiaryAction)
                    .buttonStyle(.bordered)
            }
            .controlSize(.large)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: .secondarySystemBackground))
    }
}

#Preview {
    SplitPreviewCard(
        context: SampleCalendarData.makeConversation(
            variant: .planning,
            language: .chinese,
            previewDate: .now,
            previewEvents: SampleCalendarData.makeEvents(anchorDate: .now).filter(\.isSuggested)
        ),
        onPrimaryAction: {},
        onSecondaryAction: {},
        onTertiaryAction: {}
    )
}
