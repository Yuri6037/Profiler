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

struct SpanStatsView: View {
    @ObservedObject var node: SpanNode;
    
    var body: some View {
        VStack {
            Text("Stats").bold().padding(.bottom)
            HStack {
                Text("Path").bold()
                Text(node.path)
            }
            HStack {
                Text("Active").bold()
                Text(node.active ? "Yes" : "No")
            }
            HStack {
                Text("Dropped").bold()
                Text(node.dropped ? "Yes" : "No")
            }
            HStack {
                Text("Min time").bold()
                Text(node.min)
            }
            HStack {
                Text("Max time").bold()
                Text(node.max)
            }
            HStack {
                Text("Average time").bold()
                Text(node.average)
            }
            HStack {
                Text("Run count").bold()
                Text(node.runCount.formatted())
            }
        }
    }
}

struct SpanStatsView_Previews: PreviewProvider {
    static var previews: some View {
        SpanStatsView(node: SpanNode(metadata: SpanMetadata(name: "", level: .error, target: "", module: "", file: ""), index: 0))
    }
}
