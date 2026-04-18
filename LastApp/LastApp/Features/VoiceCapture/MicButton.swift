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
