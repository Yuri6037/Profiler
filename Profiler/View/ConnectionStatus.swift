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
import Protocol

struct SingleProgressView: View {
    @ObservedObject var progress: Progress;

    var body: some View {
        VStack {
            Text(progress.text)
            ProgressView(value: progress.value)
                .padding(.horizontal)
        }
    }
}

struct ConnectionStatus: View {
    @EnvironmentObject private var adaptor: NetworkAdaptor;
    @EnvironmentObject private var progressList: ProgressList;
    @State private var rows = 200;

    let width: CGFloat;

    var body: some View {
        VStack {
            Text(adaptor.text)
            ForEach(progressList.array) { item in
                SingleProgressView(progress: item)
            }
            if adaptor.isRecording {
                Button("Stop") {
                    adaptor.send(record: MessageClientRecord(maxRows: 0, enable:false))
                }
            } else {
                if width > 150 {
                    HStack {
                        IntPicker(min: 1, max:Int(adaptor.config?.maxRows ?? 200),value: $rows)
                        Button("Start") {
                            adaptor.send(record: MessageClientRecord(maxRows: UInt32(rows), enable: true))
                        }
                    }
                } else {
                    VStack {
                        IntPicker(min: 1, max:Int(adaptor.config?.maxRows ?? 200),value: $rows)
                        Button("Start") {
                            adaptor.send(record: MessageClientRecord(maxRows: UInt32(rows), enable: true))
                        }
                    }
                }
            }
        }
    }
}

struct ConnectionStatus_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionStatus(width: 0)
            .environmentObject(ProgressList())
            .environmentObject(NetworkAdaptor(errorHandler: ErrorHandler(), container: Store.preview.container, progressList: ProgressList()))
    }
}
