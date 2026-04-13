// LastApp/LastApp/Features/Workout/Views/ExerciseDetailView.swift
import SwiftUI
import SwiftData
import Charts

struct ExerciseDetailView: View {
    let exercise: Exercise

    @Query private var allSessionExercises: [SessionExercise]

    @State private var selectedTab = 0

    // All finished session-exercises for this exercise, oldest first
    private var sessionExercises: [SessionExercise] {
        allSessionExercises
            .filter { $0.exercise?.id == exercise.id && $0.session?.finishedAt != nil }
            .sorted { ($0.session?.startedAt ?? .distantPast) < ($1.session?.startedAt ?? .distantPast) }
    }

    private var completedSets: [SessionSet] {
        sessionExercises.flatMap { $0.orderedSets }.filter { $0.isCompleted && $0.weightLbs > 0 && $0.reps > 0 }
    }

    // MARK: - Personal Records

    private var heaviestWeight: Double? { completedSets.map(\.weightLbs).max() }

    private var bestOneRepMax: Double? {
        completedSets.map { $0.weightLbs * (1 + Double($0.reps) / 30.0) }.max()
    }

    private var bestSetVolume: (weight: Double, reps: Int)? {
        completedSets.max { ($0.weightLbs * Double($0.reps)) < ($1.weightLbs * Double($1.reps)) }
            .map { ($0.weightLbs, $0.reps) }
    }

    private var bestSessionVolume: Double? {
        sessionExercises.map { se in
            se.orderedSets.filter { $0.isCompleted }.reduce(0.0) { $0 + $1.weightLbs * Double($1.reps) }
        }.max()
    }

    // Max weight lifted per session, for chart
    private var chartData: [(date: Date, weight: Double)] {
        sessionExercises.compactMap { se in
            guard let date = se.session?.startedAt,
                  let max = se.orderedSets.filter({ $0.isCompleted && $0.weightLbs > 0 }).map(\.weightLbs).max()
            else { return nil }
            return (date: date, weight: max)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Tab", selection: $selectedTab) {
                Text("Summary").tag(0)
                Text("History").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 12)

            if selectedTab == 0 {
                summaryTab
            } else {
                historyTab
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Summary Tab

    private var summaryTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Primary: \(exercise.muscleGroup.displayName)")
                    .font(.system(.subheadline))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                // Weight chart
                if chartData.count >= 2 {
                    Chart(chartData, id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(Color.appAccent)
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", point.weight)
                        )
                        .foregroundStyle(Color.appAccent)
                    }
                    .frame(height: 160)
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // Personal Records card
                if heaviestWeight != nil {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: "medal.fill")
                                .foregroundStyle(.yellow)
                            Text("Personal Records")
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)

                        if let hw = heaviestWeight {
                            prRow(label: "Heaviest Weight", value: "\(Int(hw))lbs")
                        }
                        if let orm = bestOneRepMax {
                            prRow(label: "Best 1RM", value: String(format: "%.1flbs", orm))
                        }
                        if let sv = bestSetVolume {
                            prRow(label: "Best Set Volume", value: "\(Int(sv.weight))lbs x \(sv.reps)")
                        }
                        if let vol = bestSessionVolume {
                            prRow(label: "Best Session Volume", value: "\(Int(vol))lbs")
                        }
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                } else {
                    emptyState(icon: "chart.line.uptrend.xyaxis", message: "No data yet", detail: "Complete sets in a workout to see your stats")
                }
            }
            .padding(.bottom, 40)
        }
    }

    private func prRow(label: String, value: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                Spacer()
                Text(value)
                    .font(.system(.body, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
            Divider().padding(.leading)
        }
    }

    // MARK: - History Tab

    private var historyTab: some View {
        ScrollView {
            if sessionExercises.isEmpty {
                emptyState(icon: "clock", message: "No history yet", detail: "Completed workouts will appear here")
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(sessionExercises.reversed()) { se in
                        if let session = se.session {
                            historyCard(session: session, sessionExercise: se)
                        }
                    }
                }
                .padding()
            }
        }
    }

    private func historyCard(session: WorkoutSession, sessionExercise: SessionExercise) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.system(.subheadline, weight: .semibold))

            Divider()

            HStack {
                Text("SET").frame(width: 36, alignment: .leading)
                Text("WEIGHT & REPS")
            }
            .font(.system(.caption2, weight: .semibold))
            .foregroundStyle(.tertiary)

            ForEach(sessionExercise.orderedSets.filter { $0.isCompleted && $0.weightLbs > 0 }) { set in
                HStack {
                    Text("\(set.setNumber)")
                        .font(.system(.body, weight: .semibold))
                        .frame(width: 36, alignment: .leading)
                    Text("\(Int(set.weightLbs)) lbs x \(set.reps)")
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func emptyState(icon: String, message: String, detail: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.system(.subheadline))
                .foregroundStyle(.tertiary)
            Text(detail)
                .font(.system(.caption))
                .foregroundStyle(.quaternary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
