import Foundation
import SwiftData
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
        content.title = item.parentSection?.name ?? "AnyTask"
        content.body = (item.taskText + " (@ " + dueDate.formatted(date: .omitted, time: .shortened) + ")")
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
            nextContent.title = item.parentSection?.name ?? "AnyTask"
            nextContent.body = (item.taskText + " (@ " + dueDate.formatted(date: .omitted, time: .shortened) + ")")
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
    
    // Call this from your AppDelegate/SceneDelegate when a notification is delivered
    static func handleDeliveredNotification(for identifier: String, modelContext: ModelContext) {
        // Remove _repeat suffix if present
        let idString = identifier.replacingOccurrences(of: "_repeat", with: "")
        guard let uuid = UUID(uuidString: idString) else { return }
        let fetchRequest = FetchDescriptor<Item>(predicate: #Predicate { $0.id == uuid })
        guard let item = try? modelContext.fetch(fetchRequest).first else { return }
        // Store section ID for ContentView to pick up
        if let sectionID = item.parentSection?.id {
            UserDefaults.standard.set(sectionID.uuidString, forKey: "SectionToShowOnLaunch")
        }
        // Only reschedule if not completed and repeat is enabled
        if !item.taskComplete, item.repeatNotification, let interval = item.repeatInterval {
            // Set the next due date to now + interval
            item.dueDate = Date().addingTimeInterval(interval)
            try? modelContext.save()
            scheduleNotification(for: item)
        }
    }
}
