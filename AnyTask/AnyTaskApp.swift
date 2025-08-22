//
//  AnyTaskApp.swift
//  AnyTask
//
//  Created by Kyle Hosman on 4/28/25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct AnyTaskApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            TaskSection.self
        ])
        // Use App Group container for shared store
        let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.kylehosman.AnyTask")!
        let storeURL = containerURL.appendingPathComponent("default.store")
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    // Retain the notification delegate
    private let notificationDelegate: NotificationDelegate
    
    init() {
        self.notificationDelegate = NotificationDelegate(modelContainer: sharedModelContainer)
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// Notification delegate to handle infinite repeat
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    let modelContainer: ModelContainer
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Task { @MainActor in
            NotificationManager.handleDeliveredNotification(for: response.notification.request.identifier, modelContext: modelContainer.mainContext)
            completionHandler()
        }
    }
}
