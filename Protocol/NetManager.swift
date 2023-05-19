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

class NetManager {
    public let channelFuture: EventLoopFuture<Channel>;

    init(address: String, port: Int = Constants.defaultPort) {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 4);
        let bootstrap = ClientBootstrap(group: group).channelInitializer { handler in
            handler.pipeline.addHandler(ByteToMessageHandler(Decoder()));
            //Annoyingly enough it appears that it's impossible to have multiple handlers in 1 channel...
            //handler.pipeline.addHandler(MessageToByteHandler(Encoder()));
        }
        channelFuture = bootstrap.connect(host: address, port: port);
    }
}