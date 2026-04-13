// LastApp/LastApp/Features/Workout/Views/ActiveWorkoutView.swift
import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession

    @AppStorage("restTimerDuration") private var restTimerDuration: Int = 60
    @AppStorage("weightUnit") private var weightUnit: String = "lbs"

    @State private var elapsedSeconds: Int = 0
    @State private var showingPicker = false
    @State private var showingDiscardAlert = false
    @State private var workoutTimer: Timer? = nil

    @State private var restRemaining: Int? = nil
    @State private var restTimer: Timer? = nil

    @State private var exerciseForDetail: Exercise? = nil
    @State private var notes: String = ""

    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private var hasLoggedSets: Bool {
        session.sessionExercises.contains { ex in ex.sets.contains { $0.isCompleted } }
    }

    // Convert stored lbs value for display
    private func displayWeight(_ lbs: Double) -> Double {
        weightUnit == "kg" ? lbs * 0.453592 : lbs
    }

    // Convert entered display value back to lbs for storage
    private func storageWeight(_ display: Double) -> Double {
        weightUnit == "kg" ? display / 0.453592 : display
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(session.orderedExercises) { sessionExercise in
                            exerciseSection(sessionExercise)
                        }

                        // Notes field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES")
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, AppTheme.padding)

                            TextField("Add workout notes…", text: $notes, axis: .vertical)
                                .font(.system(.body))
                                .padding(12)
                                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal, AppTheme.padding)
                        }

                        Button {
                            showingPicker = true
                        } label: {
                            Label("Add Exercise", systemImage: "plus")
                                .font(.system(.body, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, AppTheme.padding)
                        .padding(.bottom, restRemaining != nil ? 120 : 40)
                    }
                    .padding(.top, 16)
                }
                .background(Color(uiColor: .systemGroupedBackground))

                if let remaining = restRemaining {
                    restTimerBanner(remaining: remaining)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: restRemaining != nil)
            .navigationTitle(timerString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasLoggedSets { showingDiscardAlert = true } else { discardSession() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") { finishWorkout() }
                        .fontWeight(.semibold)
                }
            }
            .navigationDestination(item: $exerciseForDetail) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
        .onAppear {
            startWorkoutTimer()
            notes = session.notes
            impactFeedback.prepare()
            notificationFeedback.prepare()
        }
        .onDisappear { stopAllTimers() }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView { exercise in addExercise(exercise) }
        }
        .alert("Discard Workout?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) { discardSession() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your logged sets will be lost.")
        }
    }

    // MARK: - Rest Timer Banner

    private func restTimerBanner(remaining: Int) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rest Timer")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(restTimerString(remaining))
                    .font(.system(.title2, design: .monospaced, weight: .bold))
                    .foregroundStyle(remaining <= 10 ? .red : Color.appAccent)
            }
            Spacer()
            Button { stopRestTimer() } label: {
                Text("Skip")
                    .font(.system(.subheadline, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: -2)
        .padding(.horizontal, AppTheme.padding)
        .padding(.bottom, 20)
    }

    // MARK: - Exercise Section

    private func exerciseSection(_ sessionExercise: SessionExercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                exerciseForDetail = sessionExercise.exercise
            } label: {
                HStack(spacing: 4) {
                    Text(sessionExercise.exercise?.name ?? "Exercise")
                        .font(.system(.body, weight: .bold))
                        .foregroundStyle(Color.appAccent)
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(Color.appAccent.opacity(0.6))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.padding)

            HStack {
                Text("SET").frame(width: 36, alignment: .leading)
                Text(weightUnit.uppercased()).frame(maxWidth: .infinity, alignment: .center)
                Text("REPS").frame(maxWidth: .infinity, alignment: .center)
                Spacer().frame(width: 44)
            }
            .font(.system(.caption2, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, AppTheme.padding)

            ForEach(sessionExercise.orderedSets) { set in
                setRow(set)
            }

            Button { addSet(to: sessionExercise) } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Add Set")
                }
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(Color.appAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.appAccent.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, AppTheme.padding)
        }
    }

    // MARK: - Set Row

    private func setRow(_ set: SessionSet) -> some View {
        HStack {
            Text("\(set.setNumber)")
                .font(.system(.body, weight: .semibold))
                .frame(width: 36, alignment: .leading)

            TextField("0", value: Binding(
                get: { displayWeight(set.weightLbs) },
                set: { set.weightLbs = storageWeight($0) }
            ), format: .number)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            TextField("0", value: Binding(
                get: { set.reps },
                set: { set.reps = $0 }
            ), format: .number)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

            Button {
                withAnimation(.spring(response: 0.25)) {
                    set.isCompleted.toggle()
                }
                if set.isCompleted {
                    impactFeedback.impactOccurred()
                    startRestTimer()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(set.isCompleted ? Color.green : Color(uiColor: .secondarySystemGroupedBackground))
                        .frame(width: 36, height: 36)
                    if set.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.padding)
        .background(set.isCompleted ? Color.green.opacity(0.07) : Color.clear)
    }

    // MARK: - Workout Timer

    private var timerString: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    private func startWorkoutTimer() {
        elapsedSeconds = Int(Date().timeIntervalSince(session.startedAt))
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    // MARK: - Rest Timer

    private func restTimerString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func startRestTimer() {
        stopRestTimer()
        restRemaining = restTimerDuration
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if let r = restRemaining, r > 0 {
                restRemaining = r - 1
            } else {
                notificationFeedback.notificationOccurred(.success)
                stopRestTimer()
            }
        }
    }

    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restRemaining = nil
    }

    private func stopAllTimers() {
        workoutTimer?.invalidate()
        workoutTimer = nil
        stopRestTimer()
    }

    // MARK: - Actions

    private func addSet(to sessionExercise: SessionExercise) {
        let nextNumber = (sessionExercise.sets.map(\.setNumber).max() ?? 0) + 1
        let set = SessionSet(setNumber: nextNumber)
        set.sessionExercise = sessionExercise
        modelContext.insert(set)
        try? modelContext.save()
    }

    private func addExercise(_ exercise: Exercise) {
        let nextOrder = (session.sessionExercises.map(\.sortOrder).max() ?? -1) + 1
        let sessionExercise = SessionExercise(exercise: exercise, sortOrder: nextOrder)
        sessionExercise.session = session
        modelContext.insert(sessionExercise)

        let set = SessionSet(setNumber: 1)
        set.sessionExercise = sessionExercise
        modelContext.insert(set)

        try? modelContext.save()
    }

    private func finishWorkout() {
        stopAllTimers()
        session.finishedAt = Date()
        session.notes = notes
        try? modelContext.save()
        dismiss()
    }

    private func discardSession() {
        stopAllTimers()
        modelContext.delete(session)
        try? modelContext.save()
        dismiss()
    }
}
