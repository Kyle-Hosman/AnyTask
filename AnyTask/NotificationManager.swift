import Foundation
import UserNotifications

struct NotificationManager {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    static func scheduleNotification(for item: Item) {
        guard let dueDate = item.dueDate else { return }
        let content = UNMutableNotificationContent()
        content.title = item.taskText
        content.body = ("Due @ " + item.dueDate!.formatted(date: .omitted, time: .shortened))
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(dueDate.timeIntervalSinceNow, 1), repeats: false)
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    static func cancelNotification(for item: Item) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
    }
}
