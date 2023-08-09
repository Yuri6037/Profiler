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

public struct Version: Writable {
    public let major: UInt64;
    //The proper type for this is [u8; 24].
    public let preRelease: (UInt64, UInt64, UInt64);

    init(buffer: inout ByteBuffer) {
        major = buffer.readInteger(endianness: .little, as: UInt64.self)!;
        let p1 = buffer.readInteger(endianness: .little, as: UInt64.self)!;
        let p2 = buffer.readInteger(endianness: .little, as: UInt64.self)!;
        let p3 = buffer.readInteger(endianness: .little, as: UInt64.self)!;
        preRelease = (p1, p2, p3);
    }

    init(major: UInt64, preRelease: String) {
        self.major = major;
        let buf = Data(preRelease.utf8);
        var tuple: (UInt64, UInt64, UInt64) = (0, 0, 0);
        var motherfuckingswift = 24;
        if buf.count < motherfuckingswift {
            motherfuckingswift = buf.count;
        }
        let _ = withUnsafeMutableBytes(of: &tuple, { pointer in
            buf.copyBytes(to: pointer, count: motherfuckingswift);
        });
        self.preRelease = tuple;
    }

    public func matches(other: Version) -> Bool {
        return major == other.major && preRelease == other.preRelease;
    }

    public func write(buffer: inout ByteBuffer) {
        buffer.writeInteger(major, endianness: .little);
        buffer.writeInteger(preRelease.0, endianness: .little);
        buffer.writeInteger(preRelease.1, endianness: .little);
        buffer.writeInteger(preRelease.2, endianness: .little);
    }
}

public struct MessageHello: Writable {
    //WTF swift does not have fixed size arrays unlike C, C++, Rust, Java,
    //and pretty much all other proper languages, swift is really a pile of poop!
    //The proper type for this is [u8; 4].
    public let signature: UInt32;
    //The proper type for this is [u8; 4].
    public let name: UInt32;
    public let version: Version;

    init(buffer: inout ByteBuffer) {
        signature = buffer.readInteger(endianness: .little, as: UInt32.self)!;
        name = buffer.readInteger(endianness: .little, as: UInt32.self)!;
        version = Version(buffer: &buffer);
    }

    public func write(buffer: inout ByteBuffer) {
        buffer.writeInteger(signature, endianness: .little);
        buffer.writeInteger(name, endianness: .little);
        version.write(buffer: &buffer);
    }
}
