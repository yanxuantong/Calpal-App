# CalPal

Privacy-first, on-device calendar assistant for iPhone.

CalPal turns a short voice or text request into a calendar action on top of Apple's system calendar stack. Phase 1 focuses on the smallest useful loop:

`voice / text input -> on-device intent parsing -> EventKit write -> confirmation when needed`

## Status

This repository currently contains:

- A SwiftUI iPhone app prototype for Phase 1
- Real `EventKit` calendar read / write / modify / delete flows
- Push-to-talk voice input with Speech Recognition
- On-device intent parsing with Apple Foundation Models, plus local fallback parsing
- Chinese / English UI switching
- Writable calendar selection through system calendars already connected to iOS, including Google Calendar accounts synced through the Calendar app
- App icon assets and supporting design / implementation documents

## Why CalPal

Most AI calendar tools either:

- send data to cloud LLMs by default, or
- feel like chat apps with a calendar attached

CalPal takes a different approach:

- privacy first
- calendar first
- voice first
- system-native interaction style

The goal is not to replace Apple Calendar. The goal is to feel like a more intelligent version of it.

## Phase 1 Scope

Phase 1 is intentionally narrow:

- iPhone only
- on-device AI first
- Apple system calendar stack through `EventKit`
- quick capture, confirmation, and write-back

Not in Phase 1:

- cloud AI fallback
- long-term habit learning
- iPad-specific UX
- backend accounts
- Android

## Current Architecture

Main app layers:

- `Views/`: screens and reusable SwiftUI components
- `ViewModels/`: screen state and orchestration
- `Services/`: EventKit, voice input, permissions, local intent parsing
- `Models/`: UI models and calendar intent types
- `Support/`: theme, layout, and date helpers

Important files:

- `Calpal-Codex/Services/CalendarManager.swift`
- `Calpal-Codex/Services/VoiceInputManager.swift`
- `Calpal-Codex/Services/AIIntentParser.swift`
- `Calpal-Codex/ViewModels/CalendarScreenModel.swift`
- `Calpal-Codex/Views/Screens/MainCalendarScreen.swift`

## Calendar Source Behavior

CalPal does not call the Google Calendar API directly.

Instead, it uses Apple's `EventKit` and the calendars already available through the system Calendar app. That means if a device has Google Calendar connected through iOS account settings, CalPal can read and write those calendars through the system layer.

The app now supports choosing a target writable calendar in Settings, so new events can be written to:

- the system default calendar
- iCloud calendars
- Google calendars connected through iOS
- other writable system calendar sources such as Exchange or CalDAV

## Language Support

The app currently supports:

- Simplified Chinese UI
- English UI

The onboarding language selection also controls the app interface language.

## Design Direction

The interaction model is built around a single centered input button:

- tap: open text input
- press and hold: start voice capture
- drag while holding: keep recording with direct thumb-following motion
- release: finish recording and start recognition
- animated spring return to center

Recent UI polish also explores iOS-native motion and Liquid Glass-style presentation where available, with safe fallbacks.

## Build

Open the Xcode project:

```bash
open Calpal-Codex.xcodeproj
```

Or build from the command line:

```bash
xcodebuild -scheme Calpal-Codex -project Calpal-Codex.xcodeproj -sdk iphonesimulator -configuration Debug build
```

## Requirements

- Xcode 26+
- iOS 26 simulator or compatible device target in the current project
- Apple Intelligence enabled on device for the best on-device parsing experience

## Documentation

English:

- [README](./README.md)
- [PRD](./CalPal_PRD_EN.md)
- [UI Spec](./CalPal_UI_SPEC_EN.md)
- [SwiftUI Guide](./CalPal_SwiftUI_Guide_EN.md)

Chinese:

- [README 中文版](./README_CN.md)
- [产品需求文档](./CalPal_PRD.md)
- [UI 设计规范](./CalPal_UI_SPEC.md)
- [SwiftUI 实现指南](./CalPal_SwiftUI_Guide.md)

## Open Source Notes

This repository is being prepared for open source. Some product and implementation decisions were originally documented in Chinese and are now being mirrored in English for public collaboration.

## License

License to be added.
