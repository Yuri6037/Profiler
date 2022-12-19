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

#import "BrokerLineSpanData.h"

@implementation BrokerLineSpanData

- (BOOL)parse:(NSString *)str withError:(NSError **)error {
    if (![super parse:str withError:error])
        return NO;
    if (super.csvData.count != 7) {
        *error = [NSError errorWithDomain:@"BrokerLineSpanData" code:super.csvData.count userInfo:nil];
        return NO;
    }
    if (![super parseUnsigned:[super.csvData objectAtIndex:6] into:&_runCount withError:error])
        return NO;
    _min = [super.csvData objectAtIndex:3];
    _max = [super.csvData objectAtIndex:4];
    _average = [super.csvData objectAtIndex:5];
    _active = [[super.csvData objectAtIndex:2] characterAtIndex:0] == 'A';
    _dropped = [[super.csvData objectAtIndex:1] characterAtIndex:0] == 'D';
    return YES;
}

@end
