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

struct NodeDashboard: View {
    @ObservedObject var node: SpanNode

    var body: some View {
        GroupBox(label: Label(node.wPath, systemImage: "doc").foregroundColor(node.wMetadata?.wLevel.color ?? .accentColor)) {
            if let metadata = node.wMetadata {
                HStack {
                    Text("Name").bold()
                    Spacer()
                    Text(metadata.wName)
                }
                HStack {
                    Text("Target").bold()
                    Spacer()
                    Text(metadata.wTarget)
                }
                HStack {
                    Text("File").bold()
                    Spacer()
                    Text(metadata.wFile ?? "Unknown")
                    if let line = metadata.wLine {
                        Text("(\(line.formatted()))")
                    }
                }
                HStack {
                    Text("Module Path").bold()
                    Spacer()
                    Text(metadata.wModulePath ?? "Unknown")
                }
                HStack {
                    Text("Level").bold()
                    Spacer()
                    Text(metadata.wLevel.name).foregroundColor(metadata.wLevel.color).bold()
                }
            } else {
                Text("No metadata for this node").bold()
            }
            HStack {
                Text("Min time").bold()
                Spacer()
                Text(node.wMinTime.formatted())
            }
            HStack {
                Text("Max time").bold()
                Spacer()
                Text(node.wMaxTime.formatted())
            }
            HStack {
                Text("Average time").bold()
                Spacer()
                Text(node.wAverageTime.formatted())
            }
        }.padding()
    }
}

struct ProjectOverview: View {
    @Environment(\.horizontalSizeClass) var sizeClass;
    @EnvironmentObject private var adaptor: NetworkAdaptor
    @EnvironmentObject private var errorHandler: ErrorHandler
    @Environment(\.persistentContainer) private var container: NSPersistentContainer
    @ObservedObject private var project: Project
    @FetchRequest private var events: FetchedResults<SpanEvent>

    init(project: Project) {
        self.project = project
        let events: NSFetchRequest<SpanEvent> = SpanEvent.fetchRequest()
        events.sortDescriptors = [NSSortDescriptor(keyPath: \SpanEvent.order, ascending: true)]
        events.predicate = NSPredicate(format: "node.project=%@", project)
        events.fetchLimit = MAX_UI_ROWS
        _events = FetchRequest(fetchRequest: events)
    }

    var body: some View {
        GeometryReader { g in
            VStack {
                ScrollView {
                    if g.size.width > 500 {
                        LazyVGrid(columns: [.init(), .init()]) {
                            ForEach(project.wNodes) { item in
                                NodeDashboard(node: item)
                            }
                        }
                    } else {
                        ForEach(project.wNodes) { item in
                            NodeDashboard(node: item)
                        }
                    }
                }
                Divider()
                SpanEventTable(events: events.map { DisplaySpanEvent(fromModel: $0) })
                if adaptor.isConnected && sizeClass == .compact {
                    Divider()
                    ConnectionStatus(width: g.size.width)
                }
            }
        }
    }
}

struct ProjectOverview_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NodeDashboard(node: Store.preview.newSample())
            ProjectOverview(project: Store.preview.newSample())
                .environment(\.persistentContainer, Store.preview.container)
                .environmentObject(ErrorHandler())
                .environmentObject(NetworkAdaptor(errorHandler: ErrorHandler(), container: Store.preview.container, progressList: ProgressList()))
        }
    }
}
