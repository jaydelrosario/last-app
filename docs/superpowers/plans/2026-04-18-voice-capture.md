# Voice Capture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a hold-to-record mic button in the sidebar that streams speech to text and saves instantly as a Task (drag left) or Note (drag right).

**Architecture:** `VoiceRecorderViewModel` (`@Observable @MainActor`) owns `AVAudioEngine` + `SFSpeechRecognizer` and handles all recording, transcription, and SwiftData saving. `MicButton` owns the hold+drag gesture and pulse animation, passing save calls into the view model. `QuickCaptureBar` replaces the existing `settingsRow` in `SidebarView`, composing Settings + quick-add `+` + `MicButton`.

**Tech Stack:** SwiftUI, AVFoundation (`AVAudioEngine`, `AVAudioApplication`), Speech (`SFSpeechRecognizer`), SwiftData, iOS 17+

---

## File Map

**Create:**
- `LastApp/LastApp/Features/VoiceCapture/VoiceRecorderViewModel.swift`
- `LastApp/LastApp/Features/VoiceCapture/MicButton.swift`
- `LastApp/LastApp/Features/VoiceCapture/QuickCaptureBar.swift`

**Modify:**
- `LastApp/LastApp/Core/Navigation/SidebarView.swift` — replace `settingsRow` with `QuickCaptureBar()`

**Manual (Xcode UI):**
- Add `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` to the LastApp target's Info tab

---

## Task 1: Manual Xcode Prerequisites

> **Cannot be automated — requires Xcode UI.**

- [ ] **Step 1: Add permission descriptions**

In Xcode, select the **LastApp target → Info tab → Custom iOS Target Properties**. Click `+` and add:

| Key | Value |
|---|---|
| `NSMicrophoneUsageDescription` | `LastApp uses the microphone to record voice notes.` |
| `NSSpeechRecognitionUsageDescription` | `LastApp transcribes your voice to create tasks and notes.` |

- [ ] **Step 2: Build and verify**

`Cmd+B`. Expected: Build Succeeded.

- [ ] **Step 3: Commit**

```bash
git add LastApp/LastApp.xcodeproj/project.pbxproj
git commit -m "feat(voice): add microphone and speech recognition permission descriptions"
```

---

## Task 2: VoiceRecorderViewModel

**Files:**
- Create: `LastApp/LastApp/Features/VoiceCapture/VoiceRecorderViewModel.swift`

- [ ] **Step 1: Create VoiceRecorderViewModel.swift**

Create `LastApp/LastApp/Features/VoiceCapture/VoiceRecorderViewModel.swift`:

```swift
// LastApp/Features/VoiceCapture/VoiceRecorderViewModel.swift
import Foundation
import AVFoundation
import Speech
import SwiftData

@Observable
@MainActor
final class VoiceRecorderViewModel {

    enum RecordingState: Equatable {
        case idle
        case recording
        case saving
        case denied
        case error(String)
    }

    enum Destination {
        case task
        case note
    }

    var recordingState: RecordingState = .idle
    var transcript: String = ""

    private let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: .current)
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: - Public API

    func startRecording() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .notDetermined:
            requestSpeechAuthorization()
        case .authorized:
            requestMicrophonePermission()
        case .denied, .restricted:
            recordingState = .denied
        @unknown default:
            recordingState = .denied
        }
    }

    func finish(destination: Destination, context: ModelContext) {
        stopAudio()
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            recordingState = .idle
            transcript = ""
            return
        }
        recordingState = .saving
        switch destination {
        case .task:
            let task = TaskItem(title: text)
            context.insert(task)
        case .note:
            let note = Note()
            note.plainText = text
            note.bodyData = (try? NSKeyedArchiver.archivedData(
                withRootObject: NSAttributedString(string: text),
                requiringSecureCoding: false
            )) ?? Data()
            context.insert(note)
        }
        try? context.save()
        recordingState = .idle
        transcript = ""
    }

    func cancel() {
        stopAudio()
        recordingState = .idle
        transcript = ""
    }

    // MARK: - Permission Flow

    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch status {
                case .authorized:
                    self.requestMicrophonePermission()
                default:
                    self.recordingState = .denied
                }
            }
        }
    }

    private func requestMicrophonePermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if granted {
                        self.startAudioEngine()
                    } else {
                        self.recordingState = .denied
                    }
                }
            }
        case .granted:
            startAudioEngine()
        case .denied:
            recordingState = .denied
        @unknown default:
            recordingState = .denied
        }
    }

    // MARK: - Audio Engine

    private func startAudioEngine() {
        do {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest else { return }
            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.requiresOnDeviceRecognition = false

            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            recordingState = .recording

            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }
                    if let error {
                        let nsError = error as NSError
                        // Code 1110 = no speech detected — benign, ignore
                        guard !(nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110) else { return }
                        self.recordingState = .error(error.localizedDescription)
                    }
                }
            }
        } catch {
            recordingState = .error(error.localizedDescription)
        }
    }

    private func stopAudio() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
```

