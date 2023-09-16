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

import Foundation
import CoreData

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
        dic["__typename"] = String(describing: type(of: obj))
        for key in obj.entity.attributeKeys {
            let val = obj.value(forKey: key)
            if obj.entity.attributesByName[key]?.attributeType == .dateAttributeType {
                dic[key] = (val as! Date).toTimestamp()
            } else {
                dic[key] = val
            }
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
                let progress = val.count > 3 ? progressList.begin(
                    text: "Exporting linked objects...",
                    total: UInt(val.count)
                ) : nil
                for v in val {
                    if let o = fillDictionary(v, &done, progressList) {
                        arr.append(o)
                    }
                    progress?.advance(count: 1)
                }
                if let progress {
                    progressList.end(progress)
                }
            }
            dic[key] = arr
        }
        return dic
    }

    private func findProject(_ params: [String: Any], _ ctx: NSManagedObjectContext) throws -> Bool {
        let date: Date? = params["timestamp"] as? UInt64 != nil ? Date(fromTimestamp: params["timestamp"] as! UInt64) : nil;
        let req = Project.fetchRequest();
        req.fetchLimit = 1;
        req.predicate = NSPredicate(format: "appName=%@ AND name=%@ AND commandLine=%@ AND timestamp=%@ AND version=%@", params["appName"] as? String ?? NSNull(), params["name"] as? String ?? NSNull(), params["commandLine"] as? String ?? NSNull(), date as? NSDate ?? NSNull(), params["version"] as? String ?? NSNull());
        let obj = try ctx.fetch(req);
        return !obj.isEmpty;
    }

    private func createObject(_ params: [String: Any], _ ctx: NSManagedObjectContext, _ progressList: ProgressList) -> NSManagedObject? {
        guard let typename = params["__typename"] as? String else { return nil }
        guard let entity = NSEntityDescription.entity(forEntityName: typename, in: ctx) else { return nil }
        let obj = NSManagedObject(entity: entity, insertInto: ctx)
        for key in obj.entity.attributeKeys {
            if obj.entity.attributesByName[key]?.attributeType == .dateAttributeType {
                guard let val = params[key] as? UInt64 else { continue }
                let date = Date(fromTimestamp: val)
                obj.setValue(date, forKey: key)
            } else {
                obj.setValue(params[key], forKey: key)
            }
        }
        for key in obj.entity.toOneRelationshipKeys {
            guard let pars = params[key] as? [String: Any] else { continue }
            obj.setValue(createObject(pars, ctx, progressList), forKey: key)
        }
        for key in obj.entity.toManyRelationshipKeys {
            guard let arr = params[key] as? [[String: Any]] else { continue }
            if arr.count <= 0 {
                continue
            }
            let progress = arr.count > 3 ? progressList.begin(
                text: "Creating linked objects...",
                total: UInt(arr.count)
            ) : nil
            if obj.entity.relationshipsByName[key]?.isOrdered ?? false {
                let set = NSMutableOrderedSet()
                for v in arr {
                    let obj = createObject(v, ctx, progressList);
                    if let obj {
                        set.add(obj)
                    }
                    progress?.advance(count: 1)
                }
                obj.setValue(set, forKey: key)
            } else {
                let set = NSMutableSet()
                for v in arr {
                    let obj = createObject(v, ctx, progressList);
                    if let obj {
                        set.add(obj)
                    }
                    progress?.advance(count: 1)
                }
                obj.setValue(set, forKey: key)
            }
            if let progress {
                progressList.end(progress)
            }
        }
        return obj
    }

    func exportJson(_ proj: Project, progressList: ProgressList, onFinish: @escaping (Data?, NSError?) -> Void) {
        let projId = proj.objectID
        container.performBackgroundTask { ctx in
            let proj = ctx.object(with: projId)
            var set: Set<NSManagedObject> = Set()
            let dic = fillDictionary(proj, &set, progressList)
            do {
                let data = try JSONSerialization.data(withJSONObject: dic as Any)
                onFinish(data, nil)
            } catch {
                onFinish(nil, error as NSError)
            }
        }
    }

    func importJson(_ json: Data, progressList: ProgressList, onFinish: @escaping (Bool, NSError?) -> Void) {
        container.performBackgroundTask { ctx in
            do {
                if let obj = try JSONSerialization.jsonObject(with: json) as? [String: Any] {
                    if try findProject(obj, ctx) {
                        onFinish(false, nil);
                        return;
                    }
                    _ = createObject(obj, ctx, progressList)
                    try ctx.save()
                }
                onFinish(true, nil)
            } catch {
                onFinish(false, error as NSError)
            }
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
            fvariables.predicate = NSPredicate(format: "run.dataset.node.project = %@ OR event.node.project = %@", proj, proj)
            let fruns = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: SpanRun.self))
            fruns.predicate = NSPredicate(format: "dataset.node.project = %@", proj)
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
