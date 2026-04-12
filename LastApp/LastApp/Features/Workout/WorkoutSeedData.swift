// LastApp/LastApp/Features/Workout/WorkoutSeedData.swift
import Foundation

enum WorkoutSeedData {
    static var exercises: [Exercise] {
        [
            // Chest
            Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell),
            Exercise(name: "Incline Bench Press", muscleGroup: .chest, equipment: .dumbbell),
            Exercise(name: "Push Up", muscleGroup: .chest, equipment: .bodyweight),
            Exercise(name: "Cable Fly", muscleGroup: .chest, equipment: .cable),
            Exercise(name: "Chest Dip", muscleGroup: .chest, equipment: .bodyweight),
            // Back
            Exercise(name: "Pull Up", muscleGroup: .back, equipment: .bodyweight),
            Exercise(name: "Lat Pulldown", muscleGroup: .back, equipment: .machine),
            Exercise(name: "Seated Row", muscleGroup: .back, equipment: .cable),
            Exercise(name: "Deadlift", muscleGroup: .back, equipment: .barbell),
            Exercise(name: "Bent Over Row", muscleGroup: .back, equipment: .barbell),
            // Shoulders
            Exercise(name: "Overhead Press", muscleGroup: .shoulders, equipment: .barbell),
            Exercise(name: "Lateral Raise", muscleGroup: .shoulders, equipment: .dumbbell),
            Exercise(name: "Face Pull", muscleGroup: .shoulders, equipment: .cable),
            Exercise(name: "Arnold Press", muscleGroup: .shoulders, equipment: .dumbbell),
            // Biceps
            Exercise(name: "Barbell Curl", muscleGroup: .biceps, equipment: .barbell),
            Exercise(name: "Hammer Curl", muscleGroup: .biceps, equipment: .dumbbell),
            Exercise(name: "Preacher Curl", muscleGroup: .biceps, equipment: .machine),
            Exercise(name: "Incline Curl", muscleGroup: .biceps, equipment: .dumbbell),
            // Triceps
            Exercise(name: "Triceps Pushdown", muscleGroup: .triceps, equipment: .cable),
            Exercise(name: "Skull Crusher", muscleGroup: .triceps, equipment: .barbell),
            Exercise(name: "Dip", muscleGroup: .triceps, equipment: .bodyweight),
            Exercise(name: "Overhead Extension", muscleGroup: .triceps, equipment: .dumbbell),
            // Legs
            Exercise(name: "Squat", muscleGroup: .legs, equipment: .barbell),
            Exercise(name: "Leg Press", muscleGroup: .legs, equipment: .machine),
            Exercise(name: "Romanian Deadlift", muscleGroup: .legs, equipment: .barbell),
            Exercise(name: "Leg Extension", muscleGroup: .legs, equipment: .machine),
            Exercise(name: "Leg Curl", muscleGroup: .legs, equipment: .machine),
            Exercise(name: "Calf Raise", muscleGroup: .legs, equipment: .machine),
            Exercise(name: "Lunge", muscleGroup: .legs, equipment: .dumbbell),
            // Core
            Exercise(name: "Plank", muscleGroup: .core, equipment: .bodyweight),
            Exercise(name: "Crunch", muscleGroup: .core, equipment: .bodyweight),
            Exercise(name: "Hanging Leg Raise", muscleGroup: .core, equipment: .bodyweight),
            Exercise(name: "Ab Wheel Rollout", muscleGroup: .core, equipment: .other),
            // Cardio
            Exercise(name: "Running", muscleGroup: .cardio, equipment: .machine),
            Exercise(name: "Rowing", muscleGroup: .cardio, equipment: .machine),
            Exercise(name: "Stair Machine", muscleGroup: .cardio, equipment: .machine),
            Exercise(name: "Jump Rope", muscleGroup: .cardio, equipment: .other),
            Exercise(name: "Cycling", muscleGroup: .cardio, equipment: .machine),
        ]
    }
}
