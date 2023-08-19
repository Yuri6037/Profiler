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
    @Binding var datasets: Set<Dataset>;

    @State var showInfoSheet = false;

    var body: some View {
        GeometryReader { g in
            VStack {
                if g.size.width > 500 {
                    HStack {
                        ProjectInfo(project: project)
                        if let node = node {
                            Spacer()
                            SpanNodeInfo(node: node)
                        }
                    }.padding(.horizontal).padding(.top)
                } else {
                    VStack {
                        if g.size.height > 1000 {
                            ProjectInfo(project: project)
                                .padding(.bottom)
                        }
                        Button(action: { showInfoSheet = true }) {
                            ToolButton(icon: "viewfinder", text: "Open project/node information", value: 0)
                            Text("Open project/node information")
                        }
                    }.padding(.horizontal).padding(.top)
                }
                if let cmdline = project.wCommandLine {
                    Divider()
                    VStack {
                        Text("Command Line").bold()
                        Text(cmdline)
                    }
                }
                Divider()
                NavigationLink(destination: { ProjectOverview(project: project) }) {
                    ToolButton(icon: "filemenu.and.cursorarrow", text: "Project Overview", value: 0)
                    Text("Project Overview")
                }
                Divider()
                List(project.wNodes.sorted(by: { $1.wOrder > $0.wOrder }), selection: $node) { item in
                    NavigationLink(value: item) {
                        Text(item.wPath)
                    }
                }
                List {
                    if let node = node {
                        ForEach(node.wDatasets.sorted(by: { $1.wTimestamp > $0.wTimestamp })) { item in
                            DatasetDashboard(
                                dataset: DisplayDataset(fromModel: item),
                                onChecked: { datasets.insert(item) },
                                onUnchecked: { datasets.remove(item) },
                                checked: datasets.contains(item)
                            ).tag(item)
                        }
                    }
                }
                //TODO: Implement a preferences menu to provide defaults to the clientconfig message.
                //TODO: Implement dataset list
            }
            .sheet(isPresented: $showInfoSheet, onDismiss: { showInfoSheet = false }) {
                VStack {
                    HStack {
                        ProjectInfo(project: project)
                        if let node = node {
                            Spacer()
                            SpanNodeInfo(node: node)
                        }
                    }.padding()
                    Button(action: { showInfoSheet = false }) {
                        Text("OK")
                    }
                }.padding()
            }
        }
    }
}

struct ProjectDetails_Previews: PreviewProvider {
    static var previews: some View {
        ProjectDetails(project: Store.preview.newSample(), node: .constant(nil), datasets: .constant([]))
    }
}
