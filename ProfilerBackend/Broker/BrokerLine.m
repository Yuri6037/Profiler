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

#import <Foundation/Foundation.h>
#import "BrokerLine.h"

@implementation BrokerLine {
    size_t _clientId;
}

@synthesize clientIndex = _clientId;

- (instancetype)init {
    _type = BLT_UNKNOWN;
    _clientId = (size_t)-1;
    _data = nil;
    return self;
}

- (BOOL)parse:(NSString *)str withError:(NSError **)error {
    NSRange range = [str rangeOfString:@": "];
    _data = [str substringFromIndex:range.location + range.length];
    NSString *header = [str substringToIndex:range.location];
    NSString *clientIdStr = [header substringFromIndex:2];
    switch ([header characterAtIndex:0]) {
        case 'I':
            _type = BLT_LOG_INFO;
            break;
        case 'E':
            _type = BLT_LOG_ERROR;
            break;
        case 'D':
            _type = BLT_SPAN_DATA;
            break;
        case 'A':
            _type = BLT_SPAN_ALLOC;
            break;
        case 'S':
            _type = BLT_SPAN_EVENT;
            break;
        case 'C':
            _type = BLT_CONNECTION_EVENT;
            break;
    }
    NSUInteger clientId;
    if ([clientIdStr characterAtIndex:0] == 'N') {
        //There is no client, set it to an impossible number
        clientId = (NSUInteger)-1;
        return YES;
    }
    if (![self parseUnsigned:clientIdStr into:&clientId withError:error])
        return NO;
    _clientId = clientId;
    return YES;
}

- (BOOL)parseUnsigned:(NSString *)str into:(NSUInteger *)output withError:(NSError **)error {
    unsigned long long u;
    NSScanner *scanner = [NSScanner scannerWithString:str];
    if (![scanner scanUnsignedLongLong:&u]) {
        *error = [NSError errorWithDomain:@"BrokerLine" code:1 userInfo:nil];
        return NO;
    }
    *output = u;
    return YES;
}

@end
