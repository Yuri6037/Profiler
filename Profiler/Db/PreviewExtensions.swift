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

import Foundation
import CoreData

class InMemoryDatabase: BaseDatabase {
    static var shared: InMemoryDatabase = {
        let result = InMemoryDatabase();
        let viewContext = result.container.viewContext;
        for _ in 0..<10 {
            sampleProject(context: viewContext);
        }
        result.save();
        return result;
    }()

    init() {
        let container = NSPersistentContainer(name: "Profiler")
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        super.init(container: container);
    }

    func getFirstProject() -> Project? {
        let request = NSFetchRequest<Project>(entityName: "Project");
        request.fetchLimit = 1;
        do {
            let result = try self.container.viewContext.fetch(request);
            return result.first;
        } catch _ {
            return nil;
        }
    }

    func getFirstNode() -> SpanNode? {
        let request = NSFetchRequest<SpanNode>(entityName: "SpanNode");
        request.fetchLimit = 1;
        do {
            let result = try self.container.viewContext.fetch(request);
            return result.first;
        } catch _ {
            return nil;
        }
    }
}
