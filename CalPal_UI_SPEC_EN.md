# CalPal — UI Design Specification

**Version:** v1.1  
**Date:** 2026-03-27  
**Related Docs:** `CalPal_PRD_EN.md` / `CalPal_SwiftUI_Guide_EN.md`

---

## 1. Design Principles

- Follow the iOS system visual language
- Calendar first, AI second
- Voice first, text as support
- Keep V1 intentionally restrained
- Stay close to the mental model of Apple's Calendar app
- Respect safe areas for all interactive elements

Note: the original design direction avoided Liquid Glass for V1. The implemented prototype now selectively experiments with more system-native motion and glass-style presentation where appropriate.

---

## 2. Color System

| Usage | Color | Notes |
|---|---|---|
| Accent / primary action | `#4A7FD4` | close to familiar calendar blue |
| Current time line | `#E24B4A` | consistent with system calendar red |
| Recording active | `#E24B4A` | input button turns red while recording |
| Suggested event highlight | blue border + pale blue fill | differentiate previewed actions |
| Calendar events | follow source calendar color | from EventKit |
| Background | system adaptive colors | light and dark mode |
| Text | semantic system text colors | adaptive |

---

## 3. Core Screens

### 3.1 Main Calendar View

Top-to-bottom structure:

- status bar
- navigation bar
- compact date pager
- vertical timeline
- floating primary input control

Navigation bar:

- left: Today
- center: month title
- right: settings / menu

Date pager:

- compact and close to the system calendar feel
- selected date uses a blue circular highlight
- nearby dates remain visually light
- event dots appear with minimal emphasis
- horizontal swipe should feel like natural day paging

Timeline:

- hourly markers on the left
- 60pt per hour
- event blocks use rounded corners and source color
- current time line uses a red line and dot
- remain scrollable even during recording

Floating input button:

- current implementation is centered near the bottom
- tap for text
- hold and drag for voice
- release to end recording and begin recognition
- animated return to the resting position

### 3.2 Push-to-talk Recording State

When recording begins:

- button shifts from blue to red
- icon changes from mic to waveform
- outer pulse layers suggest active listening
- a small top hint shows release-to-finish guidance
- the calendar remains visible and usable

When recording ends:

- stop capture
- convert voice to text
- parse intent
- return button to its anchor with a spring animation

### 3.3 Confirmation Sheet

Used for:

- conflicting writes
- recurring event creation
- deletions
- ambiguous edits

Design rules:

- bottom sheet presentation
- editable title / date / time when needed
- strong primary action
- deletion flows use red emphasis

### 3.4 Unified Split View

This is the single V1 conversation layout for recommendation-style flows.

Upper area:

- focused calendar preview
- suggested or previewed event blocks
- compact action row

Lower area:

- lightweight conversation transcript
- no heavy chat-app styling

Use cases:

- planning recommendation
- review / rescheduling recommendation

### 3.5 Settings

Current settings priorities:

- app and input language
- target writable calendar
- on-device AI state
- permissions
- privacy explanation

### 3.6 Onboarding

Three-step structure:

- language selection
- permissions
- Apple Intelligence / on-device AI readiness

---

## 4. Interaction Rules

### 4.1 Gestures

| Gesture | Area | Result |
|---|---|---|
| quick tap | main input button | open text input |
| long press | main input button | start recording |
| drag while holding | main input button | keep recording while following thumb |
| release | main input button | stop recording and submit |
| vertical scroll | timeline | browse hours |
| horizontal swipe | date pager / timeline | switch days |
| sheet pull-down | confirmation sheet | dismiss |
| tap event block | timeline | open event details when supported |

### 4.2 Feedback

| Action | Haptic | Visual |
|---|---|---|
| recording start | medium impact | button turns red |
| recording end | light impact | button returns and starts processing |
| event write success | success notification | toast |
| event delete success | warning or success | toast |
| parse failure | error notification | lightweight toast |

### 4.3 Toast Rules

- top of the screen
- non-blocking
- auto-dismiss
- light, rounded, system-material style

---

## 5. Component Rules

### 5.1 Main Input Button States

```swift
enum FABState {
    case idle
    case recording
    case processing
}
```

### 5.2 Event Blocks

- block height should be derived from duration with a minimum tap target
- extremely short events may omit time text
- long titles truncate cleanly
- recurring and suggested events should remain visually distinct

### 5.3 Confirmation Sheet Height

- approximately 240pt minimum
- expand based on content

---

## 6. Implementation Guidance for Design Fidelity

- keep the homepage feeling like a calendar, not an AI dashboard
- keep AI emphasis mostly in confirmation and split-view contexts
- the three primary anchors are:
  - date pager
  - timeline
  - primary input button

Design-to-code mapping:

- each visual block should correspond to a dedicated SwiftUI component
- date pager and timeline must share the same date source of truth
- split-view previews should reuse the same event block visual logic as the main timeline

---

## 7. Dark Mode

Use semantic system colors:

- `systemBackground`
- `secondarySystemBackground`
- `label`
- `secondaryLabel`
- `separator`

Accent blue remains stable across light and dark mode, similar to Apple's Calendar.

---

## 8. Alignment with Apple's Calendar

The goal is for CalPal to feel like an enhanced version of the system calendar rather than a disconnected third-party product.

| Element | Alignment Strategy |
|---|---|
| typography | SF Pro / system typography |
| time format | follow system settings |
| date format | follow current UI language |
| event colors | use EventKit-provided calendar colors |
| event source UX | use native EventKit / system patterns where possible |
| permission prompts | use system permission dialogs |
