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
    case error;
}

enum ReadError: Error {
    case unknownMessage(UInt8);
}

enum MessageReadingState {
    case none;
    case header(UInt8);
    case payload(MessageHeader);
}

enum MsgDecodeState {
    case needMoreSteps;
    case needMoreData;
    case `continue`;
}

struct Packet {
    let header: MessageHeader;
    let payload: ByteBuffer?;

    init(header: MessageHeader, payload: ByteBuffer?) {
        self.header = header;
        self.payload = payload;
    }

    init(header: MessageHeader) {
        self.header = header;
        self.payload = nil;
    }
}

final class Decoder: ByteToMessageDecoder {
    public typealias InboundOut = (Packet?, Error?);

    private final var state = DecoderState.handshake;
    private final var msgReadState = MessageReadingState.none;

    private func decodeHello(buffer: inout ByteBuffer) -> ByteBuffer? {
        guard let slice = buffer.readSlice(length: Constants.helloMessageSize) else {
            return nil;
        }
        return slice;
    }
    
    private func decodeInternal(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> MsgDecodeState {
        if (state == DecoderState.handshake) {
            guard var buffer = decodeHello(buffer: &buffer) else {
                return .needMoreData;
            }
            let msg = try Constants.proto.initialHandshake(buffer: &buffer);
            let _ = context.writeAndFlush(NIOAny(msg))
            state = .running;
            return .continue;
        }
        switch (self.msgReadState) {
        case .none:
            guard let ty = buffer.readInteger(endianness: .little, as: UInt8.self) else {
                return .needMoreData;
            }
            msgReadState = .header(ty);
            break;
        case let .header(ty):
            guard let size = MessageHeaderRegistry.sizeof(type: ty) else {
                throw ReadError.unknownMessage(ty);
            }
            guard var buffer = buffer.readSlice(length: size) else {
                return .needMoreData;
            }
            guard let msg = MessageHeaderRegistry.read(type: ty, buffer: &buffer) else {
                throw ReadError.unknownMessage(ty);
            }
            msgReadState = .payload(msg)
            break;
        case let .payload(msg):
            if msg.payloadSize == 0 {
                context.fireChannelRead(self.wrapInboundOut((Packet(header: msg), nil)));
                msgReadState = .none;
                return .continue;
            }
            guard let buffer = buffer.readSlice(length: msg.payloadSize) else {
                return .needMoreData;
            }
            context.fireChannelRead(self.wrapInboundOut((Packet(header: msg, payload: buffer), nil)));
            msgReadState = .none;
            return .continue;
        }
        return .needMoreSteps;
    }

    public func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        if state == .error {
            //Empty the buffer.
            buffer.clear()
            //Ensure connection is closed.
            let _ = context.close();
            //Return need for more data even if we just want to terminate the connection.
            return .needMoreData;
        }
        var state: MsgDecodeState = .needMoreSteps;
        while (state == .needMoreSteps) {
            do {
                state = try self.decodeInternal(context: context, buffer: &buffer);
            } catch let error {
                context.fireChannelRead(self.wrapInboundOut((nil, error)));
                self.state = .error;
                break;
            }
        }
        return state == .needMoreData ? .needMoreData : .continue;
    }
}

final class MessageDecoder: ChannelInboundHandler {
    public typealias InboundIn = (Packet?, Error?);
    public typealias InboundOut = (Message?, Error?);

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let (packet, error) = self.unwrapInboundIn(data);
        if let error = error {
            context.fireChannelRead(self.wrapInboundOut((nil, error)));
        }
        if let packet = packet {
            var buffer: ByteBuffer;
            if let buf = packet.payload {
                buffer = buf;
            } else {
                buffer = ByteBuffer();
            }
            do {
                let msg = try packet.header.decode(buffer: &buffer);
                context.fireChannelRead(self.wrapInboundOut((msg, nil)));
            } catch let error {
                context.fireChannelRead(self.wrapInboundOut((nil, error)));
            }
        }
    }
}

final class MessageHandler: ChannelInboundHandler {
    public typealias InboundIn = (Message?, Error?);

    private let handler: MsgHandler;

    init(handler: MsgHandler) {
        self.handler = handler;
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let (msg, error) = self.unwrapInboundIn(data);
        if let error = error {
            self.handler.onError(error: error);
        }
        if let msg = msg {
            self.handler.onMessage(message: msg);
        }
    }
}
