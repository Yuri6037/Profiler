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
    static func newSample(context: NSManagedObjectContext) -> Self
}

struct PersistentContainerEnvironmentKey: EnvironmentKey {
    static let defaultValue: NSPersistentContainer = .init(name: "whatever")
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

    init(errorHandler: @escaping (NSError) -> Void, inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Profiler")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                errorHandler(error)
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

struct StoreUtils {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    private func fillDictionary(_ obj: NSManagedObject, _ done: inout Set<NSManagedObject>, _ progressList: ProgressList) -> [String: Any]? {
        if done.contains(obj) {
            return nil
        }
        done.insert(obj)
        var dic: [String: Any] = [:]
        for key in obj.entity.attributeKeys {
            let val = obj.value(forKey: key)
            dic[key] = val
        }
        for key in obj.entity.toOneRelationshipKeys {
            let val = obj.value(forKey: key) as? NSManagedObject
            if let val {
                if let o = fillDictionary(val, &done, progressList) {
                    dic[key] = o
                }
            }
        }
        for key in obj.entity.toManyRelationshipKeys {
            var val = ((obj.value(forKey: key) as? NSSet)?.allObjects) as? [NSManagedObject]
            if val == nil {
                val = ((obj.value(forKey: key) as! NSOrderedSet).array) as? [NSManagedObject]
            }
            var arr: [[String: Any]] = []
            if let val {
                let progress = val.count > 10 ? progressList.begin(
                    text: "Exporting object properties...",
                    total: UInt(val.count)
                ) : nil
                for (k, v) in val.enumerated() {
                    if let o = fillDictionary(v, &done, progressList) {
                        arr.append(o)
                    }
                    // if k % 5 == 0 {
                    progress?.advance(count: 1)
                    // }
                }
                if let progress {
                    progressList.end(progress)
                }
            }
            dic[key] = arr
        }
        return dic
    }

    func generateJson(_ proj: Project, progressList: ProgressList) {
        let projId = proj.objectID
        container.performBackgroundTask { ctx in
            let proj = ctx.object(with: projId)
            var set: Set<NSManagedObject> = Set()
            let dic = fillDictionary(proj, &set, progressList)
        }
    }

    func deleteProject(_ proj: Project, onFinish: @escaping (NSError?) -> Void) {
        let targetId = proj.target?.projects?.count ?? 0 == 1 ? proj.target?.objectID : nil
        let cpuId = proj.cpu?.projects?.count ?? 0 == 1 ? proj.cpu?.objectID : nil
        let projId = proj.objectID
        container.performBackgroundTask { ctx in
            ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            let proj = ctx.object(with: projId)
            let fvariables = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: SpanVariable.self))
            fvariables.predicate = NSPredicate(format: "run.node.project = %@ OR event.node.project = %@", proj, proj)
            let fruns = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: SpanRun.self))
            fruns.predicate = NSPredicate(format: "node.project = %@", proj)
            let fevents = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: SpanEvent.self))
            fevents.predicate = NSPredicate(format: "node.project = %@", proj)
            let fdatasets = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Dataset.self))
            fdatasets.predicate = NSPredicate(format: "node.project = %@", proj)
            let fnodes = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: SpanNode.self))
            fnodes.predicate = NSPredicate(format: "project = %@", proj)
            do {
                let dv = NSBatchDeleteRequest(fetchRequest: fvariables)
                let dr = NSBatchDeleteRequest(fetchRequest: fruns)
                let de = NSBatchDeleteRequest(fetchRequest: fevents)
                let dd = NSBatchDeleteRequest(fetchRequest: fdatasets)
                let dn = NSBatchDeleteRequest(fetchRequest: fnodes)
                try ctx.execute(dv)
                try ctx.save()
                try ctx.execute(dr)
                try ctx.save()
                try ctx.execute(de)
                try ctx.save()
                try ctx.execute(dd)
                try ctx.save()
                try ctx.execute(dn)
                try ctx.save()
                ctx.delete(proj)
                if let targetId {
                    ctx.delete(ctx.object(with: targetId))
                }
                if let cpuId {
                    ctx.delete(ctx.object(with: cpuId))
                }
                try ctx.save()
                DispatchQueue.main.async {
                    onFinish(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    onFinish(error as NSError)
                }
            }
        }
    }
}
