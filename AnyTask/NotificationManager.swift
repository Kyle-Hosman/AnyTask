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
        content.body = ("Due @ " + dueDate.formatted(date: .omitted, time: .shortened))
        content.sound = .default
        
        // Cancel any existing notifications for this item
        cancelNotification(for: item)
        
        // Schedule the first notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(dueDate.timeIntervalSinceNow, 1), repeats: false)
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
        
        // If repeat is enabled, schedule the next notification after repeatInterval
        if item.repeatNotification, let interval = item.repeatInterval, interval >= 60 {
            // Schedule the next notification after the interval
            let nextDate = dueDate.addingTimeInterval(interval)
            let nextContent = UNMutableNotificationContent()
            nextContent.title = item.taskText
            nextContent.body = ("Due @ " + nextDate.formatted(date: .omitted, time: .shortened))
            nextContent.sound = .default
            let nextTrigger = UNTimeIntervalNotificationTrigger(timeInterval: max(nextDate.timeIntervalSinceNow, 1), repeats: false)
            let nextRequest = UNNotificationRequest(identifier: item.id.uuidString + "_repeat", content: nextContent, trigger: nextTrigger)
            UNUserNotificationCenter.current().add(nextRequest) { error in
                if let error = error {
                    print("Failed to schedule repeat notification: \(error)")
                }
            }
        }
    }

    static func cancelNotification(for item: Item) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString, item.id.uuidString + "_repeat"])
    }
}
