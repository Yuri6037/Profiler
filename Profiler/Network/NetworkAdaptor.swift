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
import CoreData
import TextTools

class NetworkAdaptor: ObservableObject, MsgHandler {
    private let errorHandler: ErrorHandler;
    private let queue: DispatchQueue;
    private let context: NSManagedObjectContext;
    private let container: NSPersistentContainer;
    private let handler = NetworkHandler();
    private var net: NetManager?;
    private var connection: Connection?;
    private var projectId: NSManagedObjectID?;
    private var inHandler = false;
    @Published var showConnectSheet = false;
    @Published var config: MessageServerConfig?;

    //Inline ConnectionStatus in NetworkAdaptor since SwiftUI is a peace of shit unable to work behind 2 layers of ObservableObject.
    @Published var isConnected = false;
    @Published var text = "";
    @Published var progress: CGFloat = 0;

    init(errorHandler: ErrorHandler, container: NSPersistentContainer) {
        self.errorHandler = errorHandler;
        self.container = container;
        self.queue = DispatchQueue(label: "NetworkAdaptor", qos: .userInteractive);
        self.context = container.newBackgroundContext();
    }

    func resetConnectionStatus() {
        self.setConnectionStatusProgress(total: 0, current: 0);
        if connection != nil {
            self.setConnectionStatusText("Connected with debug server");
        }
    }

    func setConnectionStatusText(_ text: String) {
        self.text = text;
        if text != "" {
            isConnected = true;
        } else {
            isConnected = false;
        }
    }

    func setConnectionStatusProgress(total: UInt, current: UInt) {
        if total == 0 && current == 0 {
            progress = 0;
        } else {
            progress = CGFloat(current) / CGFloat(total);
        }
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

    func execDb(_ fn: @escaping (NSManagedObjectContext, Project?) throws -> Void) {
        inHandler = true;
        self.queue.async {
            let p: Project?;
            if let projectId = self.projectId {
                p = self.context.object(with: projectId) as? Project;
            } else {
                p = nil;
            }
            do {
                try fn(self.context, p);
                DispatchQueue.main.async {
                    self.inHandler = false;
                    if self.connection == nil {
                        self.setConnectionStatusText("");
                    }
                }
            } catch let error {
                DispatchQueue.main.async {
                    self.errorHandler.pushError(AppError(fromError: error));
                    self.inHandler = false;
                }
            }
        }
    }

    func execDb(node: UInt32, _ fn: @escaping (NSManagedObjectContext, Project, SpanNode) throws -> Void) {
        execDb { ctx, p in
            let request: NSFetchRequest<SpanNode> = NSFetchRequest(entityName: "SpanNode");
            request.predicate = NSPredicate(format: "project = %@ AND order = %d", p!, node);
            if let node = try ctx.fetch(request).first {
                try fn(ctx, p!, node);
            }
        }
    }
    
    func setProject(_ id: NSManagedObjectID) {
        self.projectId = id;
    }

    func onMessage(message: Message) {
        switch message {
        case .serverConfig(let config):
            if let msg = checkAndAutoNegociate(maxRows: config.maxRows, minPeriod: config.minPeriod) {
                self.connection?.send(config: msg);
                self.connection?.send(config: msg);
            } else {
                showConnectSheet = true;
                self.config = config;
            }
            break;
        case .project(let project):
            handler.handleProject(adaptor: self, message: project);
            break;
        case .spanAlloc(let span):
            handler.handleSpanAlloc(adaptor: self, message: span);
            break;
        case .spanParent(_):
            break;
        case .spanFollows(_):
            break;
        case .spanEvent(let event):
            handler.handleSpanEvent(adaptor: self, message: event);
            break;
        case .spanUpdate(let span):
            handler.handleSpanUpdate(adaptor: self, message: span);
            break;
        case .spanDataset(let dataset):
            handler.handleSpanDataset(adaptor: self, message: dataset);
            break;
        }
    }

    func onError(error: Error) {
        errorHandler.pushError(AppError(fromError: error));
    }

    func onConnect(connection: Connection) {
        self.connection = connection;
        setConnectionStatusText("Connected with debug server");
        setConnectionStatusProgress(total: 0, current: 0);
    }

    func onDisconnect() {
        net = nil;
        connection = nil;
        showConnectSheet = false;
        config = nil;
        if !inHandler {
            setConnectionStatusText("");
        }
        errorHandler.pushError(AppError(description: "Lost connection with debug server"));
    }

    public func connect(url: URL) {
        let address = url.host ?? "localhost";
        let port = url.port;
        if net != nil {
            errorHandler.pushError(AppError(description: "A network link already exists"));
            return;
        }
        net = NetManager(handler: self);
        //Again another sign of a garbage language: far too stupid to understand
        //that path and port are intended to be MOVED not borrowed!!!
        //Even Rust borrow checker works better than this stupidly broken shitty language.
        Task {
            if let port = port {
                await net?.connect(address: address, port:port);
            } else {
                await net?.connect(address: address);
            }
            await net?.wait()
            DispatchQueue.main.async {
                self.onDisconnect();
            }
        }
    }
}
