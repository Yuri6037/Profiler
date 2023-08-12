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

struct ProjectDetails: View {
    @ObservedObject var project: Project;
    
    @Binding var node: SpanNode?;
    @Binding var dataset: Dataset?;
    @Binding var renderNode: Bool;

    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    ProjectInfo(project: project)
                    if renderNode {
                        if let node = node {
                            Spacer()
                            SpanNodeInfo(node: node, dataset: $dataset)
                        }
                    }
                }.padding(.horizontal).padding(.top)
                if let cmdline = project.wCommandLine {
                    Divider()
                    VStack {
                        Text("Command Line").bold()
                        Text(cmdline)
                    }
                }
                List(project.wDatasets.sorted(by: { $1.wTimestamp > $0.wTimestamp }), selection: $dataset) { item in
                    Text(item.wTimestamp.formatted())
                }
                List(project.wNodes.sorted(by: { $1.wOrder > $0.wOrder }), selection: $node) { item in
                    NavigationLink(value: item) {
                        Text(item.wPath)
                    }
                }
                //TODO: Implement dataset list
            }
            .onChange(of: geometry.size) { newSize in
                if newSize.width < 400 {
                    renderNode = false;
                } else {
                    renderNode = true;
                }
            }
        }
    }
}

struct ProjectDetails_Previews: PreviewProvider {
    static var previews: some View {
        ProjectDetails(project: Store.preview.newSample(), node: .constant(nil), dataset: .constant(nil), renderNode: .constant(true))
    }
}
