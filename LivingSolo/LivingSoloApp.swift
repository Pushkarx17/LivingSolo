//
//  LivingSoloApp.swift
//  LivingSolo
//
//  Created by Pushkar K U on 30/10/25.
//

import SwiftUI

@main
struct LivingSoloApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
