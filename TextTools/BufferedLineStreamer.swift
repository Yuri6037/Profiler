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

public class BufferedLineStreamer {
    private var buffer: ContiguousArray<CChar>;
    private var cursor = 0;

    public init(str: String) {
        buffer = str.utf8CString;
    }

    public func readLine() -> String? {
        if cursor >= buffer.count {
            return nil;
        }
        if buffer[cursor] == UInt8(ascii: "\n") {
            cursor += 1;
        }
        var data: [UInt8] = [];
        while cursor < buffer.count && buffer[cursor] != UInt8(ascii: "\n") {
            data.append(UInt8(bitPattern: buffer[cursor]))
            cursor += 1;
        }
        return String(decoding: data, as: UTF8.self);
    }
}
