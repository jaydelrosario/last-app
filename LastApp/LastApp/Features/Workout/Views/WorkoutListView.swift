// LastApp/LastApp/Features/Workout/Views/WorkoutListView.swift
import SwiftUI
import SwiftData

struct WorkoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Routine.createdAt) private var routines: [Routine]

    @State private var showingRoutineBuilder = false
    @State private var editingRoutine: Routine? = nil
    @State private var activeSession: WorkoutSession? = nil
    @State private var showingActiveWorkout = false

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
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.large)
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
