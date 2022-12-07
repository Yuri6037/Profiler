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

extension SpanRun {
    var dTime: String {
        if self.wSeconds > 0 {
            return self.wTimeSecs.formatted() + "s"
        } else if self.wMilliSeconds > 0 {
            return self.wTimeMillis.formatted() + "ms"
        } else {
            return self.wTimeMicros.formatted() + "µs"
        }
    }
    var dMessage: String { self.wMessage ?? "No message specified" }
}

let MAX_UI_RUNS = 5000;

struct SpanRunTable: View {
    @FetchRequest private var items: FetchedResults<SpanRun>;
    init(node: SpanNode) {
        let req: NSFetchRequest<SpanRun> = SpanRun.fetchRequest();
        req.fetchLimit = MAX_UI_RUNS;
        req.sortDescriptors = [
            NSSortDescriptor(keyPath: \SpanRun.seconds, ascending: false),
            NSSortDescriptor(keyPath: \SpanRun.milliSeconds, ascending: false),
            NSSortDescriptor(keyPath: \SpanRun.microSeconds, ascending: false)
        ];
        req.predicate = NSPredicate(format: "node=%@", node);
        _items = FetchRequest(fetchRequest: req, animation: .default)
    }

    var body: some View {
        Table(items) {
            TableColumn("Time", value: \.dTime)
            TableColumn("Message", value: \.dMessage)
        }
    }
}

struct SpanRunTable_Previews: PreviewProvider {
    static var previews: some View {
        SpanRunTable(node: Database.preview.getFirstNode()!)
    }
}
