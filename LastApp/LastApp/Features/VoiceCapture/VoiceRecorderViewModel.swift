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
                        if result.isFinal {
                            self.stopAudio()
                        }
                    }
                    if let error {
                        let nsError = error as NSError
                        // Code 1110 = no speech detected — benign, ignore
                        guard !(nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110) else { return }
                        self.stopAudio()
                        self.recordingState = .error(error.localizedDescription)
                    }
                }
            }
        } catch {
            audioEngine.inputNode.removeTap(onBus: 0)
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            recognitionRequest = nil
            recordingState = .error(error.localizedDescription)
        }
    }

    private func stopAudio() {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