- [ ] **Step 2: Build and verify**

```bash
cd /Users/jay/dev/last-app && xcodebuild -project LastApp/LastApp.xcodeproj -scheme LastApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | tail -10
```

Expected: BUILD SUCCEEDED (or fails only on missing `MicButton`/`QuickCaptureBar` which don't exist yet — that's fine).

- [ ] **Step 3: Commit**

```bash
cd /Users/jay/dev/last-app && git add LastApp/LastApp/Features/VoiceCapture/VoiceRecorderViewModel.swift
git commit -m "feat(voice): add VoiceRecorderViewModel with streaming speech recognition"
```

---

## Task 3: MicButton

**Files:**
- Create: `LastApp/LastApp/Features/VoiceCapture/MicButton.swift`

- [ ] **Step 1: Create MicButton.swift**

Create `LastApp/LastApp/Features/VoiceCapture/MicButton.swift`:

```swift
// LastApp/Features/VoiceCapture/MicButton.swift
import SwiftUI
import SwiftData

struct MicButton: View {
    var viewModel: VoiceRecorderViewModel
    @Environment(\.modelContext) private var modelContext

    @State private var isRecording = false
    @State private var dragOffset: CGFloat = 0
    @State private var pulsing = false

    private var destinationHint: VoiceRecorderViewModel.Destination? {
        guard isRecording else { return nil }
        if dragOffset < -40 { return .task }
        if dragOffset > 40 { return .note }
        return nil
    }

    private var buttonFill: Color {
        switch destinationHint {
        case .task:   return .blue.opacity(0.15)
        case .note:   return .purple.opacity(0.15)
        case nil:     return Color.appAccent.opacity(isRecording ? 0.18 : 0.12)
        }
    }

    private var iconColor: Color {
        switch destinationHint {
        case .task: return .blue
        case .note: return .purple
        case nil:   return Color.appAccent
        }
    }

    var body: some View {
        ZStack {
            // Pulse ring — only shown while recording
            if isRecording {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.appAccent.opacity(pulsing ? 0 : 0.5), lineWidth: 1.5)
                    .frame(width: 68, height: 40)
                    .scaleEffect(pulsing ? 1.22 : 1.0)
                    .animation(
                        .easeOut(duration: 0.7).repeatForever(autoreverses: false),
                        value: pulsing
                    )
                    .onAppear { pulsing = true }
                    .onDisappear { pulsing = false }
            }

            // Button body
            RoundedRectangle(cornerRadius: 10)
                .fill(buttonFill)
                .frame(width: 60, height: 36)
                .overlay {
                    Image(systemName: "mic.fill")
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(iconColor)
                }
                .animation(.spring(response: 0.2), value: destinationHint == nil)
        }
        // Destination labels
        .overlay(alignment: .leading) {
            if destinationHint == .task {
                Text("← Task")
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundStyle(.blue)
                    .fixedSize()
                    .offset(x: -54)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .overlay(alignment: .trailing) {
            if destinationHint == .note {
                Text("Note →")
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundStyle(.purple)
                    .fixedSize()
                    .offset(x: 54)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .gesture(combinedGesture)
        .disabled(viewModel.recordingState == .denied)
    }

    // MARK: - Gesture

    private var combinedGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .onEnded { _ in
                isRecording = true
                viewModel.startRecording()
            }
            .simultaneously(with:
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard isRecording else { return }
                        withAnimation(.interactiveSpring()) {
                            dragOffset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        guard isRecording else { return }
                        let offset = value.translation.width
                        isRecording = false
                        withAnimation(.spring(response: 0.2)) { dragOffset = 0 }
                        if abs(offset) >= 40 {
                            let dest: VoiceRecorderViewModel.Destination = offset < 0 ? .task : .note
                            viewModel.finish(destination: dest, context: modelContext)
                        } else {
                            viewModel.cancel()
                        }
                    }
            )
    }
}
```

- [ ] **Step 2: Build and verify**

```bash
cd /Users/jay/dev/last-app && xcodebuild -project LastApp/LastApp.xcodeproj -scheme LastApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | tail -10
```

