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
import CoreData

struct ContentView: View {
    @EnvironmentObject private var errorHandler: ErrorHandler;
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Project>

    @State private var projectSelection: Project?;
    @State private var nodeSelection: SpanNode?;
    @State private var columnVisibility = NavigationSplitViewVisibility.all;
    @State private var hack: Bool = false;
    @State private var renderNode: Bool = true;

    var sidebar: some View {
        VStack {
            if hack {
                Text("Attempting to prevail against CoreData blowing up SwiftUI.")
            } else {
                List(items, selection: $projectSelection) { ProjectLink(project: $0) }
            }
        }
    }

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            sidebar: { sidebar },
            content: {
                if let project = projectSelection {
                    ProjectDetails(project: project, selection: $nodeSelection, renderNode: $renderNode)
                } else {
                    Text("Select an item")
                }
            },
            detail: {
                if let node = nodeSelection {
                    SpanNodeDetails(node: node, renderNode: !renderNode)
                } else {
                    Text("Select an item")
                }
            }
        )
#if os(macOS)
        .onDeleteCommand(perform: self.deleteItem)
#endif
        .alert(isPresented: $errorHandler.showError, error: errorHandler.currentError) {
            Button("OK") {
                errorHandler.popError()
            }
        }
        .onAppear {
            columnVisibility = .all;
        }
    }

    private func deleteItem() {
        if let selection = self.projectSelection {
            self.projectSelection = nil;
            self.nodeSelection = nil;
            self.hack = true;
            DispatchQueue.main.async {
                withAnimation {
                    Database.shared.removeProject(proj: selection);
                    self.hack = false;
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, Database.preview.container.viewContext).environmentObject(ErrorHandler())
    }
}
