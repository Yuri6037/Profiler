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

enum DecoderState {
    case handshake;
    case running;
}

public final class Decoder: ByteToMessageDecoder {
    public typealias InboundOut = ByteBuffer;

    private final var state = DecoderState.handshake;

    private func decodeHello(buffer: inout NIOCore.ByteBuffer) -> ByteBuffer? {
        guard let slice = buffer.readSlice(length: Constants.helloMessageSize) else {
            return nil;
        }
        return slice;
    }

    public func decode(context: NIOCore.ChannelHandlerContext, buffer: inout NIOCore.ByteBuffer) throws -> NIOCore.DecodingState {
        if (state == DecoderState.handshake) {
            guard let buffer = decodeHello(buffer: &buffer) else {
                return .needMoreData;
            }
            context.fireChannelRead(self.wrapInboundOut(buffer));
            return .continue;
        }
        
        return .continue;
    }
}
