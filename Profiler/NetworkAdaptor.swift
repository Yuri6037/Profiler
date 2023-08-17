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
    private let parser = CSVParser(delimiter: ",");
    private var net: NetManager?;
    private var connection: Connection?;
    private var projectId: NSManagedObjectID?;
    private var evIndex = 0;
    private var runIndex = 0;
    @Published var showConnectSheet = false;
    @Published var config: MessageServerConfig?;

    init(errorHandler: ErrorHandler, container: NSPersistentContainer) {
        self.errorHandler = errorHandler;
        self.container = container;
        self.queue = DispatchQueue(label: "NetworkAdaptor", qos: .userInteractive);
        self.context = container.newBackgroundContext();
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
        self.queue.async {
            let p: Project?;
            if let projectId = self.projectId {
                p = self.context.object(with: projectId) as? Project;
            } else {
                p = nil;
            }
            do {
                try fn(self.context, p);
            } catch let error {
                DispatchQueue.main.async {
                    self.errorHandler.pushError(AppError(fromError: error));
                }
            }
        }
    }

    func onMessage(message: Message) {
        switch message {
        case .serverConfig(let config):
            showConnectSheet = true;
            self.config = config;
            break;
        case .project(let project):
            execDb { ctx, _ in
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
                self.projectId = p.objectID;
            };
            break;
        case .spanAlloc(let span):
            print(span);
            execDb { ctx, p in
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
            break;
        case .spanParent(_):
            break;
        case .spanFollows(_):
            break;
        case .spanEvent(let event):
            execDb { ctx, p in
                let row = self.parser.parseRow(event.message);
                if row.count < 3 {
                    return;
                }
                let request: NSFetchRequest<SpanNode> = NSFetchRequest(entityName: "SpanNode");
                request.predicate = NSPredicate(format: "project = %@ AND order = %d", p!, event.id);
                if let node = try ctx.fetch(request).first {
                    let e = SpanEvent(context: ctx);
                    e.node = node;
                    e.level = Int16(event.level.raw);
                    e.timestamp = Date(timeIntervalSince1970: Double(event.timestamp));
                    e.message = row[0];
                    e.target = row[row.count - 1];
                    e.module = row[row.count - 2];
                    e.order = Int64(self.evIndex);
                    self.evIndex += 1;
                    for i in 1..<row.count - 2 {
                        let v = SpanVariable(context: ctx);
                        v.event = e;
                        v.data = row[i];
                    }
                }
            }
            break;
        case .spanUpdate(let span):
            execDb { ctx, p in
                let request: NSFetchRequest<SpanNode> = NSFetchRequest(entityName: "SpanNode");
                request.predicate = NSPredicate(format: "project = %@ AND order = %d", p!, span.id);
                if let node = try ctx.fetch(request).first {
                    node.averageTime = Int64(span.averageTime.nanoseconds);
                    node.maxTime = Int64(span.maxTime.nanoseconds);
                    node.minTime = Int64(span.minTime.nanoseconds);
                }
                try ctx.save();
            };
            break;
        case .spanDataset(_):
            break;
        }
    }

    func onError(error: Error) {
        errorHandler.pushError(AppError(fromError: error));
    }

    func onConnect(connection: Connection) {
        self.connection = connection;
        evIndex = 0;
        runIndex = 0;
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
                self.net = nil;
                self.showConnectSheet = false;
                self.config = nil;
                self.errorHandler.pushError(AppError(description: "Lost connection with debug server"));
            }
        }
    }
}