Expected: BUILD SUCCEEDED (or only missing `QuickCaptureBar` error).

- [ ] **Step 3: Commit**

```bash
cd /Users/jay/dev/last-app && git add LastApp/LastApp/Features/VoiceCapture/MicButton.swift
git commit -m "feat(voice): add MicButton with hold+drag gesture and pulse animation"
```

---

## Task 4: QuickCaptureBar + SidebarView Wiring

**Files:**
- Create: `LastApp/LastApp/Features/VoiceCapture/QuickCaptureBar.swift`
- Modify: `LastApp/LastApp/Core/Navigation/SidebarView.swift`

- [ ] **Step 1: Create QuickCaptureBar.swift**

Create `LastApp/LastApp/Features/VoiceCapture/QuickCaptureBar.swift`:

```swift
// LastApp/Features/VoiceCapture/QuickCaptureBar.swift
import SwiftUI
import SwiftData

struct QuickCaptureBar: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var voiceVM = VoiceRecorderViewModel()
    @State private var showingTaskCreation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if voiceVM.recordingState == .denied {
                Text("Microphone access required")
                    .font(.system(.caption2))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)
                    .transition(.opacity)
            }

            HStack(spacing: 8) {
                // Settings button — fills remaining space
                Button {
                    appState.navigate(to: .settings)
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Quick-add task button
                Button {
                    showingTaskCreation = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(Color.appAccent)
                        .frame(width: 44, height: 36)
                        .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                // Mic button
                MicButton(viewModel: voiceVM)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .animation(.easeInOut(duration: 0.2), value: voiceVM.recordingState == .denied)
        .sheet(isPresented: $showingTaskCreation) {
            TaskCreationView()
        }
    }
}
```

- [ ] **Step 2: Replace settingsRow in SidebarView**

In `LastApp/LastApp/Core/Navigation/SidebarView.swift`:

Replace the `settingsRow` usage in `body` (line 37):
```swift
// Before:
settingsRow

// After:
QuickCaptureBar()
```

Delete the entire `settingsRow` computed property (lines 241–254):
```swift
// DELETE this entire block:
private var settingsRow: some View {
    Button {
        appState.navigate(to: .settings)
    } label: {
        Label("Settings", systemImage: "gearshape")
            .font(.system(.body, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
}
```

Also delete the `// MARK: - Settings` comment above it.

- [ ] **Step 3: Build and verify — full build must succeed**

```bash
cd /Users/jay/dev/last-app && xcodebuild -project LastApp/LastApp.xcodeproj -scheme LastApp -destination "platform=iOS Simulator,name=iPhone 16 Pro" build 2>&1 | grep -E "error:|BUILD SUCCEEDED|BUILD FAILED" | tail -10
```

Expected: **BUILD SUCCEEDED** with 0 errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/jay/dev/last-app && git add LastApp/LastApp/Features/VoiceCapture/QuickCaptureBar.swift \
        LastApp/LastApp/Core/Navigation/SidebarView.swift
git commit -m "feat(voice): add QuickCaptureBar and wire into sidebar"
```

---

## Task 5: Manual Verification

- [ ] **Step 1: Run on simulator**

Press Cmd+R. Select an iPhone simulator (iOS 17+).

Open the sidebar. Confirm the bottom row shows: `⚙ Settings` on the left, a `+` button, and a wider mic button on the right.

- [ ] **Step 2: Test the + button**

Tap `+`. Confirm `TaskCreationView` sheet appears. Add a task title and tap Done. Navigate to Inbox and confirm the task is there.

- [ ] **Step 3: Test mic button on a real device**

> Speech recognition does not work on simulator — run on a physical iPhone for this step.

Hold the mic button for 0.3s. Confirm:
- Location permission prompt appears (first time)
- Mic button pulses with the ring animation
- Speak a short phrase

**Drag left (Task):** While still holding, drag left until `← Task` label appears. Release. Navigate to Inbox — confirm new task with spoken title exists.

**Drag right (Note):** Repeat. Drag right until `Note →` appears. Release. Navigate to Notes — confirm new note with spoken text exists.

**Cancel (no drag):** Hold, speak, release without dragging (or with a small drag under 40pt). Nothing is saved.

- [ ] **Step 4: Test denied state**

Go to device Settings → Privacy → Microphone → LastApp → set to Off. Return to app, open sidebar. Hold mic button. Confirm "Microphone access required" text appears above the bar and the mic button is disabled.

- [ ] **Step 5: Final commit**

```bash
git commit --allow-empty -m "feat(voice): voice capture complete and manually verified"
```
