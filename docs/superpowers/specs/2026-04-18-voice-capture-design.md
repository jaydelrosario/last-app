# Voice Capture — Design Spec
_Date: 2026-04-18_

## Overview

A hold-to-record button in the sidebar that streams speech to text and saves the transcription instantly as either a Task (inbox) or a Note, determined by swipe direction on release.

---

## Decisions

| Decision | Choice |
|---|---|
| Transcription | `SFSpeechRecognizer` + `AVAudioEngine` streaming (live, on-device iOS 17+) |
| Destination | Left swipe → Task in Inbox; Right swipe → Note |
| Save | Instant on release — no review step |
| Permissions | Microphone + Speech Recognition — requested on first hold |
| Permission denied UX | Inline message above the bar: "Microphone access required" |

---

## Architecture

### Files to Create

- `LastApp/LastApp/Features/VoiceCapture/VoiceRecorderViewModel.swift` — `@Observable @MainActor` class; owns `AVAudioEngine` + `SFSpeechRecognizer`; manages state and saves to SwiftData
- `LastApp/LastApp/Features/VoiceCapture/MicButton.swift` — hold + drag gesture button; pulse animation; destination indicator overlay
- `LastApp/LastApp/Features/VoiceCapture/QuickCaptureBar.swift` — bottom sidebar bar: Settings + `+` + mic button

### Files to Modify

- `LastApp/LastApp/Core/Navigation/SidebarView.swift` — replace `settingsRow` with `QuickCaptureBar()`
- `LastApp/LastApp/LastApp.xcodeproj` — add `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` to Info settings (via Xcode target Info tab)

---

## VoiceRecorderViewModel

```swift
@Observable
@MainActor
final class VoiceRecorderViewModel {
    enum State { case idle, recording, saving, denied, error(String) }
    enum Destination { case task, note }

    var state: State = .idle
    var transcript: String = ""

    private let speechRecognizer = SFSpeechRecognizer(locale: .current)
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func startRecording()
    func finish(destination: Destination, context: ModelContext)
    func cancel()
}
```

- `startRecording()`: checks `SFSpeechRecognizer.authorizationStatus` and `AVCaptureDevice.authorizationStatus(for: .audio)`. If either is `.denied`/`.restricted`, sets `state = .denied`. If `.notDetermined`, requests both then starts. Configures `AVAudioSession` for `.record`, taps `audioEngine.inputNode`, feeds buffers into `SFSpeechAudioBufferRecognitionRequest`. Sets `state = .recording`.
- On each recognition result: updates `transcript` with `result.bestTranscription.formattedString`
- `finish(destination:context:)`: stops audio engine and recognition task, sets `state = .saving`, inserts model, resets to `.idle`
- `cancel()`: stops everything, clears `transcript`, resets to `.idle`
- **Task creation**: `TaskItem(title: transcript, list: nil)` inserted into context
- **Note creation**: creates `Note()`, sets `plainText = transcript`, sets `bodyData` by archiving `NSAttributedString(string: transcript)` with `NSKeyedArchiver`

---

## Data Mapping

### Task (left swipe)

| Field | Value |
|---|---|
| `title` | `transcript` |
| `list` | `nil` (Inbox) |
| `priority` | `.p4` (default) |

### Note (right swipe)

| Field | Value |
|---|---|
| `plainText` | `transcript` |
| `bodyData` | `NSKeyedArchiver.archivedData(withRootObject: NSAttributedString(string: transcript))` |
| `notebook` | `nil` (no notebook) |
| `createdAt` / `modifiedAt` | `Date()` |

---

## UI Layout

### QuickCaptureBar

```
┌─────────────────────────────────────┐
│  ⚙ Settings   [  +  ] [    🎙    ]  │
└─────────────────────────────────────┘
```

- Full-width `HStack` with `.padding(.horizontal, 20).padding(.vertical, 14)`
- Settings button: `Label("Settings", systemImage: "gearshape")`, `.foregroundStyle(.secondary)`, fills remaining space
- `+` button: ~44×36pt, `.secondary.opacity(0.15)` background, rounded rectangle
- Mic button: ~60×36pt, `Color.appAccent.opacity(0.12)` idle background, rounded rectangle

### MicButton States

| State | Visual |
|---|---|
| Idle | Mic icon, `appAccent.opacity(0.12)` background |
| Recording | Pulse: `scaleEffect` 1.0→1.08 repeating + outer ring opacity 1.0→0 repeating |
| Drag left (≥40pt) | `← Task` label fades in left of button, button tints `.blue` |
| Drag right (≥40pt) | `Note →` label fades in right of button, button tints `.purple` |
| Denied | Button disabled, "Microphone access required" text fades in above bar |

### Gesture

- `LongPressGesture(minimumDuration: 0.3).sequenced(before: DragGesture(minimumDistance: 0))`
- On long press first phase completes: call `viewModel.startRecording()`
- On drag update: track `translation.width` to determine destination
- On drag end: call `viewModel.finish(destination:)` or `cancel()` if no threshold reached and transcript is empty

---

## Permissions

- `NSMicrophoneUsageDescription`: `"LastApp uses the microphone to record voice notes."`
- `NSSpeechRecognitionUsageDescription`: `"LastApp transcribes your voice to create tasks and notes."`
- Both requested on first hold gesture
- Denied state: mic button shows disabled appearance, inline "Microphone access required" text above bar (no modal, no Settings deep-link — keep it minimal)
