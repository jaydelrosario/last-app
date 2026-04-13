// LastApp/LastApp/Features/Workout/Views/WorkoutSessionDetailView.swift
import SwiftUI

struct WorkoutSessionDetailView: View {
    let session: WorkoutSession

    private var duration: String {
        guard let finished = session.finishedAt else { return "—" }
        let secs = Int(finished.timeIntervalSince(session.startedAt))
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        if h > 0 { return String(format: "%dh %02dm", h, m) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return String(format: "%ds", s)
    }

    private var completedSets: [SessionSet] {
        session.orderedExercises.flatMap { $0.orderedSets.filter { $0.isCompleted } }
    }

    private var totalVolume: Double {
        completedSets.reduce(0) { $0 + $1.weightLbs * Double($1.reps) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Stats row
                HStack(spacing: 0) {
                    statCell(value: duration, label: "Duration")
                    Divider().frame(height: 36)
                    statCell(value: "\(session.orderedExercises.count)", label: "Exercises")
                    Divider().frame(height: 36)
                    statCell(value: "\(completedSets.count)", label: "Sets")
                    Divider().frame(height: 36)
                    statCell(value: "\(Int(totalVolume)) lbs", label: "Volume")
                }
                .padding(.vertical, 12)
                .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Exercise sections
                ForEach(session.orderedExercises) { se in
                    let logged = se.orderedSets.filter { $0.isCompleted }
                    if !logged.isEmpty {
                        exerciseCard(se, sets: logged)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.bottom, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(session.startedAt.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Stat Cell

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.subheadline, weight: .bold))
            Text(label)
                .font(.system(.caption2))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Exercise Card

    private func exerciseCard(_ se: SessionExercise, sets: [SessionSet]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(se.exercise?.name ?? "Exercise")
                .font(.system(.body, weight: .bold))
                .foregroundStyle(Color.appAccent)

            HStack {
                Text("SET").frame(width: 36, alignment: .leading)
                Text("WEIGHT & REPS")
                Spacer()
            }
            .font(.system(.caption2, weight: .semibold))
            .foregroundStyle(.tertiary)

            ForEach(sets) { set in
                HStack {
                    Text("\(set.setNumber)")
                        .font(.system(.body, weight: .semibold))
                        .frame(width: 36, alignment: .leading)
                    Text("\(Int(set.weightLbs)) lbs × \(set.reps)")
                        .font(.system(.body))
                    Spacer()
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}
