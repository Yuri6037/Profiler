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

public struct MetadataHeader: Component {
    public let level: Level
    public let line: UInt32?
    public let name: Vchar
    public let target: Vchar
    public let modulePath: Vchar?
    public let file: Vchar?

    public static var size: Int = Level.size + Option<UInt32>.size + Vchar.size * 2 + Option<Vchar>.size * 2

    public var payloadSize: Int { Int(name.length) + Int(target.length) + Int(modulePath?.length ?? 0) + Int(file?.length ?? 0) }

    public static func read(buffer: inout ByteBuffer) -> MetadataHeader {
        MetadataHeader(
            level: .read(buffer: &buffer),
            line: Option<UInt32>.read(buffer: &buffer).value,
            name: .read(buffer: &buffer),
            target: .read(buffer: &buffer),
            modulePath: Option<Vchar>.read(buffer: &buffer).value,
            file: Option<Vchar>.read(buffer: &buffer).value
        )
    }
}

public struct Metadata {
    public let level: Level
    public let line: UInt32?
    public let name: String
    public let target: String
    public let modulePath: String?
    public let file: String?
}

extension MetadataHeader: PayloadComponent {
    public typealias PayloadOut = Metadata

    public func readPayload(buffer: inout ByteBuffer) throws -> Metadata {
        try Metadata(
            level: level,
            line: line,
            name: name.readPayload(buffer: &buffer),
            target: target.readPayload(buffer: &buffer),
            modulePath: modulePath?.readPayload(buffer: &buffer),
            file: file?.readPayload(buffer: &buffer)
        )
    }
}
