// LastApp/Features/Habits/HabitTemplates.swift
import Foundation

struct HabitTemplateItem {
    let name: String
    let action: String
    let goalCount: Int
    let goalUnit: String
    /// 0=Sun … 6=Sat. Empty means every day.
    let scheduleDays: [Int]
}

enum HabitTemplates {

    static let groups: [(title: String, templates: [HabitTemplateItem])] = [
        ("Morning", morning),
        ("Movement", movement),
        ("Mind", mind),
        ("Evening", evening),
        ("Health", health),
    ]

    // MARK: - Morning

    static let morning: [HabitTemplateItem] = [
        HabitTemplateItem(
            name: "Drink water", action: "Drink a glass of water",
            goalCount: 1, goalUnit: "glass", scheduleDays: []
        ),
        HabitTemplateItem(
            name: "Make your bed", action: "Make your bed",
            goalCount: 1, goalUnit: "time", scheduleDays: []
        ),
        HabitTemplateItem(
            name: "Gratitude journal", action: "Write 3 things you're grateful for",
            goalCount: 3, goalUnit: "items", scheduleDays: []
        ),
        HabitTemplateItem(
            name: "No phone morning", action: "No phone for the first hour of the day",
            goalCount: 1, goalUnit: "hour", scheduleDays: []
        ),
    ]

    // MARK: - Movement

    static let movement: [HabitTemplateItem] = [
        HabitTemplateItem(
            name: "Walk", action: "Walk for 10 minutes",
            goalCount: 10, goalUnit: "min", scheduleDays: []
        ),
        HabitTemplateItem(
            name: "Stretch", action: "Stretch for 5 minutes",
            goalCount: 5, goalUnit: "min", scheduleDays: []
        ),
        HabitTemplateItem(
            name: "Pushups", action: "Do 10 pushups",
            goalCount: 10, goalUnit: "reps", scheduleDays: []
        ),
        HabitTemplateItem(
            name: "Take the stairs", action: "Take the stairs instead of the elevator",
            goalCount: 1, goalUnit: "time", scheduleDays: [1, 2, 3, 4, 5]
        ),
    ]

    // MARK: - Mind

    static let mind: [HabitTemplateItem] = [
        HabitTemplateItem(
            name: "Read", action: "Read for 10 minutes",
            goalCount: 10, goalUnit: "min", scheduleDays: []
        ),
        HabitTemplateItem(
            name: "Meditate", action: "Meditate for 5 minutes",
            goalCount: 5, goalUnit: "min", scheduleDays: []
        ),
        HabitTemplateItem(
            name: "Learn something new", action: "Watch or read something educational",
            goalCount: 1, goalUnit: "time", scheduleDays: []
        ),
    ]

    // MARK: - Evening

    static let evening: [HabitTemplateItem] = [
        HabitTemplateItem(
            name: "Journal", action: "Write in your journal",
            goalCount: 1, goalUnit: "time", scheduleDays: []
        ),
        HabitTemplateItem(
            name: "Plan tomorrow", action: "Write tomorrow's top 3 priorities",
            goalCount: 3, goalUnit: "items", scheduleDays: []
        ),
        HabitTemplateItem(
            name: "Screen-free wind down", action: "No screens 30 minutes before bed",
            goalCount: 30, goalUnit: "min", scheduleDays: []
        ),
    ]

    // MARK: - Health

    static let health: [HabitTemplateItem] = [
        HabitTemplateItem(
            name: "Take vitamins", action: "Take your vitamins",
            goalCount: 1, goalUnit: "time", scheduleDays: []
        ),
        HabitTemplateItem(
            name: "Drink water", action: "Drink 8 glasses of water",
            goalCount: 8, goalUnit: "glasses", scheduleDays: []
        ),
        HabitTemplateItem(
            name: "Cook at home", action: "Cook a meal at home",
            goalCount: 1, goalUnit: "meal", scheduleDays: []
        ),
        HabitTemplateItem(
            name: "Sleep on time", action: "Be in bed by 10:30 PM",
            goalCount: 1, goalUnit: "time", scheduleDays: []
        ),
    ]
}
