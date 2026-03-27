import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("preferredLanguage") private var preferredLanguage = AppLanguage.chinese.rawValue

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainCalendarScreen(initialLanguage: AppLanguage(rawValue: preferredLanguage) ?? .chinese)
            } else {
                OnboardingFlowView(
                    selectedLanguage: AppLanguage(rawValue: preferredLanguage) ?? .chinese,
                    onFinish: { language in
                        preferredLanguage = language.rawValue
                        hasCompletedOnboarding = true
                    }
                )
            }
        }
    }
}

#Preview {
    RootView()
}
