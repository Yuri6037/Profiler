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

#import "ProfilerService.h"
#import "ServiceBroker.h"
#import <TextTools/BufferedTextFile.h>

@interface ProfilerService()

- (NSError *)dumpBackendError;

- (void)timerFireMethod:(NSTimer *)timer;

@end

@implementation ProfilerService {
    NSURL *_serviceExe;
    NSURL *_workDir;
    NSTask *_task;
    NSFileHandle *_stdin;
    NSFileHandle *_stderr;
    BufferedTextFile *_stdout;
    uint32_t _refCount;
    ServiceBroker *_broker;
    void (^_block)(BrokerLine *broker);
    void (^_errorBlock)(NSError *error);
}

- (instancetype)init {
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.github.Yuri6037.ProfilerBackend"];
#ifdef __aarch64__
    _serviceExe = [NSURL fileURLWithPath:[bundle pathForResource:@"profiler-aarch64" ofType:@""]];
#else
    _serviceExe = [NSURL fileURLWithPath:[bundle pathForResource:@"profiler-amd64" ofType:@""]];
#endif
    NSLog(@"Path to profiler backend: %@", _serviceExe);
    _task = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *dir = [paths firstObject];
    _workDir = [NSURL fileURLWithPath:[dir stringByAppendingString:@"/ProfilerBackend"]];
    _broker = nil;
    _block = nil;
    _errorBlock = nil;
    return self;
}

- (NSURL *)getClientPath:(NSInteger)index {
    NSString *dirname = [NSString stringWithFormat:@"%ld", index];
    return [[_workDir URLByAppendingPathComponent:@"data"] URLByAppendingPathComponent:dirname];
}

- (void)start {
    SEL sel = @selector(timerFireMethod:);
    NSTimer *timer = [NSTimer timerWithTimeInterval:0 target:self selector:sel userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)setEventBlocks:(void (^)(BrokerLine *broker))block withErrorBlock:(void (^)(NSError *error))errorBlock {
    _block = block;
    _errorBlock = errorBlock;
}

- (void)timerFireMethod:(NSTimer *)timer {
    NSError *error;
    if (![self isAlive:&error]) {
        NSLog(@"Profiler backend has died: %@", error);
        if (_errorBlock != nil)
            (_errorBlock)(error);
    }
    BrokerLine *broker = [self pollEvent];
    if (_block != nil && broker != nil) {
        (_block)(broker);
    }
}

- (NSError *)dumpBackendError {
    NSMutableDictionary<NSErrorUserInfoKey, id> *info = [[NSMutableDictionary alloc] init];
    [info setValue:_workDir.path forKey:NSFilePathErrorKey];
    [info setValue:_serviceExe forKey:NSURLErrorKey];
    NSError *error;
    NSData *data = [_stderr readDataToEndOfFileAndReturnError:&error];
    if (data == nil)
        [info setValue:error forKey:NSUnderlyingErrorKey];
    else {
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [info setValue:str forKey:NSDebugDescriptionErrorKey];
    }
    return [NSError errorWithDomain:@"ProfilerServiceBackendError" code:_task.terminationStatus userInfo:info];
}

- (BOOL)close:(NSError **)error {
    --_refCount;
    if (_task != nil && _refCount == 0) {
        [self sendCommand:@"stop" withError:error];
        [_task waitUntilExit];
        BOOL flag = YES;
        if (_task.terminationStatus != 0) {
            *error = [self dumpBackendError];
            flag = NO;
        }
        _broker = nil;
        _stdout = nil;
        _stdin = nil;
        _stderr = nil;
        _task = nil;
        return flag;
    }
    return YES;
}

- (BOOL)open:(NSError **)error {
    ++_refCount;
    if (_task != nil)
        return YES;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:_workDir.path withIntermediateDirectories:YES attributes:nil error:error])
        return NO;
    NSTask *task = [[NSTask alloc] init];
    task.executableURL = _serviceExe;
    task.currentDirectoryURL = _workDir;
    NSPipe *sin = [NSPipe pipe];
    NSPipe *serr = [NSPipe pipe];
    NSPipe *sout = [NSPipe pipe];
    _stdin = sin.fileHandleForWriting;
    _stderr = serr.fileHandleForReading;
    _broker = [[ServiceBroker alloc] initWithPipe:sout.fileHandleForReading error:error];
    if (_broker == nil)
        return NO;
    [task setStandardInput:sin];
    [task setStandardOutput:sout];
    [task setStandardError:serr];
    if (![task launchAndReturnError:error])
        return NO;
    [_broker start];
    _task = task;
    return YES;
}

- (BOOL)sendCommand:(NSString *)command withError:(NSError **)error {
    if (_task == nil)
        return YES;
    command = [command stringByAppendingString:@"\n"];
    const char *str = [command UTF8String];
    NSData *data = [NSData dataWithBytes:str length:command.length];
    if (![_stdin writeData:data error:error]) {
        *error = [_task.standardInput streamError];
        return NO;
    }
    if (!_task.isRunning) {
        *error = [self dumpBackendError];
        return NO;
    }
    return YES;
}

- (BrokerLine * _Nullable)pollEvent {
    if (_task == nil)
        return nil;
    return [_broker pollEvent];
}

- (BOOL)isAlive:(NSError **)error {
    if (_task == nil)
        return YES;
    if (!_task.isRunning) {
        *error = [self dumpBackendError];
        return NO;
    }
    if (![_broker checkAlive:error])
        return NO;
    return YES;
}

@end
