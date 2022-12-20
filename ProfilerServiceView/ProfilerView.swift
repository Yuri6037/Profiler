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

struct ProfilerView: View {
    @ObservedObject var subscribtion: ProfilerSubscribtion;

    var body: some View {
        NavigationStack {
            List(subscribtion.spans) { node in
                NavigationLink(destination: {
                    Text("Span data goes here")
                }, label: {
                    VStack {
                        HStack {
                            Text("Name").bold()
                            Text(node.metadata.name)
                        }
                        HStack {
                            Text("Module").bold()
                            Text(node.metadata.module)
                        }
                        HStack {
                            Text("Target").bold()
                            Text(node.metadata.target)
                        }
                        HStack {
                            Text("File").bold()
                            Text(node.metadata.file)
                        }
                        HStack {
                            Text("Level").bold()
                            Text(node.metadata.level.name)
                        }
                    }
                })
            }
            Spacer()
            HStack {
                Text("Status: ").padding(.trailing)
                Text(subscribtion.lastLog?.msg ?? "")
            }
        }
    }
}

struct ProfilerView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilerView(subscribtion: ProfilerSubscribtion.preview())
    }
}
