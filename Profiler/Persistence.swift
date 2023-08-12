//
//  Persistence.swift
//  Profiler
//
//  Created by Yuri Edward on 5/15/23.
//

import CoreData
import SwiftUI

protocol SampleData {
    static func newSample(context: NSManagedObjectContext) -> Self;
}

struct PersistentContainerEnvironmentKey: EnvironmentKey {
    static let defaultValue: NSPersistentContainer = NSPersistentContainer(name: "whatever");
}

extension EnvironmentValues {
    var persistentContainer: NSPersistentContainer {
        get { self[PersistentContainerEnvironmentKey.self] }
        set { self[PersistentContainerEnvironmentKey.self] = newValue }
    }
}


struct Store {
    static var preview: Store = {
        let result = Store(errorHandler: { error in
            fatalError("Unresolved error \(error), \(error.userInfo)");
        }, inMemory: true);
        let viewContext = result.container.viewContext
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    func newSample<T: SampleData>() -> T {
        return T.newSample(context: container.viewContext)
    }

    let container: NSPersistentContainer

    init(errorHandler: @escaping (NSError) -> Void, inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Profiler")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                errorHandler(error);
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
