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

#import "NodeImportTask.h"
#import "SpanNode+CoreDataClass.h"

@implementation NodeImportTask {
    NSUInteger _index;
    NSString *_runsFile;
    NSString *_metadataFile;
    NSString *_eventsFile;
    NSPersistentContainer *_container;
    TreeNode *_node;
    NSManagedObjectID *_oid;
}

- (instancetype)initWithTreeNode:(TreeNode *)node directory:(NSString *)dir container:(NSPersistentContainer *)container projectId:(NSManagedObjectID *)oid {
    _index = node.index;
    _runsFile = [[[dir stringByAppendingString:@"/runs/"] stringByAppendingFormat:@"%lu", node.index] stringByAppendingString:@".csv"];
    _metadataFile = [[[dir stringByAppendingString:@"/metadata/"] stringByAppendingFormat:@"%lu", node.index] stringByAppendingString:@".csv"];
    _eventsFile = [[[dir stringByAppendingString:@"/events/"] stringByAppendingFormat:@"%lu", node.index] stringByAppendingString:@".csv"];
    _container = container;
    _node = node;
    _oid = oid;
    return self;
}

- (void)main {
    //TODO: Assign node to project by fetching project from _projectId
    NSManagedObjectContext *ctx = [_container newBackgroundContext];
    SpanNode *node = [[SpanNode alloc] initWithContext:ctx];
    node.path = _node.path;
    node.id = (int32_t)_index;
}

@end
