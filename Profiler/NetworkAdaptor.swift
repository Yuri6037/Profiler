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

import Protocol
import Foundation
import SwiftString

class NetworkAdaptor: ObservableObject, MsgHandler {
    private var net: NetManager?;
    private let errorHandler: ErrorHandler;
    private var connection: Connection?;
    @Published var showConnectSheet = false;
    @Published var config: MessageServerConfig?;

    init(errorHandler: ErrorHandler) {
        self.errorHandler = errorHandler;
    }

    func disconnect() {
        connection?.close();
    }

    func send(config: MessageClientConfig) {
        showConnectSheet = false;
        self.config = nil;
        connection?.send(config: config);
    }

    func send(record: MessageClientRecord) {
        connection?.send(record: record);
    }

    func onMessage(message: Message) {
        switch message {
        case .serverConfig(let config):
            showConnectSheet = true;
            self.config = config;
            break;
        case .project(let project):
            print(project);
            break;
        }
    }

    func onError(error: Error) {
        errorHandler.pushError(AppError(fromError: error));
        connection?.close();
    }

    func onConnect(connection: Connection) {
        self.connection = connection;
    }

    public func connect(url: URL) {
        var path = url.path;
        let id = path.index(of: ":");
        var port: Int? = nil;
        if id != -1 {
            port = path[safe: id + 1...9999999].toInt();
            path = path[0..<id];
        }
        if net != nil {
            errorHandler.pushError(AppError(description: "A network link already exists"));
        }
        net = NetManager(handler: self);
        //Again another sign of a garbage language: far too stupid to understand
        //that path and port are intended to be MOVED not borrowed!!!
        //Even Rust borrow checker works better than this stupidly broken shitty language.
        let motherfuckingswift = path;
        let motherfuckingswift1 = port;
        Task {
            if let port = motherfuckingswift1 {
                await net?.connect(address: motherfuckingswift, port:port);
            } else {
                await net?.connect(address: motherfuckingswift);
            }
            await net?.wait()
            DispatchQueue.main.async {
                self.net = nil;
                self.showConnectSheet = false;
                self.config = nil;
                self.errorHandler.pushError(AppError(description: "Lost connection with debug server"));
            }
        }
    }
}
