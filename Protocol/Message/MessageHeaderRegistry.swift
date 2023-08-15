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
import NIO

enum MessageHeaderRegistry {
    private static var map: [UInt8: MessageHeader.Type] = [
        0: MessageHeaderProject.self,
        1: MessageHeaderSpanAlloc.self,
        2: MessageSpanParent.self,
        3: MessageSpanFollows.self,
        4: MessageHeaderSpanEvent.self,
        5: MessageSpanUpdate.self,
        6: MessageHeaderSpanDataset.self,
        7: MessageServerConfig.self
    ];

    public static func sizeof(type: UInt8) -> Int? {
        return map[type]?.size;
    }

    public static func read(type: UInt8, buffer: inout ByteBuffer) -> MessageHeader? {
        return map[type]?.read(buffer: &buffer)
    }
}
