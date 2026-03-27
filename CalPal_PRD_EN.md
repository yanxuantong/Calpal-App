# CalPal — Product Requirements Document

**Version:** v1.3  
**Date:** 2026-03-27  
**Author:** Shawn  
**Status:** Confirmed, ready for development  
**Related Docs:** `CalPal_UI_SPEC_EN.md` / `CalPal_SwiftUI_Guide_EN.md`

---

## 1. Product Positioning

### 1.1 One-line Description

CalPal is a privacy-first iPhone scheduling assistant powered by on-device AI. Version 1 focuses on validating the minimum useful loop:

`voice / text input -> on-device AI parsing -> Apple system calendar write`

### 1.2 Core Goals for V1

- Validate whether on-device AI parsing of natural-language scheduling requests is usable enough
- Validate whether push-to-talk voice interaction feels natural
- Validate whether the system calendar read/write loop is stable
- Deliver a lightweight but genuinely usable demo without any cloud AI dependency

### 1.3 What V1 Is Not Trying to Solve

- Deep long-term behavioral understanding
- Morning planning and evening review flows
- iPad-specific experience
- Cross-device sync
- Cloud AI fallback

### 1.4 Technical Feasibility Already Verified

The following have already been validated in working demos:

- Apple Foundation Models parsing natural language into structured calendar intent
- EventKit calendar read and write
- Apple Speech Recognition
- Push-to-talk FAB interaction
- Foundation Models loading correctly on supported devices with Apple Intelligence enabled

---

## 2. Target User

**V1 target:** single-user, US-based, iPhone-first  
**V2 direction:** expand into a more complete personal productivity assistant

### User Profile

- Bilingual user, primarily Chinese with optional English UI
- Heavy Apple Calendar user
- Sensitive to privacy risks from cloud AI and third-party SaaS
- Values input speed and scheduling efficiency over collaboration features

---

## 3. Scope

### 3.1 V1 MVP Features

#### F1: Voice + Text Input

- Primary interaction: push-to-talk voice input
  - press and hold to start recording
  - release to stop and submit
  - upward cancel gesture
- Secondary interaction: text input
  - tap to open a text field
  - useful when speech input is less precise
- Language support
  - single-language Chinese or English
  - selected during onboarding
  - mixed-language speech is out of scope for V1

#### F2: On-device AI Intent Parsing

V1 architecture is fully local:

```text
User input (voice / text)
        ↓
Foundation Models (on-device)
        ↓
CalendarIntent
        ├── success -> execute calendar strategy
        └── failure -> ask user to restate
```

Expected structured output:

```swift
@Generable
struct CalendarIntent {
    let action: String
    let title: String
    let startISO: String
    let endISO: String
    let isRecurring: Bool
    let recurrenceRule: String?
    let location: String?
    let notes: String?
}
```

Error handling:

- Foundation Models unavailable -> prompt the user to enable Apple Intelligence
- Parsing failure -> lightweight toast asking the user to rephrase
- No cloud fallback in V1

#### F3: Smart Write Strategy

| Scenario | Behavior |
|---|---|
| Clear add intent with no conflict | write directly |
| Conflicts with existing event | show confirmation sheet |
| First-time recurring event creation | show confirmation sheet |
| Involves another person | show confirmation sheet |
| Any deletion | always require confirmation |
| Recurring deletion | choose this event / future / all |

#### F4: Calendar Read / Write

- V1 is based on Apple's system calendar stack via EventKit
- Supports read, create, update, and delete
- No direct Google Calendar API integration in V1
- Writable target calendars can still include Google calendars already connected through iOS

#### F5: Onboarding

- Language selection
- Permission requests: calendar, microphone, speech recognition
- Apple Intelligence availability check
- Clear messaging when on-device AI is unavailable

#### F6: Basic Settings

- App / input language
- On-device AI status
- Calendar target selection
- Permissions and privacy explanation
- Claude API placeholder entry

### 3.2 V2 Features

- Morning review / briefing
- Evening review
- Habit analysis and preference modeling
- SwiftData persistence expansion
- CloudKit / iCloud sync
- iPad adaptation
- Local reminders
- Direct Google Calendar API support
- Claude API planning and review flows
- Siri shortcuts
- Widgets
- Mixed-language speech recognition
- More advanced recurrence parsing

### 3.3 Explicitly Out of Scope for V1

