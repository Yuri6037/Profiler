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

public enum Constants {
    public static let defaultPort = 4026;
    public static let messageQueueSize = 128;

    //This is supposed to be b"BP3D", but swift is far too much of a peace of shit to handle it!
    public static let signature: UInt32 = 0x44335042;

    public static let helloMessageSize = 40; //The hello packet is always 40 bytes long.

    //This is supposed to be b"PROF", but swift is far too much of a peace of shit to handle it!
    public static let protoName: UInt32 = 0x464F5250;
    public static let protoVersion = Version(major: 1, preRelease: "rc.2.0.0");
    public static let proto = BP3DProtocol(name: protoName, version: protoVersion);
}
