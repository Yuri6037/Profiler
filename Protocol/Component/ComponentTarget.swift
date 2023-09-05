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

public struct TargetHeader: Component {
    public let os: Vchar
    public let family: Vchar
    public let arch: Vchar

    public var payloadSize: Int { Int(os.length + family.length + arch.length) }

    public static var size: Int = Vchar.size * 3

    public static func read(buffer: inout ByteBuffer) -> TargetHeader {
        let os = Vchar.read(buffer: &buffer)
        let family = Vchar.read(buffer: &buffer)
        let arch = Vchar.read(buffer: &buffer)
        return TargetHeader(os: os, family: family, arch: arch)
    }
}

public struct Target {
    public let os: String
    public let family: String
    public let arch: String
}

extension TargetHeader: PayloadComponent {
    public typealias PayloadOut = Target

    public func readPayload(buffer: inout ByteBuffer) throws -> Target {
        let os = try os.readPayload(buffer: &buffer)
        let family = try family.readPayload(buffer: &buffer)
        let arch = try arch.readPayload(buffer: &buffer)
        return Target(os: os, family: family, arch: arch)
    }
}
