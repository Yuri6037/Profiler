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

import Protocol
import SwiftUI

struct GeneralSettingsView: View {
    @AppStorage("general.autoNegociate") private var autoNegociate = false

    var body: some View {
        Form {
            Toggle("Automatically negociate client config", isOn: $autoNegociate)
        }
        .padding(20)
    }
}

struct NetworkSettingsView: View {
    @AppStorage("network.maxPointsAverage") private var averagePoints = 100
    @AppStorage("network.period") private var period = 200
    @AppStorage("network.maxLevel") private var maxLevel = Int(Level.trace.raw)
    @AppStorage("network.rows") private var rows = 0
    @AppStorage("network.rowsIsDebugServer") private var rowsIsDebugServer = true
    @AppStorage("network.periodIsDebugServer") private var periodIsDebugServer = true
    @AppStorage("network.enableRecording") private var enableRecording = true

    var body: some View {
        VStack {
            Text("Default settings to use to automatically fill the ClientConfig prompt.")
                .fixedSize(horizontal: false, vertical: true)
            Group {
                Text("Main configuration").bold()
                Toggle("Use the server's minimum period", isOn: $periodIsDebugServer)
                HStack {
                    Text("Number of points for average:")
                    Spacer()
                    IntPicker(min: 1, max: Int(UInt32.max), value: $averagePoints)
                }
                HStack {
                    Text("Period (ms):")
                    Spacer()
                    IntPicker(min: Int(1), max: 1000, value: $period)
                }
                HStack {
                    Text("Max level:")
                    Spacer()
                    Picker("", selection: $maxLevel) {
                        Text(Level.trace.name)
                            .foregroundColor(Level.trace.color)
                            .tag(Int(Level.trace.raw))
                        Text(Level.debug.name)
                            .foregroundColor(Level.debug.color)
                            .tag(Int(Level.debug.raw))
                        Text(Level.info.name)
                            .foregroundColor(Level.info.color)
                            .tag(Int(Level.info.raw))
                        Text(Level.warning.name)
                            .foregroundColor(Level.warning.color)
                            .tag(Int(Level.warning.raw))
                        Text(Level.error.name)
                            .foregroundColor(Level.error.color)
                            .tag(Int(Level.error.raw))
                    }
                    .frame(width: 128)
                }
            }
            Divider()
            Group {
                Text("Recording configuration").bold()
                Toggle("Start enabled", isOn: $enableRecording)
                Toggle("Use the server's maximum number of rows", isOn: $rowsIsDebugServer)
                HStack {
                    Text("Rows:")
                    Spacer()
                    IntPicker(min: 0, max: Int.max, value: $rows)
                }
            }
        }
        .padding()
    }
}

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, network
    }

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            NetworkSettingsView()
                .tabItem {
                    Label("Network", systemImage: "app.connected.to.app.below.fill")
                }
                .tag(Tabs.network)
        }
        .padding(20)
        .frame(width: 375, height: 300)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkSettingsView()
    }
}
