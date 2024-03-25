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

enum ProtocolState {
    case handshake
    case running
    case error
}

enum MsgDecodeError: Error {
    case unknownMessage(UInt8)
    case eof
}

final class FrameDecoder: ByteToMessageDecoder {
    typealias InboundOut = (ByteBuffer?, Error?)
    private final var state = ProtocolState.handshake

    private func decodeHello(buffer: inout ByteBuffer) -> ByteBuffer? {
        guard let slice = buffer.readSlice(length: Constants.helloMessageSize) else {
            return nil
        }
        return slice
    }

    func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        if state == .handshake {
            guard var buffer = decodeHello(buffer: &buffer) else {
                return .needMoreData
            }
            do {
                let msg = try Constants.proto.initialHandshake(buffer: &buffer)
                let _ = context.writeAndFlush(NIOAny(msg))
            } catch {
                context.fireChannelRead(wrapInboundOut((nil, error)))
                let _ = context.close()
            }
            state = .running
            return .continue
        }
        guard let length = buffer.readInteger(endianness: .little, as: UInt32.self) else {
            return .needMoreData
        }
        guard let buffer = buffer.readSlice(length: Int(length)) else {
            return .needMoreData
        }
        context.fireChannelRead(wrapInboundOut((buffer, nil)))
        return .continue
    }
}

final class MessageDecoder: ChannelInboundHandler {
    public typealias InboundIn = (ByteBuffer?, Error?)
    public typealias InboundOut = (Message?, Error?)

    public func decodeInternal(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws {
        guard let ty = buffer.readInteger(endianness: .little, as: UInt8.self) else {
            throw MsgDecodeError.eof
        }
        guard let msg = try MessageRegistry.read(type: ty, buffer: &buffer) else {
            throw MsgDecodeError.unknownMessage(ty)
        }
        context.fireChannelRead(wrapInboundOut((msg, nil)))
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let (buffer, error) = unwrapInboundIn(data)
        if let error = error {
            context.fireChannelRead(wrapInboundOut((nil, error)))
        }
        do {
            if var buffer = buffer {
                try self.decodeInternal(context: context, buffer: &buffer)
            }
        } catch {
            context.fireChannelRead(wrapInboundOut((nil, error)))
        }
    }
}

final class MessageHandler: ChannelInboundHandler {
    public typealias InboundIn = (Message?, Error?)

    private let handler: MsgHandler

    init(handler: MsgHandler) {
        self.handler = handler
    }

    public func channelRead(context _: ChannelHandlerContext, data: NIOAny) {
        let (msg, error) = unwrapInboundIn(data)
        if let error {
            handler.onError(error: error)
        }
        if let msg {
            handler.onMessage(message: msg)
        }
    }
}
