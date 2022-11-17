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

#include <fcntl.h>

#import "BufferedTextFile.h"

#define BUF_SIZE 8

#define NSBufferedTextFileErrorDomain @"com.github.Yuri6037.Profiler.BufferedTextFile"

@interface BufferedTextFile()

- (BOOL)readBuffer:(NSError **)error;

@end

@implementation BufferedTextFile {
    char _buffer[BUF_SIZE];
    ssize_t _cursor;
    ssize_t _len;
    int _fd;
}

- (BufferedTextFile * _Nullable)init:(NSString *)file withError:(NSError **)error {
    const char *cfile = [file cStringUsingEncoding:NSUTF8StringEncoding];
    _fd = open(cfile, O_RDONLY);
    if (_fd == -1) {
        *error = [NSError errorWithDomain:NSBufferedTextFileErrorDomain code:errno userInfo:nil];
        return nil;
    }
    _cursor = 0;
    _len = 0;
    return self;
}

- (BOOL)readBuffer:(NSError **)error {
    ssize_t res = read(_fd, _buffer, BUF_SIZE);
    if (res == -1) {
        *error = [NSError errorWithDomain:NSBufferedTextFileErrorDomain code:errno userInfo:nil];
        return NO;
    }
    _cursor = 0;
    _len = res;
    return YES;
}

- (NSString * _Nullable)readLine:(NSError **)error {
    NSString *line = nil;
    if (_cursor == _len && ![self readBuffer:error])
        return nil;
    ssize_t i = _cursor;
    while (_buffer[i] != '\n' && _len > 0) {
        i += 1;
        if (i >= _len) {
            if (line == nil) {
                //allocate a new line
                NSUInteger len = i - _cursor;
                line = [[NSString alloc] initWithBytes:_buffer + _cursor length:len encoding:NSUTF8StringEncoding];
            } else {
                //append to the line
                NSUInteger len = i - _cursor;
                line = [line stringByAppendingString:[[NSString alloc] initWithBytes:_buffer + _cursor length:len encoding:NSUTF8StringEncoding]];
            }
            if (![self readBuffer:error])
                return nil;
            i = _cursor;
        }
    }
    if (i > _cursor) {
        if (line == nil) {
            //allocate a new line
            line = [[NSString alloc] initWithBytes:_buffer + _cursor length:i encoding:NSUTF8StringEncoding];
        } else {
            //append to the line
            line = [line stringByAppendingString:[[NSString alloc] initWithBytes:_buffer + _cursor length:i encoding:NSUTF8StringEncoding]];
        }
        _cursor = i + 1; // skip the '\n'
    }
    return line;
}

- (void)close {
    if (_fd != -1)
        close(_fd);
    _fd = -1;
}

- (void)dealloc {
    [self close];
}

@end
