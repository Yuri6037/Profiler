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
    @ObservedObject var node: SpanNode
    @Binding var datasets: Set<Dataset>
    @EnvironmentObject var errorHandler: ErrorHandler
    @EnvironmentObject var filters: NodeFilters
    @Environment(\.managedObjectContext) var viewContext;
    @Environment(\.persistentContainer) var container: NSPersistentContainer
    @Environment(\.horizontalSizeClass) var sizeClass;
    @State private var points: [Double]?
    @State private var runs: [DisplaySpanRun]?
    @State private var events: [DisplaySpanEvent]?
    @State private var showMoreSheet = false

    private func loadRuns(node: SpanNode) {
        runs = nil
        dbFunc(node: node, fetch: { node, datasets, ctx in
            let runs: NSFetchRequest<SpanRun> = SpanRun.fetchRequest()
            runs.sortDescriptors = filters.getSortDescriptors()
            runs.predicate = filters.getPredicate(node: node, datasets: datasets)
            let size = try ctx.count(for: runs)
            runs.fetchLimit = MAX_UI_ROWS
            runs.predicate = filters.getPredicate(size: size, maxSize: MAX_UI_ROWS, node: node, datasets: datasets)
            return runs
        }, handle: { runs in
            let runs = runs.map { DisplaySpanRun(fromModel: $0) }
            DispatchQueue.main.async {
                self.runs = runs
            }
        })
    }

    private func loadEvents(node: SpanNode) {
        events = nil
        dbFunc(node: node, fetch: { node, _, _ in
            let events: NSFetchRequest<SpanEvent> = SpanEvent.fetchRequest()
            events.fetchLimit = MAX_UI_ROWS
            events.sortDescriptors = [NSSortDescriptor(keyPath: \SpanEvent.order, ascending: true)]
            events.predicate = NSPredicate(format: "node=%@", node)
            return events
        }, handle: { events in
            let events = events.map { DisplaySpanEvent(fromModel: $0) }
            DispatchQueue.main.async {
                self.events = events
            }
        })
    }

    private func loadPoints(node: SpanNode) {
        points = nil
        dbFunc(node: node, fetch: { node, datasets, ctx in
            let filters = NodeFilters()
            let runs: NSFetchRequest<SpanRun> = SpanRun.fetchRequest()
            runs.sortDescriptors = filters.getSortDescriptors()
            runs.predicate = filters.getPredicate(node: node, datasets: datasets)
            let size = try ctx.count(for: runs)
            runs.fetchLimit = 1500
            runs.predicate = filters.getPredicate(size: size, maxSize: 1500, node: node, datasets: datasets)
            return runs
        }, handle: { runs in
            _ = runs.map { DisplaySpanRun(fromModel: $0) }
            let points = runs.map(\.wTime.seconds)
            DispatchQueue.main.async {
                self.points = points
            }
        })
    }

    private func dbFunc<T>(node: SpanNode, fetch: @escaping (NSManagedObject, [NSManagedObject], NSManagedObjectContext) throws -> NSFetchRequest<T>, handle: @escaping ([T]) -> Void) {
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

    private func loadData(node: SpanNode) {
        loadRuns(node: node)
        loadEvents(node: node)
        loadPoints(node: node)
    }

    var body: some View {
        GeometryReader { g in
            VStack {
                if let runs {
                    SpanRunTable(runs: runs)
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
                loadRuns(node: node)
                loadPoints(node: node)
            }
            .onChange(of: filters.distribution) { _ in loadRuns(node: node) }
            .onChange(of: filters.order) { _ in loadRuns(node: node) }
            .onChange(of: filters.text) { filters.updateTextFilter($0) { loadRuns(node: node) } }
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
                    }.padding()
                    Button(action: { showMoreSheet = false }) {
                        Text("OK")
                    }
                }.padding().frame(minWidth: 500, minHeight: 200)
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
