// LastApp/LastApp/Features/Workout/Views/WorkoutListView.swift
import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.createdAt) private var routines: [Routine]
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var allSessions: [WorkoutSession]

    @State private var showingRoutineBuilder = false
    @State private var editingRoutine: Routine? = nil
    @State private var activeSession: WorkoutSession? = nil
    @State private var showingActiveWorkout = false
    @State private var selectedSession: WorkoutSession? = nil

    private var completedSessions: [WorkoutSession] {
        allSessions.filter { $0.finishedAt != nil }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Start Empty Workout
                    Button {
                        startEmptyWorkout()
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(.body, weight: .semibold))
                            Text("Start Empty Workout")
                                .font(.system(.body, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppTheme.padding)
                    .padding(.top, AppTheme.padding)

                    // Routines section
                    HStack {
                        Text("Routines")
                            .font(.system(.title3, weight: .bold))
                        Spacer()
                        Button {
                            showingRoutineBuilder = true
                        } label: {
                            Image(systemName: "plus.square")
                                .font(.system(.body, weight: .medium))
                                .foregroundStyle(Color.appAccent)
                        }
                    }
                    .padding(.horizontal, AppTheme.padding)

                    if routines.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "dumbbell")
                                .font(.system(size: 40))
                                .foregroundStyle(.tertiary)
                            Text("No routines yet")
                                .font(.system(.subheadline))
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(routines) { routine in
                                routineCard(routine)
                                    .padding(.horizontal, AppTheme.padding)
                            }
                        }
                    }
                }

                // History section
                if !completedSessions.isEmpty {
                    HStack {
                        Text("History")
                            .font(.system(.title3, weight: .bold))
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.padding)

                    VStack(spacing: 10) {
                        ForEach(completedSessions) { session in
                            Button {
                                selectedSession = session
                            } label: {
                                sessionHistoryRow(session)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, AppTheme.padding)
                        }
                    }
                }

                Spacer(minLength: 40)
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedSession) { session in
            WorkoutSessionDetailView(session: session)
        }
        .sheet(isPresented: $showingRoutineBuilder) {
            RoutineBuilderView()
        }
        .sheet(item: $editingRoutine) { routine in
            RoutineBuilderView(existingRoutine: routine)
        }
        .fullScreenCover(isPresented: $showingActiveWorkout) {
            if let session = activeSession {
                ActiveWorkoutView(session: session)
            }
        }
    }

    // MARK: - Routine Card

    private func routineCard(_ routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(routine.name)
                    .font(.system(.body, weight: .bold))
                Spacer()
                Menu {
                    Button { editingRoutine = routine } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        modelContext.delete(routine)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(.body, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .contentShape(Rectangle())
                }
            }

            if !routine.exerciseSummary.isEmpty {
                Text(routine.exerciseSummary)
                    .font(.system(.subheadline))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Button {
                startRoutineWorkout(routine)
            } label: {
                Text("Start Routine")
                    .font(.system(.subheadline, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.appAccent, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Session History Row

    private func sessionHistoryRow(_ session: WorkoutSession) -> some View {
        let exerciseNames = session.orderedExercises.prefix(3).compactMap { $0.exercise?.name }.joined(separator: ", ")
        let completedSets = session.orderedExercises.flatMap { $0.orderedSets.filter { $0.isCompleted } }
        let volume = completedSets.reduce(0.0) { $0 + $1.weightLbs * Double($1.reps) }
        let duration: String = {
            guard let finished = session.finishedAt else { return "" }
            let secs = Int(finished.timeIntervalSince(session.startedAt))
            let m = secs / 60
            return m > 0 ? "\(m)m" : "\(secs)s"
        }()

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(.subheadline, weight: .semibold))
                if !exerciseNames.isEmpty {
                    Text(exerciseNames)
                        .font(.system(.caption))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if !duration.isEmpty {
                    Text(duration)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                if volume > 0 {
                    Text("\(Int(volume)) lbs")
                        .font(.system(.caption))
                        .foregroundStyle(.tertiary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(.caption, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Session creation

    private func startEmptyWorkout() {
        let session = WorkoutSession()
        modelContext.insert(session)
        try? modelContext.save()
        activeSession = session
        showingActiveWorkout = true
    }

    private func startRoutineWorkout(_ routine: Routine) {
        let session = WorkoutSession()
        modelContext.insert(session)

        for (i, entry) in routine.orderedEntries.enumerated() {
            guard let exercise = entry.exercise else { continue }
            let sessionExercise = SessionExercise(exercise: exercise, sortOrder: i)
            sessionExercise.session = session
            modelContext.insert(sessionExercise)

            for setNum in 1...entry.setCount {
                let set = SessionSet(setNumber: setNum)
                set.sessionExercise = sessionExercise
                modelContext.insert(set)
            }
        }

        try? modelContext.save()
        activeSession = session
        showingActiveWorkout = true
    }
}
