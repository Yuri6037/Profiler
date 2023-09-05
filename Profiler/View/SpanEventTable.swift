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

struct SpanEventTable: View {
    var events: [DisplaySpanEvent]

    var body: some View {
        Table(events) {
            TableColumn("Timestamp", value: \.timestamp)
                .width(130)
            TableColumn("Level", value: \.level)
                .width(50)
            TableColumn("Target", value: \.target)
                .width(100)
            TableColumn("Module", value: \.module)
                .width(100)
            TableColumn("Message", value: \.message)
            TableColumn("Variables", value: \.variables)
        }
    }
}

struct SpanEventTable_Previews: PreviewProvider {
    static var previews: some View {
        SpanEventTable(events: [DisplaySpanEvent(fromModel: Store.preview.newSample())])
    }
}
