// Copyright 2022 Yuri6037
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
import ProfilerBackend

enum SpanLevel {
    case trace;
    case debug;
    case info;
    case warning;
    case error;

    init(cName: String) {
        switch cName {
        case "trace":
            self = .trace;
            break;
        case "debug":
            self = .debug;
            break;
        case "info":
            self = .info;
            break;
        case "warning":
            self = .warning;
            break;
        case "error":
            self = .error;
            break;
        default:
            self = .info;
            break;
        }
    }

    var name: String {
        switch self {
        case .trace:
            return "Trace";
        case .debug:
            return "Debug";
        case .info:
            return "Info";
        case .warning:
            return "Warning";
        case .error:
            return "Error";
        }
    }
}

struct SpanMetadata {
    let name: String;
    let level: SpanLevel;
    let target: String;
    let module: String;
    let file: String;
}

class SpanNode: Identifiable, Hashable, Equatable {
    @Published var metadata: SpanMetadata;
    @Published var index: UInt;
    @Published var dropped: Bool = false;
    @Published var active: Bool = false;
    @Published var average: String = "";
    @Published var min: String = "";
    @Published var max: String = "";
    @Published var events: [String] = [];

    init(metadata: SpanMetadata, index: UInt) {
        self.metadata = metadata;
        self.index = index;
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(index)
    }

    static func == (lhs: SpanNode, rhs: SpanNode) -> Bool {
        lhs.index == rhs.index
    }
}

class ProfilerSubscribtion: ObservableObject {
    @Published var lastLog: BrokerLineLog?;
    @Published var clientIndex: Int;
    @Published var spans: [SpanNode] = [];
    private var _service: ProfilerService;
    fileprivate var spanIdMap: [UInt: Int] = [:];

    fileprivate init(service: ProfilerService, client: Int) {
        _service = service;
        clientIndex = client;
    }

    func cancel() throws {
        try _service.sendCommand("kick " + String(clientIndex));
    }

    static func preview() -> ProfilerSubscribtion {
        ProfilerSubscribtion(service: ProfilerService(), client: 0);
    }
}

class ProfilerServiceManager {
    private static var _instance: ProfilerServiceManager?;
    
    public static func getInstance() -> ProfilerServiceManager {
        if _instance == nil {
            _instance = ProfilerServiceManager();
        }
        return _instance!;
    }

    private var _service: ProfilerService;

    private var _waitingSubscriptions: [(ProfilerSubscribtion) -> Void] = [];
    private var _subscribtions: [Int: ProfilerSubscribtion] = [:];

    private func handleEvent(broker: BrokerLine) {
        switch (broker.type) {
        case BLT_CONNECTION_EVENT:
            let connection = broker as! BrokerLineConnection;
            print("Received new connection from \(connection.address)");
            if let handler = self._waitingSubscriptions.first {
                self._waitingSubscriptions.remove(at: 0);
                let obj = ProfilerSubscribtion(service: self._service, client: broker.clientIndex)
                handler(obj)
                self._subscribtions[broker.clientIndex] = obj;
            }
            break;
        case BLT_LOG_INFO, BLT_LOG_ERROR:
            let log = broker as! BrokerLineLog;
            let subscribtion = _subscribtions[broker.clientIndex];
            subscribtion?.lastLog = log;
            break;
        case BLT_SPAN_ALLOC:
            let span = broker as! BrokerLineSpanAlloc;
            let subscribtion = _subscribtions[broker.clientIndex];
            subscribtion?.spans.append(SpanNode(
                metadata: SpanMetadata(
                    name: span.name,
                    level: SpanLevel(cName: span.level),
                    target: span.target,
                    module: span.module,
                    file: span.file + "(" + span.line + ")"
                ),
                index: span.index
            ));
            subscribtion?.spanIdMap[span.index] = (subscribtion?.spans.count ?? 1) - 1;
            break;
        case BLT_SPAN_DATA:
            let span = broker as! BrokerLineSpanData;
            let subscribtion = _subscribtions[broker.clientIndex];
            if let node = subscribtion?.spans[subscribtion?.spanIdMap[span.index] ?? 0] {
                node.active = span.active;
                node.dropped = span.dropped;
                node.min = span.min;
                node.max = span.max;
                node.average = span.average;
            }
            break;
        case BLT_SPAN_EVENT:
            let span = broker as! BrokerLineSpanEvent;
            let subscribtion = _subscribtions[broker.clientIndex];
            let id = subscribtion?.spanIdMap[span.index] ?? 0;
            if let node = (id > 0 && id < subscribtion?.spans.count ?? 0) ? subscribtion?.spans[id] : nil {
                node.events.append(span.msg + "  " + span.valueSet);
            }
            break;
        default:
            break;
        }
    }

    func connect(address: String, callback: @escaping (ProfilerSubscribtion) -> Void) throws {
        _waitingSubscriptions.append(callback);
        try _service.open();
        try _service.sendCommand("connect " + address);
    }

    init() {
        _service = ProfilerService();
        _service.setEventBlocks({ self.handleEvent(broker: $0) }, withErrorBlock: { error in
            
        });
        _service.start();
    }
}
