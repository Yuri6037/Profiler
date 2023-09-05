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

public struct CpuHeader: Component {
    public let name: Vchar
    public let coreCount: UInt32

    public var payloadSize: Int { Int(name.length) }

    public static var size: Int = Size().add(Vchar.self).add(UInt32.self).bytes

    public static func read(buffer: inout ByteBuffer) -> CpuHeader {
        let name = Vchar.read(buffer: &buffer)
        let coreCount = UInt32.read(buffer: &buffer)
        return CpuHeader(name: name, coreCount: coreCount)
    }
}

public struct Cpu {
    public let name: String
    public let coreCount: UInt32
}

extension CpuHeader: PayloadComponent {
    public typealias PayloadOut = Cpu

    public func readPayload(buffer: inout ByteBuffer) throws -> Cpu {
        let name = try name.readPayload(buffer: &buffer)
        return Cpu(name: name, coreCount: coreCount)
    }
}
