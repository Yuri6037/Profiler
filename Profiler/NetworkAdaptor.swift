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

class NetworkAdaptor: ObservableObject, MsgHandler {
    private var net: NetManager?;
    private let errorHandler: ErrorHandler;
    private var connection: Connection?;
    private let container: NSPersistentContainer;
    private var projectId: NSManagedObjectID?;
    @Published var showConnectSheet = false;
    @Published var config: MessageServerConfig?;

    init(errorHandler: ErrorHandler, container: NSPersistentContainer) {
        self.errorHandler = errorHandler;
        self.container = container;
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

    func execDb(_ fn: @escaping (NSManagedObjectContext) throws -> Void) {
        container.performBackgroundTask { ctx in
            do {
                try fn(ctx)
            } catch let error {
                DispatchQueue.main.async {
                    self.errorHandler.pushError(AppError(fromError: error));
                }
            }
        };
    }

    func onMessage(message: Message) {
        switch message {
        case .serverConfig(let config):
            showConnectSheet = true;
            self.config = config;
            break;
        case .project(let project):
            execDb { ctx in
                let p = Project(context: ctx);
                p.timestamp = Date();
                p.appName = project.appName;
                p.name = project.name;
                p.version = project.version;
                p.commandLine = project.commandLine;
                let request: NSFetchRequest<Target> = NSFetchRequest(entityName: "Target");
                request.predicate = NSPredicate(format: "os = %@ AND family = %@ AND arch = %@", project.target.os, project.target.family, project.target.arch);
                var retrieved = try ctx.fetch(request).first;
                if retrieved == nil {
                    retrieved = Target(context: ctx);
                    retrieved?.os = project.target.os;
                    retrieved?.family = project.target.family;
                    retrieved?.arch = project.target.arch;
                }
                p.target = retrieved;
                if let cpu = project.cpu {
                    let request: NSFetchRequest<Cpu> = NSFetchRequest(entityName: "Cpu");
                    request.predicate = NSPredicate(format: "name = %@ AND coreCount = %d", cpu.name, cpu.coreCount);
                    var retrieved = try ctx.fetch(request).first;
                    if retrieved == nil {
                        retrieved = Cpu(context: ctx);
                        retrieved?.name = cpu.name;
                        retrieved?.coreCount = Int32(cpu.coreCount);
                    }
                    p.cpu = retrieved;
                }
                let zerospan = SpanNode(context: ctx)
                zerospan.project = p;
                zerospan.path = "/";
                zerospan.order = 0;
                zerospan.metadata = nil;
                try ctx.save();
                DispatchQueue.main.async {
                    self.projectId = p.objectID;
                }
            };
            break;
        case .spanAlloc(let span):
            if let projectId = projectId {
                execDb { ctx in
                    let p = ctx.object(with: projectId) as! Project;
                    let node = SpanNode(context: ctx);
                    node.project = p;
                    node.order = Int32(span.id);
                    let metadata = SpanMetadata(context: ctx);
                    metadata.level = Int16(span.metadata.level.raw);
                    metadata.file = span.metadata.file;
                    metadata.modulePath = span.metadata.modulePath;
                    metadata.target = span.metadata.target;
                    metadata.line = span.metadata.line != nil ? Int32(span.metadata.line!) : -1;
                    metadata.name = span.metadata.name;
                    node.metadata = metadata;
                    node.path = "/" + span.metadata.name;
                    try ctx.save();
                };
            }
            break
        }
    }

    func onError(error: Error) {
        errorHandler.pushError(AppError(fromError: error));
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
            return;
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
