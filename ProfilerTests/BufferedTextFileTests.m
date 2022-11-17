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

#import <XCTest/XCTest.h>
#import "BufferedTextFile.h"

@interface BufferedTextFileTests : XCTestCase

@end

@implementation BufferedTextFileTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    NSError *err;
    NSString *line;
    BufferedTextFile *file = [[BufferedTextFile alloc] init:@"/etc/paths" withError:&err];
    XCTAssertNotNil(file);
    NSMutableString *str = [[NSMutableString alloc] init];
    while ((line = [file readLine:&err])) {
        XCTAssertGreaterThan([line length], 0);
        [str appendString:line];
        [str appendString:@"\n"];
    }
    NSString *expected = [NSString stringWithContentsOfFile:@"/etc/paths" encoding:NSUTF8StringEncoding error:&err];
    XCTAssertNotNil(str);
    XCTAssertEqualObjects(str, expected);
}

@end