- Cloud AI fallback
- Review rituals
- Habit learning
- Cross-device synchronization
- Dedicated iPad UI
- Team calendars or multi-user collaboration
- Todo management
- User account system or backend
- Android

---

## 4. Technical Architecture

### 4.1 Technology Choices

| Layer | Technology | Requirement | V1 |
|---|---|---|---|
| UI | SwiftUI | iOS 18.4+ in original planning docs | Implemented |
| On-device AI | Apple Foundation Models | supported Apple Intelligence devices | Implemented |
| Speech | Apple Speech Recognition | iOS-supported | Implemented |
| Calendar | EventKit | iOS-supported | Implemented |
| Cloud AI | Anthropic Claude API | — | Placeholder only |
| Persistence | SwiftData | optional | Not required for V1 |
| Sync | CloudKit Private DB | — | V2 |

### 4.2 Recommended Project Shape

```text
CalPal/
├── App entry
├── Views/
├── ViewModels/
├── Services/
├── Models/
├── Support/
└── Resources/
```

### 4.3 Important Interfaces

```swift
protocol AIService {
    func parseIntent(_ input: String) async -> CalendarIntent?
}
```

Design notes:

- keep `AIService` as an abstraction for future extension
- use Foundation Models at runtime for V1
- keep Claude integration as a future-facing placeholder only

### 4.4 Known Risks and V1 Mitigation

| Risk | Priority | V1 Strategy |
|---|---|---|
| Foundation Models unavailable | High | show clear setup guidance |
| Parsing failure | Medium | ask user to restate |
| Recurrence instability | Medium | rely on confirmation sheet fallback |
| Calendar timezone bugs | Medium | centralize date handling |
| Speech recognition inaccuracies | Medium | offer text input fallback |

---

## 5. Primary User Flows

### 5.1 Add Event

```text
User presses and holds FAB
        ↓
Recording begins while calendar remains scrollable
        ↓
User releases
        ↓
Speech to text
        ↓
Foundation Models parsing
        ├── success -> CalendarIntent
        │       ├── no conflict -> direct write -> success toast
        │       └── conflict / recurring -> confirmation sheet
        └── failure -> ask user to rephrase
```

### 5.2 Delete Event

```text
User: cancel tomorrow afternoon's meeting
        ↓
Intent parser detects deletion
        ↓
Confirmation sheet
        ↓
Delete after explicit user confirmation
```

### 5.3 On-device AI Unavailable

```text
User launches app or attempts parsing
        ↓
Apple Intelligence unavailable
        ↓
Show setup guidance
```

---

## 6. Non-functional Requirements

| Metric | Goal |
|---|---|
| Speech response | < 1.5s |
| Intent parsing | < 2s on supported devices |
| EventKit operations | < 0.5s |
| Minimum platform | iPhone target only |
| Privacy | no third-party server dependency in V1 |

---

## 7. Milestones

### Phase 0: Technical Validation

- Foundation Models demo
- EventKit demo
- Speech Recognition demo
- FAB push-to-talk demo

### Phase 1: Core Structure

- main calendar view
- onboarding
- permissions
- settings

### Phase 2: Input and Parsing

- full FAB voice flow
- text input
- speech integration
- Foundation Models parsing

### Phase 3: Calendar Write Loop

- EventKit create / update / delete
- smart write strategy
- delete confirmation
- recurring event confirmation
- error messaging

### Phase 4: Integration and Polish

- Claude API placeholder
- device testing
- edge-case fixes
- UI polish

---

## 8. Acceptance and Testing

Required scenarios:

- first-launch permission chain
- Apple Intelligence available / unavailable
- speech success / cancel / failure
- text parse success / failure
- no-conflict direct event write
- delete confirmation
- recurring confirmation
- error and disabled-state consistency

Out of scope for V1 acceptance:

- cross-device sync
- habit modeling
- morning / evening review
- iPad support

---

## 9. Cost

| Item | Cost | Notes |
|---|---|---|
| Foundation Models | free | on-device |
| Speech Recognition | free | system service |
| Claude API | $0 in V1 | not used |
| Google Calendar API | $0 in V1 | not used directly |
| Apple Developer Program | $99 / year | required for device distribution |

---

## 10. Baseline Conclusion

- V1 is a minimal iPhone-first, on-device, calendar-centric product
- Success means the core loop is stable and usable, not that the assistant is already fully intelligent
- Cloud AI remains explicitly out of runtime scope in V1
