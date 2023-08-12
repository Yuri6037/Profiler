//
//  ProfilerApp.swift
//  Profiler
//
//  Created by Yuri Edward on 5/15/23.
//

import SwiftUI

//Swift is so much of a peace of shit that it just has banned the possibility
//of writing a single App for both iOS and macOS: it refuses #if os(macOS)!
class AppDelegate: NSObject, NSApplicationDelegate
{
    let errorHandler: ErrorHandler = ErrorHandler();
    lazy var store: Store = {
#if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return Store.preview
        }
#endif
        return Store(errorHandler: { error in
            self.errorHandler.pushError(AppError(fromNSError: error));
        })
    }()
}

@main
struct ProfilerApp: App {
    //When swift finally accepts #if os(macOS) on a class use it to enable the app under iOS
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate;

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.errorHandler)
                .environment(\.persistentContainer, appDelegate.store.container)
                .environment(\.managedObjectContext, appDelegate.store.container.viewContext)
        }
    }
}
