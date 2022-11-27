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

#import <TextTools/TextTools.h>
#import "ProjectImporter.h"
#import "TreeNode.h"
#import "NodeImportTask.h"

@implementation ProjectImporter {
    NSString *_dir;
    NSString *_treeFile;
}

- (instancetype)init:(NSString *)dir {
    _dir = dir;
    _treeFile = [_dir stringByAppendingString:@"/tree.txt"];
    return self;
}

- (BOOL)loadInOperationQueue:(NSOperationQueue *)queue withContainer:(NSPersistentContainer *)container error:(NSError **)error {
    BufferedTextFile *file = [[BufferedTextFile alloc] init:_treeFile bufferSize:8192 withError:error];
    NSString *line;
    if (file == nil)
        return NO;
    *error = nil;
    while ((line = [file readLine:error])) {
        TreeNode *node = [[TreeNode alloc] initFromString:line];
        NodeImportTask *task = [[NodeImportTask alloc] initWithTreeNode:node directory:_dir container:container];
        [queue addOperation:task];
    }
    return error == nil;
}

@end
