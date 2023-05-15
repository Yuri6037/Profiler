//
//  ProfilerApp.swift
//  Profiler
//
//  Created by Yuri Edward on 5/15/23.
//

import SwiftUI

@main
struct ProfilerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
