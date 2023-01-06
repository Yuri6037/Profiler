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

    func removeProject(proj: Project, onFinish: @escaping () -> Void);

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
    
    private func handleError(error: NSError) {
        lastError = error;
        if let f = errorEvent {
            f(error);
            lastError = nil;
        }
    }

    func removeProject(proj: Project, onFinish: @escaping () -> Void) {
        let targetId = proj.target?.projects?.count ?? 0 == 1 ? proj.target?.objectID : nil;
        let cpuId = proj.cpu?.projects?.count ?? 0 == 1 ? proj.cpu?.objectID : nil;
        let projId = proj.objectID;
        container.performBackgroundTask { ctx in
            ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
            let proj = ctx.object(with: projId);
            let fvariables = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: SpanVariable.self));
            fvariables.predicate = NSPredicate(format: "run.node.project = %@ OR event.node.project = %@", proj, proj);
            let fruns = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: SpanRun.self));
            fruns.predicate = NSPredicate(format: "node.project = %@", proj);
            let fevents = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: SpanEvent.self));
            fevents.predicate = NSPredicate(format: "node.project = %@", proj);
            let fnodes = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: SpanNode.self));
            fnodes.predicate = NSPredicate(format: "project = %@", proj);
            do {
                let dv = NSBatchDeleteRequest(fetchRequest: fvariables);
                let dr = NSBatchDeleteRequest(fetchRequest: fruns);
                let de = NSBatchDeleteRequest(fetchRequest: fevents);
                let dn = NSBatchDeleteRequest(fetchRequest: fnodes);
                try ctx.execute(dv);
                try ctx.save();
                try ctx.execute(dr);
                try ctx.save();
                try ctx.execute(de);
                try ctx.save();
                try ctx.execute(dn);
                try ctx.save();
                ctx.delete(proj);
                if let targetId = targetId {
                    ctx.delete(ctx.object(with: targetId));
                }
                if let cpuId = cpuId {
                    ctx.delete(ctx.object(with: cpuId));
                }
                try ctx.save();
                DispatchQueue.main.async {
                    onFinish();
                }
            } catch {
                DispatchQueue.main.async {
                    self.handleError(error: error as NSError);
                    onFinish();
                }
            }
        };
    }

    func save() {
        do {
            try container.viewContext.save();
        } catch {
            handleError(error: error as NSError);
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

    func removeProject(proj: Project, onFinish: @escaping () -> Void) {
        fatalError("Attempt to use a NullDatabase");
    }

    func save() {
        fatalError("Attempt to use a NullDatabase");
    }
}
