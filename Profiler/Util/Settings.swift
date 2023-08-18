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

import Foundation
import Protocol

struct ClientConfigDefaults {
    let averagePoints: Int;
    let period: Int;
    let maxLevel: Level;
    let rows: Int;
    let rowsIsDebugServer: Bool;
    let periodIsDebugServer: Bool;
    let enableRecording: Bool;

    init() {
        let defaults = UserDefaults.standard;
        averagePoints = defaults.integer(forKey: "network.maxPointsAverage");
        period = defaults.integer(forKey: "network.period");
        maxLevel = Level(fromRaw: UInt8(defaults.integer(forKey: "network.maxLevel")));
        rows = defaults.integer(forKey: "network.rows");
        rowsIsDebugServer = defaults.bool(forKey: "network.rowsIsDebugServer");
        periodIsDebugServer = defaults.bool(forKey: "network.periodIsDebugServer");
        enableRecording = defaults.bool(forKey: "network.enableRecording");
    }
}

func checkAndAutoNegociate(maxRows: UInt32, minPeriod: UInt16) -> MessageClientConfig? {
    let flag = UserDefaults.standard.bool(forKey: "general.autoNegociate");
    if !flag {
        return nil;
    }
    //TODO: Implement
    return nil;
}
