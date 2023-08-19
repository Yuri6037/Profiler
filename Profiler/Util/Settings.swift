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

struct Defaults {
    static func integer(forKey: String) -> Int? {
        if UserDefaults.standard.object(forKey: forKey) == nil {
            return nil
        }
        return UserDefaults.standard.integer(forKey: forKey);
    }

    static func bool(forKey: String) -> Bool? {
        if UserDefaults.standard.object(forKey: forKey) == nil {
            return nil
        }
        return UserDefaults.standard.bool(forKey: forKey);
    }
}

struct ClientConfigDefaults {
    let averagePoints: Int;
    let period: Int;
    let maxLevel: Level;
    let rows: Int;
    let rowsIsDebugServer: Bool;
    let periodIsDebugServer: Bool;
    let enableRecording: Bool;

    init() {
        averagePoints = Defaults.integer(forKey: "network.maxPointsAverage") ?? 100;
        period = Defaults.integer(forKey: "network.period") ?? 200;
        maxLevel = Level(fromRaw: UInt8(Defaults.integer(forKey: "network.maxLevel") ?? 0));
        rows = Defaults.integer(forKey: "network.rows") ?? 0;
        rowsIsDebugServer = Defaults.bool(forKey: "network.rowsIsDebugServer") ?? true;
        periodIsDebugServer = Defaults.bool(forKey: "network.periodIsDebugServer") ?? true;
        enableRecording = Defaults.bool(forKey: "network.enableRecording") ?? true;
    }
}

func checkAndAutoNegociate(maxRows: UInt32, minPeriod: UInt16) -> MessageClientConfig? {
    let flag = Defaults.bool(forKey: "general.autoNegociate") ?? false;
    if !flag {
        return nil;
    }
    let rows: Int;
    let period: Int;
    let defaults = ClientConfigDefaults();
    if defaults.rowsIsDebugServer {
        rows = Int(maxRows);
    } else {
        rows = Int(defaults.rows > maxRows ? Int(maxRows) : defaults.rows);
    }
    if defaults.periodIsDebugServer {
        period = Int(minPeriod);
    } else {
        period = Int(defaults.period < minPeriod ? Int(minPeriod) : defaults.period);
    }
    return MessageClientConfig(
        maxAveragePoints: UInt32(defaults.averagePoints),
        record: MessageClientRecord(maxRows: UInt32(rows), enable: defaults.enableRecording),
        period: UInt16(period)
    );
}
