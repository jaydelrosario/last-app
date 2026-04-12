// LastApp/LastApp/Features/Workout/Views/ActiveWorkoutView.swift
import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let session: WorkoutSession

    @State private var elapsedSeconds: Int = 0
    @State private var showingPicker = false
    @State private var showingDiscardAlert = false
    @State private var timer: Timer? = nil

    private var hasLoggedSets: Bool {
        session.sessionExercises.contains { ex in
            ex.sets.contains { $0.isCompleted }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(session.orderedExercises) { sessionExercise in
                        exerciseSection(sessionExercise)
                    }

                    // Add Exercise button
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
                    .padding(.bottom, 40)
                }
                .padding(.top, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(timerString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasLoggedSets {
                            showingDiscardAlert = true
                        } else {
                            discardSession()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        finishWorkout()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView { exercise in
                addExercise(exercise)
            }
        }
        .alert("Discard Workout?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) { discardSession() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your logged sets will be lost.")
        }
    }

    // MARK: - Exercise Section

    private func exerciseSection(_ sessionExercise: SessionExercise) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sessionExercise.exercise?.name ?? "Exercise")
                .font(.system(.body, weight: .bold))
                .foregroundStyle(Color.appAccent)
                .padding(.horizontal, AppTheme.padding)

            // Column headers
            HStack {
                Text("SET").frame(width: 36, alignment: .leading)
                Text("LBS").frame(maxWidth: .infinity, alignment: .center)
                Text("REPS").frame(maxWidth: .infinity, alignment: .center)
                Spacer().frame(width: 44)
            }
            .font(.system(.caption2, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, AppTheme.padding)

            // Set rows
            ForEach(sessionExercise.orderedSets) { set in
                setRow(set)
            }

            // Add Set
            Button {
                addSet(to: sessionExercise)
            } label: {
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
                get: { set.weightLbs },
                set: { set.weightLbs = $0 }
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

            // Checkmark
            Button {
                withAnimation(.spring(response: 0.25)) {
                    set.isCompleted.toggle()
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

    // MARK: - Timer

    private var timerString: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func startTimer() {
        elapsedSeconds = Int(Date().timeIntervalSince(session.startedAt))
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
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
        stopTimer()
        session.finishedAt = Date()
        try? modelContext.save()
        dismiss()
    }

    private func discardSession() {
        stopTimer()
        modelContext.delete(session)
        try? modelContext.save()
        dismiss()
    }
}
