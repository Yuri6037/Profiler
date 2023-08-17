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

public struct CSVParser {
    let delimiter: Character;

    public init(delimiter: Character) {
        self.delimiter = delimiter
    }

    public func parseRow(_ row: String) -> [String] {
        let delimiter = self.delimiter.asciiValue!;
        let str = row.utf8CString;
        var quote = false;
        var array: [String] = [];
        var data: [UInt8] = [];
        var i = 0;
        while str[i] != 0x0 {
            if str[i] == UInt8(ascii: "\"") {
                if i + 1  < row.count && str[i + 1] == UInt8(ascii: "\"") {
                    //Double double-quotes
                    data.append(UInt8(ascii: "\""));
                } else {
                    quote = !quote;
                }
            } else if str[i] == delimiter && !quote {
                // We encountered a separator so create a new string.
                array.append(String(decoding: data, as: UTF8.self));
                data = [];
            } else {
                //Just append the character to the array
                data.append(UInt8(bitPattern: str[i]))
            }
            i += 1;
        }
        array.append(String(decoding: data, as: UTF8.self));
        return array;
    }
}
