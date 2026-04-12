// LastApp/Features/Habits/HabitNotificationManager.swift
import UserNotifications
import Foundation

enum HabitNotificationManager {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func schedule(for habit: Habit) {
        cancel(for: habit)
        guard habit.reminderEnabled, habit.habitTimeInterval >= 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Habit reminder"
        content.body = "I will \(habit.action)"
        content.sound = .default

        let offsetInterval = habit.habitTimeInterval - Double(habit.reminderOffsetMinutes * 60)
        let fireInterval = max(0, offsetInterval)
        let base = Calendar.current.startOfDay(for: .now).addingTimeInterval(fireInterval)
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: base)

        for day in habit.scheduleDays {
            var components = timeComponents
            components.weekday = day + 1   // Calendar: Sunday = 1
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: notificationID(habit: habit, day: day),
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    static func cancel(for habit: Habit) {
        let ids = (0..<7).map { notificationID(habit: habit, day: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func notificationID(habit: Habit, day: Int) -> String {
        "\(habit.id)-day\(day)"
    }
}
