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
import Protocol
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var adaptor: NetworkAdaptor
    @EnvironmentObject private var errorHandler: ErrorHandler
    @EnvironmentObject private var progressList: ProgressList
    @EnvironmentObject private var exportManager: ExportManager
    @Environment(\.managedObjectContext) private var viewContext;
    @Environment(\.persistentContainer) private var container;

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.timestamp, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<Project>

    @Binding var projectSelection: Project?
    @State private var nodeSelection: SpanNode?
    @State private var datasetsSelection: Set<Dataset> = []
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var deleteMode: Bool = false
    @State private var address = ""
    @StateObject private var filters: NodeFilters = .init()

    var sidebar: some View {
        VStack {
            if deleteMode {
                ProgressView()
            } else {
                GeometryReader { g in
                    VStack {
                        List(selection: $projectSelection) {
                            ForEach(items) {
                                ProjectLink(project: $0, onDelete: {
                                    deleteItem(project: $0)
                                })
                            }
                            #if os(iOS)
                                .onDelete(perform: { deleteItem(index: $0) })
                            #endif
                        }
                        .toolbar {
                            Menu {
                                Button {
                                    exportManager.importJson();
                                } label: {
                                    Label("Import from JSON...", systemImage: "j.square")
                                }
                                Button {
                                    
                                } label: {
                                    Label("Connect to server", systemImage: "app.connected.to.app.below.fill")
                                }
                            } label: {
                                Label("New project", systemImage: "plus")
                            }
                        }
                        if adaptor.isConnected {
                            Divider()
                            ConnectionStatus(width: g.size.width)
                                .padding(.bottom, 5)
                        } else {
                            ForEach(progressList.array) { item in
                                SingleProgressView(progress: item)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: adaptor.projectId) { pid in
            if let pid {
                projectSelection = viewContext.object(with: pid) as? Project
            }
        }
    }

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            sidebar: { sidebar },
            content: {
                if let project = projectSelection {
                    ProjectDetails(project: project, node: $nodeSelection, datasets: $datasetsSelection)
                } else {
                    Text("Select an item")
                }
            },
            detail: {
                if let node = nodeSelection {
                    SpanNodeDetails(node: node, datasets: $datasetsSelection)
                        .environmentObject(filters)
                        .toolbar {
                            Picker("Order", selection: $filters.order) {
                                // Swift is far too broken to see that the context is the Picker!!
                                ToolButton(icon: "square", text: "Keep items in the order of insertion", value: NodeFilters.Order.insertion)
                                ToolButton(icon: "arrow.up.square", text: "Sort from maximum time to minimum time", value: NodeFilters.Order.maximum)
                                ToolButton(icon: "arrow.down.square", text: "Sort from minimum time to maximum time", value: NodeFilters.Order.minimum)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            Spacer()
                            Picker("Distribution", selection: $filters.distribution) {
                                // Swift is far too broken to see that the context is the Picker!!
                                ToolButton(icon: "square.fill.on.square.fill", text: "Pick N items evenly distributed", value: NodeFilters.Distribution.even)
                                ToolButton(icon: "square.and.arrow.up.fill", text: "Pick the first N items", value: NodeFilters.Distribution.nFirst)
                                ToolButton(icon: "square.and.arrow.down.fill", text: "Pick the last N items", value: NodeFilters.Distribution.nLast)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            Spacer()
                        }
                        .searchable(text: $filters.text)
                } else if let project = projectSelection {
                    ProjectOverview(project: project)
                } else {
                    Text("Select an item")
                }
            }
        )
        #if os(macOS)
        .onDeleteCommand(perform: deleteItem)
        #endif
        .alert(isPresented: $errorHandler.showError, error: errorHandler.currentError) {
            Button("OK") {
                errorHandler.popError()
            }
        }
        .onAppear {
            columnVisibility = .all
        }
        .sheet(isPresented: $adaptor.showConnectSheet) {
            VStack {
                ClientConfig(maxRows: adaptor.config?.maxRows ?? 0, minPeriod: adaptor.config?.minPeriod ?? 0)
                    .padding()
            }
        }
    }

    private func deleteItem(index: IndexSet) {
        if let index = index.first {
            let project = items[index]
            projectSelection = project
            deleteItem()
        }
    }

    private func deleteItem(project: Project) {
        projectSelection = project
        deleteItem()
    }

    private func deleteItem() {
        if let selection = projectSelection {
            projectSelection = nil
            nodeSelection = nil
            deleteMode = true
            withAnimation {
                StoreUtils(container: container).deleteProject(selection) { error in
                    if let error {
                        errorHandler.pushError(AppError(fromNSError: error))
                    }
                    deleteMode = false
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(projectSelection: .constant(nil))
            .environment(\.persistentContainer, Store.preview.container)
            .environment(\.managedObjectContext, Store.preview.container.viewContext)
            .environmentObject(ErrorHandler())
            .environmentObject(ProgressList())
            .environmentObject(NetworkAdaptor(errorHandler: ErrorHandler(), container: Store.preview.container, progressList: ProgressList()))
            .environmentObject(ExportManager(container: Store.preview.container, errorHandler: ErrorHandler(), progressList: ProgressList()))
    }
}
