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

struct ProjectDetails: View {
    @ObservedObject var project: Project

    @Binding var node: SpanNode?
    @Binding var datasets: Set<Dataset>

    @State var showInfoSheet = false

    @FetchRequest var datasetList: FetchedResults<Dataset>

    @Environment(\.horizontalSizeClass) var sizeClass;

    init(project: Project, node: Binding<SpanNode?>, datasets: Binding<Set<Dataset>>) {
        self.project = project
        _node = node
        _datasets = datasets
        let datasetReq: NSFetchRequest<Dataset> = Dataset.fetchRequest()
        datasetReq.sortDescriptors = [NSSortDescriptor(keyPath: \Dataset.timestamp, ascending: true)]
        datasetReq.predicate = NSPredicate(format: "node.project=%@", project)
        datasetReq.fetchLimit = MAX_UI_ROWS
        _datasetList = FetchRequest(fetchRequest: datasetReq)
    }

    var body: some View {
        GeometryReader { g in
            VStack {
                if g.size.width > 500 && sizeClass == .regular {
                    HStack {
                        ProjectInfo(project: project)
                        if let node {
                            Spacer()
                            SpanNodeInfo(node: node)
                        }
                    }.padding(.horizontal).padding(.top)
                } else {
                    VStack {
                        Button(action: { showInfoSheet = true }) {
                            ToolButton(icon: "viewfinder", text: "More", value: 0)
                            Text("More")
                        }
                        .popover(isPresented: $showInfoSheet) {
                            VStack {
                                HStack {
                                    ProjectInfo(project: project)
                                    if let node {
                                        Spacer()
                                        SpanNodeInfo(node: node)
                                    }
                                }.padding()
                                Button(action: { showInfoSheet = false }) {
                                    Text("OK")
                                }
                            }.padding()
                                .presentationDetents([.fraction(0.4)])
                        }
                    }.padding(.horizontal).padding(.top)
                }
                if let cmdline = project.wCommandLine {
                    Divider()
                    VStack {
                        Text("Command Line").bold()
                        Text(cmdline)
                    }.padding()
                }
                Divider()
                List(selection: $node) {
                    NavigationLink(destination: { ProjectOverview(project: project) }) {
                        ToolButton(icon: "filemenu.and.cursorarrow", text: "Project Overview", value: 0)
                        Text("Project Overview")
                    }
                    ForEach(project.wNodes.sorted(by: { $1.wOrder > $0.wOrder })) { item in
                        NavigationLink(value: item) {
                            ToolButton(icon: "folder", text: item.wPath, value: 0)
                            Text(item.wPath)
                        }
                    }
                }
                List {
                    ForEach(datasetList.sorted(by: { $1.wTimestamp > $0.wTimestamp })) { item in
                        DatasetDashboard(
                            dataset: DisplayDataset(fromModel: item),
                            onChecked: { datasets.insert(item) },
                            onUnchecked: { datasets.remove(item) },
                            checked: datasets.contains(item)
                        ).tag(item)
                    }
                }
            }
        }
    }
}

struct ProjectDetails_Previews: PreviewProvider {
    static var previews: some View {
        ProjectDetails(project: Store.preview.newSample(), node: .constant(nil), datasets: .constant([]))
    }
}
