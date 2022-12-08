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

struct SpanNodeDetails: View {
    @ObservedObject var node: SpanNode;
    var renderNode: Bool = false;
    @State var points: [Double] = [];

    func loadChartPoints(node: SpanNode) {
        points = []
        let nodeId = node.objectID;
        Database.shared.container.performBackgroundTask { ctx in
            let node = ctx.object(with: nodeId);
            let req: NSFetchRequest<SpanRun> = SpanRun.fetchRequest();
            req.fetchLimit = 1024;
            req.predicate = NSPredicate(format: "node=%@", node);
            do {
                let objs = try ctx.fetch(req);
                let points = objs.map { $0.wTimeMicros };
                DispatchQueue.main.async {
                    self.points = points;
                }
            } catch {
                //Ignore the error
            }
        }
    }

    var body: some View {
        VStack {
            if renderNode {
                SpanNodeInfo(node: node)
            }
            SpanRunTable(node: node)
            SpanEventTable(events: node.wEvents)
            if points.count > 0 {
                ScrollView(.horizontal) {
                    LineChart(width: 2048, height: 256, points: points)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear { loadChartPoints(node: node) }
        .onChange(of: node) { loadChartPoints(node: $0) }
    }
}

struct SpanNodeDetails_Previews: PreviewProvider {
    static var previews: some View {
        SpanNodeDetails(node: Database.preview.getFirstNode()!)
    }
}
