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
import CoreData
import Protocol

extension Duration {
    func formatted() -> String {
        if seconds > 0 {
            return seconds.formatted() + "s";
        } else if milliseconds > 0 {
            return milliseconds.formatted() + "ms";
        } else {
            return microseconds.formatted() + "µs";
        }
    }
}

extension Dataset {
    var wTimestamp: Date { self.timestamp! }
    var wAverageTime: Duration { Duration(nanoseconds: UInt64(self.averageTime)) }
    var wMinTime: Duration { Duration(nanoseconds: UInt64(self.minTime)) }
    var wMaxTime: Duration { Duration(nanoseconds: UInt64(self.maxTime)) }
    var wMedianTime: Duration { Duration(nanoseconds: UInt64(self.medianTime)) }
}

extension Dataset: SampleData {
    static func newSample(context: NSManagedObjectContext) -> Self {
        let dataset = Dataset(context: context);
        dataset.timestamp = Date();
        return dataset as! Self; //WTF!?
    }
}
