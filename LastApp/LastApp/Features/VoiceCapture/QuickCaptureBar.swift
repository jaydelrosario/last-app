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
