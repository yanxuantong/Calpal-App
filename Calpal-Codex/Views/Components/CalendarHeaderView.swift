import SwiftUI

struct CalendarHeaderView: View {
    let language: AppLanguage
    let monthTitle: String
    let onTodayTap: () -> Void
    let onMenuTap: () -> Void

    var body: some View {
        HStack {
            Button(language.ui("今天", "Today"), action: onTodayTap)
                .font(.body.weight(.semibold))

            Spacer()

            Text(monthTitle)
                .font(.title3.weight(.semibold))

            Spacer()

            Button(action: onMenuTap) {
                Image(systemName: "line.3.horizontal")
                    .font(.title3.weight(.semibold))
                    .frame(width: 30, height: 30)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    CalendarHeaderView(language: .chinese, monthTitle: "2026年3月", onTodayTap: {}, onMenuTap: {})
}
