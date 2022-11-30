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
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Project.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Project>

    @State var importTask: ProjectImporter?;
    @State var projectSelection: Project?;
    @State var nodeSelection: SpanNode?;
    @State var columnVisibility = NavigationSplitViewVisibility.all;
    @State var hack: Bool = false;

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
                    ProjectDetails(project: project, selection: $nodeSelection)
                } else {
                    Text("Select an item")
                }
            },
            detail: {
                if let node = nodeSelection {
                    SpanNodeDetails(node: node)
                } else {
                    Text("Select an item")
                }
            }
        )
        .onDeleteCommand(perform: self.deleteItem)
        .toolbar {
            Button("Import") {
                openFileDialog(onPick: { url in
                    self.importProject(dir: url.path);
                })
            }
        }
        .alert("Database Error", isPresented: .constant(Database.shared.lastErrorExists), actions: {
            Button("OK") {
                Database.shared.lastError = nil;
            }
        }, message: {
            Text("\(Database.shared.lastErrorString)")
        })
        .onAppear {
            columnVisibility = .all;
        }
    }

    private func importProject(dir: String) {
        self.importTask = ProjectImporter(directory: dir, container: Database.shared.container);
        do {
            try self.importTask?.loadProject();
            try self.importTask?.importTree();
        } catch {
            //TODO: Error handling
            fatalError("\(error)");
        }
    }

    /*private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }*/

    private func deleteItem() {
        if let selection = self.projectSelection {
            self.projectSelection = nil;
            self.nodeSelection = nil;
            self.hack = true;
            DispatchQueue.main.async {
                withAnimation {
                    viewContext.delete(selection);
                    Database.shared.save();
                    self.hack = false;
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, Database.preview.container.viewContext)
    }
}
