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

struct ProjectLink: View {
    @EnvironmentObject private var exportManager: ExportManager
    @ObservedObject var project: Project
    let onDelete: () -> Void

    var body: some View {
        NavigationLink(value: project) {
            VStack(alignment: .leading) {
                HStack {
                    Text("\(project.wName)").bold()
                    Text("(\(project.wVersion ?? "No version"))")
                }
                Text("\(project.timestamp!, formatter: dateFormatter)")
            }
        }
#if os(iOS)
        .contextMenu {
            Button {
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Divider()
            Button {
                exportManager.exportJson(project)
            } label: {
                Label("Export to JSON...", systemImage: "j.square")
            }
            Button {
            } label: {
                Label("Export to CSV...", systemImage: "c.square")
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
#endif
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ProjectLink_Previews: PreviewProvider {
    static var previews: some View {
        ProjectLink(project: Store.preview.newSample(), onDelete: {})
            .environmentObject(ExportManager(container: Store.preview.container, errorHandler: ErrorHandler(), progressList: ProgressList()))
    }
}
