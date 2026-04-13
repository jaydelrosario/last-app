// LastApp/Features/Tasks/TaskNotificationManager.swift
import UserNotifications
import Foundation

enum TaskNotificationManager {
    static func schedule(for task: TaskItem) {
        cancel(for: task)
        guard let dueDate = task.dueDate, !task.isCompleted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task due today"
        content.body = task.title
        content.sound = .default

        // Fire at 9 AM on the due date
        var components = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id(for: task), content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func cancel(for task: TaskItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id(for: task)])
    }

    private static func id(for task: TaskItem) -> String { "task-\(task.id)" }
}
