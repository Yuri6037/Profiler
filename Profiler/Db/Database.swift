// Copyright 2022 Yuri6037
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

protocol Database {
    var container: NSPersistentContainer { get };

    var lastError: NSError? { get };

    var errorEvent: ((NSError) -> Void)? { get set };

    func removeProject(proj: Project);

    func save();
}

class BaseDatabase: Database {
    let container: NSPersistentContainer;

    var lastError: NSError?;

    var errorEvent: ((NSError) -> Void)?;

    init(container: NSPersistentContainer) {
        self.container = container;
        self.container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                self.lastError = error;
            }
        });
        self.container.viewContext.automaticallyMergesChangesFromParent = true;
    }

    func removeProject(proj: Project) {
        let target = proj.target;
        let cpu = proj.cpu;
        container.viewContext.delete(proj);
        save();
        if let target = target {
            if target.projects?.isEmpty ?? false {
                container.viewContext.delete(target);
                save();
            }
        }
        if let cpu = cpu {
            if cpu.projects?.isEmpty ?? false {
                container.viewContext.delete(cpu);
                save();
            }
        }
    }

    func save() {
        do {
            try container.viewContext.save();
        } catch {
            let error = error as NSError;
            self.lastError = error;
            if let f = self.errorEvent {
                f(error);
                self.lastError = nil;
            }
        }
    }
}

class FileDatabase: BaseDatabase {
    static var url: URL {
        NSPersistentContainer.defaultDirectoryURL()
    }

    init() {
        let container = NSPersistentContainer(name: "Profiler")
        super.init(container: container)
    }
}

class NullDatabase: Database {
    var container: NSPersistentContainer {
        fatalError("Attempt to use a NullDatabase");
    }

    var lastError: NSError?;

    var errorEvent: ((NSError) -> Void)?;

    func removeProject(proj: Project) {
        fatalError("Attempt to use a NullDatabase");
    }

    func save() {
        fatalError("Attempt to use a NullDatabase");
    }
}
