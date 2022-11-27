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

struct ProjectInfo: View {
    @ObservedObject var project: Project;

    var body: some View {
        VStack {
            Text("General").bold().padding(.bottom)
            VStack(alignment: .leading) {
                HStack {
                    Text("Name").bold()
                    Text(project.wName)
                }
                HStack {
                    Text("Version").bold()
                    Text(project.wVersion ?? "None")
                }
                HStack {
                    Text("Time").bold()
                    Text(project.wTimestamp.formatted())
                }
                if let system = project.wSystem {
                    Text("System").bold()
                    VStack(alignment: .leading) {
                        HStack {
                            Text("OS").bold()
                            Text(system.wOs)
                        }
                        HStack {
                            Text("CPU").bold()
                            Text(system.wCpuName)
                            Text("(\(system.wCpuCoreCount) core(s))")
                        }
                    }.padding(.leading)
                } else {
                    HStack {
                        Text("System").bold()
                        Text("None")
                    }
                }
            }
        }
    }
}

struct ProjectInfo_Previews: PreviewProvider {
    static var previews: some View {
        ProjectInfo(project: Database.preview.getFirstProject()!)
    }
}