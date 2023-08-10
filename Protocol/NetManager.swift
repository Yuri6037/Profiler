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
import Network
import NIOCore
import NIOPosix

public protocol MsgHandler {
    func onMessage(message: Message);
    func onError(error: Error);
    func onConnect(connection: Connection);
}

public class Connection {
    private let channel: Channel;

    fileprivate init(channel: Channel) {
        self.channel = channel
    }

    public func close() {
        self.channel.close(promise: nil);
    }

    public func sendClientConfig() {
        
    }

    public func sendRecord() {
        
    }
}

public class NetManager {
    private let handler: MsgHandler;
    private var close: EventLoopFuture<Void>?;

    init(handler: MsgHandler) {
        self.handler = handler;
    }

    public func connect(address: String, port: Int = Constants.defaultPort) async {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 4);
        let bootstrap = ClientBootstrap(group: group).channelInitializer { handler in
            handler.pipeline.addHandler(MessageToByteHandler(Encoder())).flatMap { _ in
                handler.pipeline.addHandler(ByteToMessageHandler(Decoder())).flatMap { _ in
                    handler.pipeline.addHandler(MessageDecoder()).flatMap { _ in
                        handler.pipeline.addHandlers(MessageHandler(handler: self.handler))
                    }
                }
            }
        }
        do {
            let channel = try await bootstrap.connect(host: address, port: port).get();
            self.handler.onConnect(connection: Connection(channel: channel))
            self.close = channel.closeFuture;
        } catch let error {
            self.handler.onError(error: error);
        }
    }

    public func wait() async {
        do {
            try await self.close?.get();
        } catch let error {
            self.handler.onError(error: error);
        }
    }
}
