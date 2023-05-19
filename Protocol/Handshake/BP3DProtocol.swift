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

public struct BP3DProtocolMismatchError {
    public let expected: UInt32;
    public let actual: UInt32;
}

public struct BP3DVersionMismatchError {
    public let expected: Version;
    public let actual: Version;
}

public enum BP3DProtocolError: Error {
    case signatureMismatch;
    case protocolMismatch(BP3DProtocolMismatchError);
    case versionMismatch(BP3DVersionMismatchError);
}

public struct BP3DProtocol {
    public let name: UInt32;
    public let version: Version;

    public func initialHandshake(buffer: inout ByteBuffer) throws -> MessageHello {
        let msg = MessageHello(buffer: &buffer);
        if msg.signature != Constants.signature {
            throw BP3DProtocolError.signatureMismatch;
        }
        if msg.name != name {
            throw BP3DProtocolError.protocolMismatch(BP3DProtocolMismatchError(expected: name, actual: msg.name));
        }
        if !msg.version.matches(other: version) {
            throw BP3DProtocolError.versionMismatch(BP3DVersionMismatchError(expected: version, actual: msg.version));
        }
        return msg;
    }
}
