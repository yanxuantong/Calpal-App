# CalPal — SwiftUI Implementation Guide

**Version:** v1.0  
**Date:** 2026-03-27  
**Related Docs:** `CalPal_PRD_EN.md` / `CalPal_UI_SPEC_EN.md`

---

## 1. Goal

This guide translates the approved product and UI direction into a SwiftUI implementation structure, so engineering can move quickly without repeatedly re-deciding the information architecture.

Version 1 focuses on three groups of screens:

- main calendar screen
- unified split-view conversation screen
- onboarding and settings

---

## 2. Recommended View Structure

```text
CalPalApp
└── RootView
    ├── MainCalendarScreen
    ├── UnifiedConversationScreen
    ├── OnboardingFlowView
    └── SettingsView
```

Recommended decomposition:

```text
Views/
├── Screens/
│   ├── MainCalendarScreen.swift
│   ├── UnifiedConversationScreen.swift
│   ├── OnboardingFlowView.swift
│   └── SettingsView.swift
├── Components/
│   ├── CalendarHeaderView.swift
│   ├── DatePagerView.swift
│   ├── TimelineView.swift
│   ├── EventBlockView.swift
│   ├── FloatingInputBar.swift
│   ├── SplitPreviewCard.swift
│   ├── ConversationBubbleView.swift
│   └── ConfirmationSheetView.swift
└── Support/
    ├── CalendarTheme.swift
    └── LayoutMetrics.swift
```

---

## 3. Important State Models

```swift
enum FABState {
    case idle
    case recording
    case processing
}

enum ConversationVariant {
    case planning
    case review
}

struct DayPage: Identifiable, Hashable {
    let id: Date
    let date: Date
    let hasEvents: Bool
}

struct CalendarEventUIModel: Identifiable, Hashable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let color: Color
    let isSuggested: Bool
}
```

Suggested screen model:

```swift
@Observable
final class CalendarScreenModel {
    var selectedDate: Date = .now
    var visibleDates: [DayPage] = []
    var events: [CalendarEventUIModel] = []
    var fabState: FABState = .idle
    var showingTextInput = false
    var activeConversation: ConversationContext?
}
```

Key principles:

- `DatePagerView` and `TimelineView` share a single selected date
- split-view previews reuse the same `CalendarEventUIModel`
- recording is a UI state, not a separate screen model

---

## 4. Main Calendar Screen Guidance

### 4.1 MainCalendarScreen

Recommended structure:

```swift
struct MainCalendarScreen: View {
    @State private var model = CalendarScreenModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            background

            VStack(spacing: 0) {
                CalendarHeaderView(...)
                DatePagerView(...)
                TimelineView(...)
            }

            FloatingInputBar(...)
        }
    }
}
```

### 4.2 DatePagerView

Guidelines:

- use a compact horizontally swipable structure
- avoid oversized cards
- selected day gets a clear but restrained circular highlight
- keep motion close to system calendar behavior

### 4.3 TimelineView

Guidelines:

- vertical scrolling
- fixed hourly height
- calculated event positioning
- current-time line as an overlay
- no full-screen overlay that blocks scrolling during recording

---

## 5. Unified Conversation Screen

`UnifiedConversationScreen` is the single V1 conversation template.

```swift
struct UnifiedConversationScreen: View {
    let context: ConversationContext

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            SplitPreviewCard(...)
            Divider()
            conversationArea
        }
    }
}
```

### 5.1 Variants

Planning:

- proactive tone
- preview focuses on open time blocks
- common actions: Apply / Adjust Time / Skip

Review:

- reflective tone
- preview focuses on rescheduling or recovery opportunities
- common actions: Apply / Later / Ignore

### 5.2 Visual Rules

- upper preview should visually match the timeline event style
- lower conversation area should stay lightweight
- avoid making it feel like a messaging app

---

## 6. Onboarding and Settings

### OnboardingFlowView

- use a controlled multi-step flow
- one clear task per step
- language selection should also determine UI language

### SettingsView

V1 settings should include:

- app / input language
- writable calendar target
- on-device AI status
- Claude placeholder
- permissions and privacy notes

---

## 7. Code Quality and Implementation Details

- centralize colors, spacing, and sizing in theme / metrics helpers
- keep EventKit logic in service layer rather than views
- keep `EventBlockView` independent from direct EventKit types
- inject conversation result context into `UnifiedConversationScreen`
- avoid coupling UI components directly to Foundation Models

---

## 8. Recommended Build Order

1. Build the `MainCalendarScreen` skeleton
2. Implement `DatePagerView`
3. Implement `TimelineView` and event layout
4. Add `FloatingInputBar` and recording states
5. Implement `UnifiedConversationScreen`
6. Finish onboarding and settings

This prioritizes the most important V1 path:

```text
Main calendar -> input -> on-device parsing -> confirmation -> calendar write
```
