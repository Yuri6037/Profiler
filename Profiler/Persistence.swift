// Copyright 2023 Yuri6037
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy
// of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS
// IN THE SOFTWARE.

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
