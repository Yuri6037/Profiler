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

enum ReadError: Error {
    case unknownMessage(UInt8);
}

enum MessageReadingState {
    case none;
    case header(UInt8);
    case payload(MessageHeader);
}

public final class Decoder: ByteToMessageDecoder {
    public typealias InboundOut = (MessageHeader, ByteBuffer?);

    private final var state = DecoderState.handshake;
    private final var msgReadState = MessageReadingState.none;

    private func decodeHello(buffer: inout ByteBuffer) -> ByteBuffer? {
        guard let slice = buffer.readSlice(length: Constants.helloMessageSize) else {
            return nil;
        }
        return slice;
    }
    
    private func decodeInternal(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
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
                context.fireChannelRead(self.wrapInboundOut((msg, nil)));
                msgReadState = .none;
                return .continue;
            }
            guard let buffer = buffer.readSlice(length: msg.payloadSize) else {
                return .needMoreData;
            }
            context.fireChannelRead(self.wrapInboundOut((msg, buffer)));
            msgReadState = .none;
            break;
        }
        return .continue;
    }

    public func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        var state: DecodingState = .continue;
        while (state != .needMoreData) {
            do {
                state = try self.decodeInternal(context: context, buffer: &buffer);
            } catch let error {
                print("Error while reading message: ", error);
                context.close(promise: nil);
            }
        }
        return state;
    }
}

public final class MessageDecoder: ChannelInboundHandler {
    public typealias InboundIn = (MessageHeader, ByteBuffer?);
    public typealias InboundOut = Message;

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let (header, buffer) = self.unwrapInboundIn(data);
        var reader: Reader;
        if let buf = buffer {
            reader = Reader(buffer: buf);
        } else {
            reader = Reader(buffer: ByteBuffer());
        }
        do {
            let msg = try header.decode(reader: &reader);
            print(msg)
        } catch let error {
            print("Error while decoding message: ", error);
            context.close(promise: nil);
        }
    }
}
