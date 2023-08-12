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

extension Level {
    var color: Color {
        switch self {
        case .trace:
            return .cyan;
        case .debug:
            return .accentColor;
        case .info:
            return .green;
        case .warning:
            return .yellow;
        case .error:
            return .red;
        }
    }
}

struct SpanNodeInfo: View {
    @ObservedObject var node: SpanNode;
    @Binding var dataset: Dataset?;

    var body: some View {
        VStack {
            Text("Node Information").bold()
            VStack(alignment: .leading) {
                if let metadata = node.wMetadata {
                    HStack {
                        Text("Name").bold()
                        Text(metadata.wName)
                    }
                    HStack {
                        Text("Target").bold()
                        Text(metadata.wTarget)
                    }
                    HStack {
                        Text("File").bold()
                        Text(metadata.wFile ?? "Unknown")
                        if let line = metadata.wLine {
                            Text("(\(line.formatted()))")
                        }
                    }
                    HStack {
                        Text("Module Path").bold()
                        Text(metadata.wModulePath ?? "Unknown")
                    }
                    HStack {
                        Text("Level").bold()
                        Text(metadata.wLevel.name).foregroundColor(metadata.wLevel.color).bold()
                    }
                } else {
                    Text("No metadata for this node").bold()
                }
                HStack {
                    Text("Run count").bold()
                    Text((node.runs?.count ?? 0).formatted())
                }
                HStack {
                    Text("Min time").bold()
                    Text(node.wMinTime.formatted())
                }
                HStack {
                    Text("Max time").bold()
                    Text(node.wMaxTime.formatted())
                }
                HStack {
                    Text("Average time").bold()
                    Text(node.wAverageTime.formatted())
                }
                if let dataset = dataset {
                    Text("Dataset").bold()
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Min time").bold()
                            Text(dataset.wMinTime.formatted())
                        }
                        HStack {
                            Text("Max time").bold()
                            Text(dataset.wMaxTime.formatted())
                        }
                        HStack {
                            Text("Average time").bold()
                            Text(dataset.wAverageTime.formatted())
                        }
                        HStack {
                            Text("Median time").bold()
                            Text(dataset.wMedianTime.formatted())
                        }
                    }.padding(.leading)
                }

            }
        }
    }
}

struct SpanNodeInfo_Previews: PreviewProvider {
    static var previews: some View {
        SpanNodeInfo(node: Store.preview.newSample(), dataset: .constant(Store.preview.newSample()))
    }
}
