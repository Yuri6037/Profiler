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

#import "ServiceBroker.h"
#import <TextTools/BufferedReader.h>
#import "BrokerLineConnection.h"
#import "BrokerLineLog.h"
#import "BrokerLineSpanData.h"
#import "BrokerLineSpanAlloc.h"
#import "BrokerLineSpanEvent.h"
#import "BrokerLineSpanPath.h"

@interface ServiceBroker()

+ (BrokerLine *)getBrokerLineFromType:(char)type;

@end

@implementation ServiceBroker {
    BufferedReader *_reader;
    NSMutableArray<BrokerLine *> *_messageQueue;
    NSLock *_lock;
    NSError *_lastError;
}

+ (BrokerLine *)getBrokerLineFromType:(char)type {
    switch (type) {
        case 'I':
        case 'E':
            return [[BrokerLineLog alloc] init];
        case 'D':
            return [[BrokerLineSpanData alloc] init];
        case 'A':
            return [[BrokerLineSpanAlloc alloc] init];
        case 'S':
            return [[BrokerLineSpanEvent alloc] init];
        case 'C':
            return [[BrokerLineConnection alloc] init];
        case 'P':
            return [[BrokerLineSpanPath alloc] init];
        default:
            return nil;
    }
}

- (instancetype)initWithPipe:(NSFileHandle *)read error:(NSError **)error {
    _reader = [[BufferedReader alloc] initWithHandle:read bufferSize:8192 error:error];
    if (_reader == nil)
        return nil;
    _messageQueue = [[NSMutableArray alloc] init];
    _lock = [[NSLock alloc] init];
    _lastError = nil;
    return [super init];
}

- (BrokerLine * _Nullable)pollEvent {
    if (_messageQueue.count == 0) //Properties are atomic by default
        return nil;
    [_lock lock];
    BrokerLine *msg = [_messageQueue firstObject];
    [_messageQueue removeObjectAtIndex:0];
    [_lock unlock];
    return msg;
}

- (BOOL)checkAlive:(NSError **)error {
    if (_lastError != nil) {
        *error = _lastError;
        _lastError = nil;
        return NO;
    }
    return YES;
}

- (void)main {
    while (true) {
        NSString *line = [_reader readLine];
        if (line == nil) {
            if (_reader.readLineError != nil)
                _lastError = _reader.readLineError;
            break;
        }
        BrokerLine *broker = [ServiceBroker getBrokerLineFromType:[line characterAtIndex:0]];
        if (broker != nil) {
            NSError *err = nil;
            if (![broker parse:line withError:&err]) {
                _lastError = err;
                break;
            }
            [_lock lock];
            [_messageQueue addObject:broker];
            [_lock unlock];
        }
    }
}

@end
