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

import CoreData
import Foundation
import Protocol
import SwiftString
import TextTools

class NetworkAdaptor: ObservableObject, MsgHandler {
    private let errorHandler: ErrorHandler
    private let queue: DispatchQueue
    private let group = DispatchGroup()
    private let context: NSManagedObjectContext
    private let container: NSPersistentContainer
    private let handler = NetworkHandler()
    private var net: NetManager?
    private var connection: Connection?
    var projectId: NSManagedObjectID?

    // ClientConfig sheet
    @Published var showConnectSheet = false
    @Published var config: MessageServerConfig?

    // Recording status
    @Published var isRecording = false
    private var rowsToRecord = UInt32(0)
    @Published var serverMaxRows = UInt32(0)

    // Inline ConnectionStatus in NetworkAdaptor since SwiftUI is a peace of shit unable to work behind 2 layers of ObservableObject.
    @Published var isConnected = false
    @Published var text = ""
    var progressList: ProgressList
    private var lastText = ""

    init(errorHandler: ErrorHandler, container: NSPersistentContainer, progressList: ProgressList) {
        self.errorHandler = errorHandler
        self.container = container
        queue = DispatchQueue(label: "NetworkAdaptor", qos: .userInteractive)
        context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        self.progressList = progressList
    }

    func setMessage(_ text: String) {
        self.text = text
    }

    func disconnect() {
        connection?.close()
    }

    func send(config: MessageClientConfig) {
        showConnectSheet = false
        rowsToRecord = config.record.maxRows
        isRecording = config.record.enable
        if isRecording {
            setMessage("Recording data...")
        } else {
            setMessage("Ready")
        }
        connection?.send(config: config)
    }

    func send(record: MessageClientRecord) {
        isRecording = record.enable
        rowsToRecord = record.maxRows
        if isRecording {
            setMessage("Recording data...")
        } else {
            setMessage("Ready")
        }
        connection?.send(record: record)
    }

    func execDb(_ fn: @escaping (NSManagedObjectContext, Project?) throws -> Void) {
        queue.async(group: group) {
            let p: Project?
            if let projectId = self.projectId {
                p = self.context.object(with: projectId) as? Project
            } else {
                p = nil
            }
            do {
                try fn(self.context, p)
            } catch {
                DispatchQueue.main.async {
                    self.errorHandler.pushError(AppError(fromError: error))
                }
            }
        }
    }

    func execDb(node: UInt32, _ fn: @escaping (NSManagedObjectContext, Project, SpanNode) throws -> Void) {
        execDb { ctx, p in
            let request: NSFetchRequest<SpanNode> = NSFetchRequest(entityName: "SpanNode")
            request.predicate = NSPredicate(format: "project = %@ AND order = %d", p!, node)
            if let node = try ctx.fetch(request).first {
                try fn(ctx, p!, node)
            }
        }
    }

    func setProject(_ id: NSManagedObjectID) {
        projectId = id
    }

    func onMessage(message: Message) {
        DispatchQueue.main.async(group: group) {
            switch message.getType() {
            case let .serverConfig(config):
                self.serverMaxRows = config.maxRows
                if let msg = checkAndAutoNegociate(maxRows: config.maxRows, minPeriod: config.minPeriod) {
                    self.send(config: msg)
                    self.send(config: msg)
                } else {
                    self.showConnectSheet = true
                    self.config = config
                }
            case let .project(project):
                self.handler.handleProject(adaptor: self, message: project)
            case let .spanAlloc(span):
                self.handler.handleSpanAlloc(adaptor: self, message: span)
            case .spanParent:
                break
            case .spanFollows:
                break
            case let .spanEvent(event):
                self.handler.handleSpanEvent(adaptor: self, message: event)
            case let .spanUpdate(span):
                if self.isRecording && span.runCount >= self.rowsToRecord {
                    self.isRecording = false
                    self.setMessage("Ready")
                }
                self.handler.handleSpanUpdate(adaptor: self, message: span)
            case let .spanDataset(dataset):
                self.handler.handleSpanDataset(adaptor: self, message: dataset)
            }
        }
    }

    func onError(error: Error) {
        DispatchQueue.main.async(group: group) {
            self.errorHandler.pushError(AppError(fromError: error))
        }
    }

    func onConnect(connection: Connection) {
        DispatchQueue.main.async(group: group) {
            self.connection = connection
            self.isConnected = true
            self.setMessage("Waiting for config...")
        }
    }

    func onDisconnect() {
        net = nil
        connection = nil
        showConnectSheet = false
        config = nil
        isConnected = false
        context.reset()
        lastText = ""
        text = ""
        errorHandler.pushError(AppError(description: "Lost connection with debug server"))
    }

    public func connect(url: URL) {
        let address = url.host ?? "localhost"
        let port = url.port
        if net != nil {
            errorHandler.pushError(AppError(description: "A network link already exists"))
            return
        }
        net = NetManager(handler: self)
        DispatchQueue.global(qos: .background).async {
            Task {
                if let port {
                    await self.net?.connect(address: address, port: port)
                } else {
                    await self.net?.connect(address: address)
                }
                await self.net?.wait()
                self.group.notify(queue: DispatchQueue.main) {
                    self.onDisconnect()
                }
            }
        }
    }
}
