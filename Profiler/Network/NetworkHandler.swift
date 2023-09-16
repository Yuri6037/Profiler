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
import Foundation
import Protocol
import TextTools

class NetworkHandler {
    private let parser = CSVParser(delimiter: ",")
    private var evIndex = 0
    private var tree = SpanTree()

    func handleProject(adaptor: NetworkAdaptor, message: MessageProject) {
        tree = SpanTree()
        evIndex = 0
        adaptor.execDb { ctx, _ in
            let p = Project(context: ctx)
            p.timestamp = Date()
            p.appName = message.appName
            p.name = message.name
            p.version = message.version
            p.commandLine = message.commandLine
            let request: NSFetchRequest<Target> = NSFetchRequest(entityName: "Target")
            request.predicate = NSPredicate(format: "os = %@ AND family = %@ AND arch = %@", message.target.os, message.target.family, message.target.arch)
            var retrieved = try ctx.fetch(request).first
            if retrieved == nil {
                retrieved = Target(context: ctx)
                retrieved?.os = message.target.os
                retrieved?.family = message.target.family
                retrieved?.arch = message.target.arch
            }
            p.target = retrieved
            if let cpu = message.cpu {
                let request: NSFetchRequest<Cpu> = NSFetchRequest(entityName: "Cpu")
                request.predicate = NSPredicate(format: "name = %@ AND coreCount = %d", cpu.name, cpu.coreCount)
                var retrieved = try ctx.fetch(request).first
                if retrieved == nil {
                    retrieved = Cpu(context: ctx)
                    retrieved?.name = cpu.name
                    retrieved?.coreCount = Int32(cpu.coreCount)
                }
                p.cpu = retrieved
            }
            let zerospan = SpanNode(context: ctx)
            zerospan.project = p
            zerospan.path = "/"
            zerospan.order = 0
            zerospan.metadata = nil
            try ctx.save()
            adaptor.setProject(p.objectID)
        }
    }

    func handleSpanAlloc(adaptor: NetworkAdaptor, message: MessageSpanAlloc) {
        tree.addNode(Span(name: message.metadata.name, id: message.id))
        adaptor.execDb { ctx, p in
            let node = SpanNode(context: ctx)
            node.project = p
            node.order = Int32(message.id)
            let metadata = SpanMetadata(context: ctx)
            metadata.level = Int16(message.metadata.level.raw)
            metadata.file = message.metadata.file
            metadata.modulePath = message.metadata.modulePath
            metadata.target = message.metadata.target
            metadata.line = message.metadata.line != nil ? Int32(message.metadata.line!) : -1
            metadata.name = message.metadata.name
            node.metadata = metadata
            node.path = "/" + message.metadata.name
            try ctx.save()
        }
    }

    func handleSpanParent(adaptor: NetworkAdaptor, message: MessageSpanParent) {
        if tree.relocateNode(message.id, newParent: message.parentNode) {
            let path = tree.getPath(message.id)
            adaptor.execDb(node: message.id) { ctx, _, node in
                node.path = path
                try ctx.save()
            }
        }
    }

    func handleSpanFollows(adaptor: NetworkAdaptor, message: MessageSpanFollows) {
        if let parent = tree.root.findParent(message.follows) {
            if tree.relocateNode(message.id, newParent: parent) {
                let path = tree.getPath(message.id)
                adaptor.execDb(node: message.id) { ctx, _, node in
                    node.path = path
                    try ctx.save()
                }
            }
        }
    }

    func handleSpanEvent(adaptor: NetworkAdaptor, message: MessageSpanEvent) {
        adaptor.execDb(node: message.id) { ctx, _, node in
            let row = self.parser.parseRow(message.message)
            if row.count < 3 {
                return
            }
            let e = SpanEvent(context: ctx)
            e.node = node
            e.level = Int16(message.level.raw)
            e.timestamp = Date(timeIntervalSince1970: Double(message.timestamp))
            e.message = row[0]
            e.target = row[row.count - 1]
            e.module = row[row.count - 2]
            e.order = Int64(self.evIndex)
            self.evIndex += 1
            for i in 1 ..< row.count - 2 {
                let v = SpanVariable(context: ctx)
                v.event = e
                v.data = row[i]
            }
            try ctx.save()
        }
    }

    func handleSpanUpdate(adaptor: NetworkAdaptor, message: MessageSpanUpdate) {
        adaptor.execDb(node: message.id) { ctx, _, node in
            node.averageTime = Int64(bitPattern: message.averageTime.nanoseconds)
            node.maxTime = Int64(bitPattern: message.maxTime.nanoseconds)
            node.minTime = Int64(bitPattern: message.minTime.nanoseconds)
            try ctx.save()
        }
    }

    func handleSpanDataset(adaptor: NetworkAdaptor, message: MessageSpanDataset) {
        let total = UInt(message.runCount)
        if total == 0 {
            // Do not attempt to import a 0 entry dataset.
            return
        }
        let progress = adaptor.progressList.begin(text: "Importing dataset...", total: total)
        adaptor.execDb(node: message.id) { ctx, _, node in
            let reader = BufferedLineStreamer(str: message.content)
            let medianHalfIndex = total > 1 ? total / 2 - 1 : 0
            let medianCount = total % 2 == 0 ? 2 : 1
            let dataset = Dataset(context: ctx)
            dataset.timestamp = Date()
            dataset.node = node
            var runIndex = node.wRunsCount
            var maxTime = UInt64(0)
            var minTime = UInt64.max
            var averageTime = UInt64(0)
            var timeValues: [UInt64] = []
            while let line = reader.readLine() {
                let row = self.parser.parseRow(line)
                if row.count < 3 {
                    continue
                }
                let run = SpanRun(context: ctx)
                run.order = Int64(runIndex)
                runIndex += 1
                run.dataset = dataset
                run.message = row[0]
                let secs = UInt32(row[row.count - 2]) ?? 0
                let nanos = UInt32(row[row.count - 1]) ?? 0
                let time = Duration(seconds: secs, nanoseconds: nanos).nanoseconds
                run.time = Int64(bitPattern: time)
                if time > maxTime {
                    maxTime = time
                }
                if time < minTime {
                    minTime = time
                }
                averageTime += time
                for i in 1 ..< row.count - 2 {
                    let v = SpanVariable(context: ctx)
                    v.run = run
                    v.data = row[i]
                }
                timeValues.append(time)
                progress.advance()
            }
            averageTime = averageTime / UInt64(total)
            dataset.averageTime = Int64(bitPattern: averageTime)
            dataset.minTime = Int64(bitPattern: minTime)
            dataset.maxTime = Int64(bitPattern: maxTime)
            timeValues.sort()
            let medianTime: UInt64
            if medianCount == 2 {
                medianTime = (timeValues[Int(medianHalfIndex)] + timeValues[Int(medianHalfIndex) + 1]) / 2
            } else {
                medianTime = timeValues[Int(medianHalfIndex)]
            }
            dataset.medianTime = Int64(bitPattern: medianTime)
            let averages = node.wDatasets.map { UInt64(bitPattern: $0.averageTime) }.reduce(0, +);
            node.averageTime = Int64(bitPattern: averages / UInt64(node.wDatasets.count))
            if minTime < UInt64(bitPattern: node.minTime) {
                node.minTime = Int64(bitPattern: minTime)
            }
            if maxTime > UInt64(bitPattern: node.maxTime) {
                node.maxTime = Int64(bitPattern: maxTime)
            }
            try ctx.save()
            adaptor.progressList.end(progress)
        }
    }
}
