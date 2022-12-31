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

import SwiftUI
import ErrorHandler

let MAX_UI_ROWS = 20000;

private struct Data {
    var points: [Double];
    var runs: [DisplaySpanRun];
    var events: [DisplaySpanEvent];
}

struct SpanNodeDetails: View {
    @ObservedObject var node: SpanNode;
    @EnvironmentObject var errorHandler: ErrorHandler;
    @Environment(\.database) var database: Database;
    var renderNode: Bool = false;
    @State private var data: Data?;

    func loadData(node: SpanNode) {
        data = nil;
        let nodeId = node.objectID;
        let size = node.wRuns.count;
        database.container.performBackgroundTask { ctx in
            let node = ctx.object(with: nodeId);
            let runs: NSFetchRequest<SpanRun> = SpanRun.fetchRequest();
            runs.fetchLimit = MAX_UI_ROWS;
            runs.sortDescriptors = [
                NSSortDescriptor(keyPath: \SpanRun.order, ascending: true)
            ];
            //Compute how many times to halve the rows in order to be under 20K
            if size > MAX_UI_ROWS {
                var halves = 2;
                while size / halves > MAX_UI_ROWS {
                    halves += 1;
                }
                runs.predicate = NSPredicate(format: "node=%@ AND modulus:by:(order, %d) == 0", node, halves);
            } else {
                runs.predicate = NSPredicate(format: "node=%@", node);
            }
            let events: NSFetchRequest<SpanEvent> = SpanEvent.fetchRequest();
            events.fetchLimit = MAX_UI_ROWS;
            events.predicate = NSPredicate(format: "node=%@", node);
            do {
                let runs = try ctx.fetch(runs);
                let events = try ctx.fetch(events);
                let points = runs.prefix(1024).map { $0.wTimeMicros };
                let runs1 = runs.map { DisplaySpanRun(fromModel: $0) };
                let events1 = events.map { DisplaySpanEvent(fromModel: $0) };
                DispatchQueue.main.async {
                    self.data = Data(points: points, runs: runs1, events: events1);
                }
            } catch {
                DispatchQueue.main.async {
                    errorHandler.pushError(AppError(fromNSError: error as NSError));
                }
            }
        }
    }

    var body: some View {
        VStack {
            if renderNode {
                SpanNodeInfo(node: node)
            }
            if let data = data {
                SpanRunTable(runs: data.runs)
                SpanEventTable(events: data.events)
                if data.points.count > 0 {
                    ScrollView(.horizontal) {
                        LineChart(width: 2048, height: 256, points: data.points)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                ProgressView()
            }
        }
        .onAppear { loadData(node: node) }
        .onChange(of: node) { loadData(node: $0) }
    }
}

struct SpanNodeDetails_Previews: PreviewProvider {
    static var previews: some View {
        SpanNodeDetails(node: Database.preview.getFirstNode()!).environment(\.database, Database.preview)
    }
}
