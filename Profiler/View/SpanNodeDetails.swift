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

let MAX_UI_ROWS = 20000

struct SpanNodeDetails: View {
    @ObservedObject var node: Node
    @Binding var datasets: Set<ProfilerDataset>
    @EnvironmentObject var errorHandler: ErrorHandler
    @EnvironmentObject var filters: NodeFilters
    @Environment(\.managedObjectContext) var viewContext;
    @Environment(\.persistentContainer) var container: NSPersistentContainer
    @Environment(\.horizontalSizeClass) var sizeClass;
    @State private var points: [Double]?
    @State private var records: [DisplayProfilerRecord]?
    @State private var events: [DisplaySpanEvent]?
    @State private var showMoreSheet = false

    private func loadRecords(node: Node) {
        records = nil
        dbFunc(node: node, fetch: { node, datasets, ctx in
            let records: NSFetchRequest<ProfilerRecord> = ProfilerRecord.fetchRequest()
            records.sortDescriptors = filters.getSortDescriptors()
            records.predicate = filters.getPredicate(node: node, datasets: datasets)
            let size = try ctx.count(for: records)
            records.fetchLimit = MAX_UI_ROWS
            records.predicate = filters.getPredicate(size: size, maxSize: MAX_UI_ROWS, node: node, datasets: datasets)
            return records
        }, handle: { records in
            let records = records.map { DisplayProfilerRecord(fromModel: $0) }
            DispatchQueue.main.async {
                self.records = records
            }
        })
    }

    private func loadEvents(node: Node) {
        events = nil
        dbFunc(node: node, fetch: { node, _, _ in
            let events: NSFetchRequest<Event> = Event.fetchRequest()
            events.fetchLimit = MAX_UI_ROWS
            events.sortDescriptors = [NSSortDescriptor(keyPath: \Event.order, ascending: true)]
            events.predicate = NSPredicate(format: "node=%@", node)
            return events
        }, handle: { events in
            let events = events.map { DisplaySpanEvent(fromModel: $0) }
            DispatchQueue.main.async {
                self.events = events
            }
        })
    }

    private func loadPoints(node: Node) {
        if Defaults.bool(forKey: "general.useMeanInGraph") ?? true {
            loadPointsMean(node: node)
        } else {
            loadPointsLowPass(node: node)
        }
    }

    private func loadPointsLowPass(node: Node) {
        points = nil
        dbFunc(node: node, fetch: { node, datasets, ctx in
            let filters = NodeFilters()
            let records: NSFetchRequest<ProfilerRecord> = ProfilerRecord.fetchRequest()
            records.sortDescriptors = filters.getSortDescriptors()
            records.predicate = filters.getPredicate(node: node, datasets: datasets)
            let size = try ctx.count(for: records)
            records.fetchLimit = 1500
            records.predicate = filters.getPredicate(size: size, maxSize: 1500, node: node, datasets: datasets)
            return records
        }, handle: { records in
            _ = records.map { DisplayProfilerRecord(fromModel: $0) }
            let points = records.map(\.wTime.seconds)
            DispatchQueue.main.async {
                self.points = points
            }
        })
    }

    private func loadPointsMean(node: Node) {
        points = nil
        dbFunc(node: node, fetch: { node, datasets, ctx in
            let filters = NodeFilters()
            let records: NSFetchRequest<ProfilerRecord> = ProfilerRecord.fetchRequest()
            records.sortDescriptors = filters.getSortDescriptors()
            records.predicate = filters.getPredicate(node: node, datasets: datasets)
            return records
        }, handle: { records in
            if records.count <= 1500 {
                _ = records.map { DisplayProfilerRecord(fromModel: $0) }
                let points = records.map(\.wTime.seconds)
                DispatchQueue.main.async {
                    self.points = points
                }
                return
            }
            let samples = UInt(records.count) / 1500;
            var points: [Float64] = []
            var average = 0.0
            var count = 0
            for v in records {
                count += 1
                average += v.wTime.seconds
                if count >= samples {
                    points.append(average / Float64(count))
                    count = 0;
                    average = 0.0
                }
            }
            if count > 0 {
                points.append(average / Float64(count))
            }
            DispatchQueue.main.async {
                self.points = points
            }
        })
    }

    private func dbFunc<T>(node: Node, fetch: @escaping (NSManagedObject, [NSManagedObject], NSManagedObjectContext) throws -> NSFetchRequest<T>, handle: @escaping ([T]) -> Void) {
        let nodeId = node.objectID
        let datasetIds = datasets.map { v in v.objectID }
        container.performBackgroundTask { ctx in
            let datasets = datasetIds.map { v in ctx.object(with: v) }
            let node = ctx.object(with: nodeId)
            do {
                let req = try fetch(node, datasets, ctx)
                let data = try ctx.fetch(req)
                handle(data)
            } catch {
                DispatchQueue.main.async {
                    errorHandler.pushError(AppError(fromNSError: error as NSError))
                }
            }
        }
    }

    private func loadData(node: Node) {
        loadRecords(node: node)
        loadEvents(node: node)
        loadPoints(node: node)
    }

    var body: some View {
        GeometryReader { g in
            VStack {
                if let records {
                    ProfilerRecordTable(records: records)
                } else {
                    ProgressView()
                }
                if g.size.height > 1000 {
                    if let events {
                        SpanEventTable(events: events)
                    } else {
                        ProgressView()
                    }
                } else {
                    Button(action: { showMoreSheet = true }) {
                        ToolButton(icon: "viewfinder", text: "More information", value: 0)
                        Text("More information")
                    }
                }
                if let points {
                    if points.count > 0 {
                        ScrollView(.horizontal) {
                            LineChart(width: 2048, height: 256, points: points)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    ProgressView()
                }
            }
            .onAppear { loadData(node: node) }
            .onChange(of: node) { loadData(node: $0) }
            .onChange(of: datasets) { _ in
                loadRecords(node: node)
                loadPoints(node: node)
            }
            .onChange(of: filters.distribution) { _ in loadRecords(node: node) }
            .onChange(of: filters.order) { _ in loadRecords(node: node) }
            .onChange(of: filters.text) { filters.updateTextFilter($0) { loadRecords(node: node) } }
            .sheet(isPresented: $showMoreSheet, onDismiss: { showMoreSheet = false }) {
                VStack {
                    VStack {
                        if sizeClass == .compact {
                            SpanNodeInfo(node: node)
                            Divider()
                        }
                        if let events {
                            SpanEventTable(events: events)
                        } else {
                            ProgressView()
                        }
                    }
                    Button(action: { showMoreSheet = false }) {
                        Text("OK")
                    }
                }.padding()
                #if os(macOS)
                    .frame(minWidth: 500, minHeight: 200)
                #endif
            }
        }
    }
}

struct SpanNodeDetails_Previews: PreviewProvider {
    static var previews: some View {
        SpanNodeDetails(node: Store.preview.newSample(), datasets: .constant([]))
            .environment(\.persistentContainer, Store.preview.container)
            .environment(\.managedObjectContext, Store.preview.container.viewContext)
            .environmentObject(ErrorHandler())
            .environmentObject(NodeFilters())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
