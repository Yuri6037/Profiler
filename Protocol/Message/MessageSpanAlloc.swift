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

public struct MessageHeaderSpanAlloc: MessageHeader {
    public let id: UInt32;
    public let metadata: MetadataHeader;

    public static var size: Int = UInt32.size + MetadataHeader.size;

    public static func read(reader: inout Reader) -> MessageHeaderSpanAlloc {
        return MessageHeaderSpanAlloc(
            id: reader.read(UInt32.self),
            metadata: reader.read(MetadataHeader.self)
        );
    }

    public var payloadSize: Int { metadata.payloadSize };

    public func decode(reader: inout Reader) throws -> Message {
        return .spanAlloc(MessageSpanAlloc(
            id: id,
            metadata: try reader.read(metadata)
        ));
    }
}

public struct MessageSpanAlloc {
    public let id: UInt32;
    public let metadata: Metadata;
}
