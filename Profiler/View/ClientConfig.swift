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

struct ClientConfig: View {
    let maxRows: UInt32;
    let minPeriod: UInt16;
    @State var rows: Int;
    @State var period: Int;
    @State var averagePoints = 100;
    @State var enableRecording = true;

    init(maxRows: UInt32, minPeriod: UInt16) {
        self.minPeriod = minPeriod;
        self.maxRows = maxRows;
        _rows = .init(initialValue: Int(maxRows));
        _period = .init(initialValue: Int(minPeriod));
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Number of points for average:")
                IntPicker(min: 1, max: Int(UInt32.max), value: $averagePoints)
            }
            HStack {
                Text("Min period (ms):")
                Text(minPeriod.formatted()).bold()
            }
            HStack {
                Text("Period (ms):")
                IntPicker(min: Int(minPeriod), max: 1000, value: $period)
            }
            Text("Recording configuration").bold()
                .padding(.top)
            VStack(alignment: .leading) {
                HStack {
                    Text("Max rows:")
                    Text(maxRows.formatted()).bold()
                }
                HStack {
                    Text("Rows:")
                    IntPicker(min: 0, max: Int(maxRows), value: $rows);
                }
                Toggle("Start enabled", isOn: $enableRecording)
            }.padding(.leading)
        }
    }
}

struct ClientConfig_Previews: PreviewProvider {
    static var previews: some View {
        ClientConfig(maxRows: 1000000, minPeriod: 200)
    }
}
