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

import SwiftUI

let MAX_UI_ROWS = 20000;

struct SpanNodeDetails: View {
    @ObservedObject var node: SpanNode;
    @Binding var dataset: Dataset?;
    @EnvironmentObject var errorHandler: ErrorHandler;
    @EnvironmentObject var filters: NodeFilters;
    @Environment(\.managedObjectContext) var viewContext;
    @Environment(\.persistentContainer) var container: NSPersistentContainer;
    var renderNode: Bool = false;
    @State private var points: [Double]?;
    @State private var runs: [DisplaySpanRun]?;
    @State private var events: [DisplaySpanEvent]?;

    private func loadRuns(node: SpanNode) {
        runs = nil;
        let size = node.runs?.count ?? 0;
        dbFunc(node: node, fetch: { node, dataset in
            let runs: NSFetchRequest<SpanRun> = SpanRun.fetchRequest();
            runs.fetchLimit = MAX_UI_ROWS;
            runs.sortDescriptors = filters.getSortDescriptors();
            runs.predicate = filters.getPredicate(size: size, maxSize: MAX_UI_ROWS, node: node, dataset: dataset);
            return runs;
        }, handle: { runs in
            let runs1 = runs.map { DisplaySpanRun(fromModel: $0) };
            DispatchQueue.main.async {
                self.runs = runs1;
            }
        });
    }

    private func loadEvents(node: SpanNode) {
        events = nil;
        dbFunc(node: node, fetch: { node, _ in
            let events: NSFetchRequest<SpanEvent> = SpanEvent.fetchRequest();
            events.fetchLimit = MAX_UI_ROWS;
            events.predicate = NSPredicate(format: "node=%@", node);
            return events;
        }, handle: { events in
            let events1 = events.map { DisplaySpanEvent(fromModel: $0) };
            DispatchQueue.main.async {
                self.events = events1;
            }
        });
    }

    private func loadPoints(node: SpanNode) {
        points = nil;
        let size = node.runs?.count ?? 0;
        dbFunc(node: node, fetch: { node, dataset in
            let filters = NodeFilters();
            let runs: NSFetchRequest<SpanRun> = SpanRun.fetchRequest();
            runs.fetchLimit = 1500;
            runs.sortDescriptors = filters.getSortDescriptors();
            runs.predicate = filters.getPredicate(size: size, maxSize: 1500, node: node, dataset: dataset);
            return runs;
        }, handle: { runs in
            //Swift requires useless values because its type inference system is garbagely broken
            let _ = runs.map { DisplaySpanRun(fromModel: $0) };
            let points = runs.map { $0.wTime.seconds }
            DispatchQueue.main.async {
                self.points = points;
            }
        });
    }

    private func dbFunc<T>(node: SpanNode, fetch: @escaping (NSManagedObject, NSManagedObject?) -> NSFetchRequest<T>, handle: @escaping ([T]) -> Void) {
        let nodeId = node.objectID;
        let datasetId = dataset?.objectID;
        container.performBackgroundTask { ctx in
            let dataset: NSManagedObject?;
            if let datasetId = datasetId {
                dataset = ctx.object(with: datasetId);
            } else {
                dataset = nil;
            }
            let node = ctx.object(with: nodeId);
            let req = fetch(node, dataset);
            do {
                let data = try ctx.fetch(req);
                handle(data);
            } catch {
                DispatchQueue.main.async {
                    errorHandler.pushError(AppError(fromNSError: error as NSError));
                }
            }
        }
    }
    
    private func loadData(node: SpanNode) {
        loadRuns(node: node);
        loadEvents(node: node);
        loadPoints(node: node);
    }

    var body: some View {
        VStack {
            if renderNode {
                SpanNodeInfo(node: node, dataset: $dataset)
            }
            if let runs = runs {
                SpanRunTable(runs: runs)
            } else {
                ProgressView()
            }
            if let events = events {
                SpanEventTable(events: events)
            } else {
                ProgressView()
            }
            if let points = points {
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
        .onChange(of: filters.distribution) { _ in loadRuns(node: node) }
        .onChange(of: filters.order) { _ in loadRuns(node: node) }
        .onChange(of: filters.text) { filters.updateTextFilter($0) { loadRuns(node: node) } }
    }
}

struct SpanNodeDetails_Previews: PreviewProvider {
    static var previews: some View {
        SpanNodeDetails(node: Store.preview.newSample(), dataset: .constant(Store.preview.newSample()))
            .environment(\.persistentContainer, Store.preview.container)
            .environment(\.managedObjectContext, Store.preview.container.viewContext)
            .environmentObject(ErrorHandler())
            .environmentObject(NodeFilters())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
