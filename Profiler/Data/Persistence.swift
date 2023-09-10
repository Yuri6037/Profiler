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

protocol SampleData {
    static func newSample(context: NSManagedObjectContext) -> Self
}

// Annoyingly garbagely broken swift language believes self is captured as mutating when it is not!!!
class Store {
    static var preview: Store = {
        let result = Store(errorHandler: { error in
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }, inMemory: true)
        let viewContext = result.container.viewContext
        do {
            _ = Project.newSample(context: viewContext)
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    func newSample<T: SampleData>() -> T {
        T.newSample(context: container.viewContext)
    }

    let container: NSPersistentContainer

    var utils: StoreUtils { StoreUtils(container: container) }

    func createBackup() throws {
        let path = try FileUtils.getDocumentsDirectory().appendingPathComponent("Backups");
        try path.createDirsIfNotExists();
        let path1 = path.appendingPathComponent(Date().toISO8601());
        try path1.createDirsIfNotExists();
        let url = try FileUtils.getAppSupportDirectory()
        #if os(macOS)
            .appendingPathComponent("Profiler")
        #endif
        let main = url.appendingPathComponent("Profiler.sqlite");
        let shm = url.appendingPathComponent("Profiler.sqlite-shm");
        let wal = url.appendingPathComponent("Profiler.sqlite-wal");
        try FileUtils.copy(from: main, to: path1.appendingPathComponent("Profiler.sqlite"))
        try FileUtils.copy(from: shm, to: path1.appendingPathComponent("Profiler.sqlite-shm"))
        try FileUtils.copy(from: wal, to: path1.appendingPathComponent("Profiler.sqlite-wal"))
    }

    func reset() throws {
        let url = try FileUtils.getAppSupportDirectory()
        #if os(macOS)
            .appendingPathComponent("Profiler")
        #endif
        let main = url.appendingPathComponent("Profiler.sqlite");
        let shm = url.appendingPathComponent("Profiler.sqlite-shm");
        let wal = url.appendingPathComponent("Profiler.sqlite-wal");
        try FileUtils.delete(url: main)
        try FileUtils.delete(url: shm)
        try FileUtils.delete(url: wal)
    }

    init(errorHandler: @escaping (NSError) -> Void, inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Profiler")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                errorHandler(error)
                do {
                    try self.createBackup();
                    try self.reset();
                    self.container.loadPersistentStores(completionHandler: { _, error in
                        if let error = error as NSError? {
                            errorHandler(error)
                        }
                    })
                } catch {
                    if let error = error as NSError? {
                        errorHandler(error)
                    }
                }
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
