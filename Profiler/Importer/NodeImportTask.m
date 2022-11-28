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
#import "NodeImportTask.h"
#import "SpanNode+CoreDataClass.h"
#import "SpanMetadata+CoreDataClass.h"

@interface NodeImportTask()

- (BOOL)loadMetadata:(NSError **)error into:(SpanNode *)node withContext:(NSManagedObjectContext *)ctx;

+ (int16_t)levelFromString:(NSString *)str;

- (BOOL)loadRunsInto:(NSMutableSet<SpanRun *> *)runs context:(NSManagedObjectContext *)ctx withError:(NSError **)error;
- (BOOL)loadEventsInto:(NSMutableSet<SpanEvent *> *)events context:(NSManagedObjectContext *)ctx withError:(NSError **)error;

@end

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

+ (int16_t)levelFromString:(NSString *)str {
    if ([str isEqualToString:@"trace"])
        return 0;
    else if ([str isEqualToString:@"debug"])
        return 1;
    else if ([str isEqualToString:@"warning"])
        return 3;
    else if ([str isEqualToString:@"error"])
        return 4;
    else
        return 2;
}

- (BOOL)loadMetadata:(NSError **)error into:(SpanNode *)node withContext:(NSManagedObjectContext *)ctx {
    BufferedTextFile *file = [[BufferedTextFile alloc] init:_metadataFile bufferSize:8192 withError:error];
    CSVParser *parser = [[CSVParser alloc] init:','];
    NSString *line;
    if (file == nil)
        return NO;
    *error = nil;
    node.metadata = [[SpanMetadata alloc] initWithContext:ctx];
    node.metadata.id = [NSUUID UUID];
    while ((line = [file readLine:error]) != nil) {
        CSVRow row = [parser parseRow:line];
        NSString *key = [row objectAtIndex:0];
        NSString *value = [row objectAtIndex:1];
        if ([key isEqualToString:@"File"] && value.length > 0)
            node.metadata.file = value;
        else if ([key isEqualToString:@"Name"])
            node.metadata.name = value;
        else if ([key isEqualToString:@"Target"])
            node.metadata.target = value;
        else if ([key isEqualToString:@"Module path"] && value.length > 0)
            node.metadata.modulePath = value;
        else if ([key isEqualToString:@"Line"])
            node.metadata.line = (int32_t)[value integerValue];
        else if ([key isEqualToString:@"Level"])
            node.metadata.level = [NodeImportTask levelFromString:value];
    }
    return error == nil;
}

- (BOOL)loadRunsInto:(NSMutableSet<SpanRun *> *)runs context:(NSManagedObjectContext *)ctx withError:(NSError **)error {
    BufferedTextFile *file = [[BufferedTextFile alloc] init:_runsFile bufferSize:8192 withError:error];
    CSVParser *parser = [[CSVParser alloc] init:','];
    NSString *line;
    if (file == nil)
        return NO;
    *error = nil;
    while ((line = [file readLine:error]) != nil) {
        CSVRow row = [parser parseRow:line];
        SpanRun *run = [NodeImportTask parseRun:row withContext:ctx];
        if (run == nil) {
            *error = [NSError errorWithDomain:@"Parse error" code:0 userInfo:nil];
            return NO;
        }
        [runs addObject:run];
    }
    return error == nil;
}

- (BOOL)loadEventsInto:(NSMutableSet<SpanEvent *> *)events context:(NSManagedObjectContext *)ctx withError:(NSError **)error {
    BufferedTextFile *file = [[BufferedTextFile alloc] init:_eventsFile bufferSize:8192 withError:error];
    CSVParser *parser = [[CSVParser alloc] init:','];
    NSString *line;
    if (file == nil)
        return NO;
    *error = nil;
    while ((line = [file readLine:error]) != nil) {
        CSVRow row = [parser parseRow:line];
        SpanEvent *event = [NodeImportTask parseEvent:row withContext:ctx];
        if (event == nil) {
            *error = [NSError errorWithDomain:@"Parse error" code:0 userInfo:nil];
            return NO;
        }
        [events addObject:event];
    }
    return error == nil;
}

- (void)main {
    NSManagedObjectContext *ctx = [_container newBackgroundContext];
    Project *proj = (Project *)[ctx objectWithID:_oid];
    assert(proj != nil); //If this assertion fails then we have a pretty big problem: ProjectImporter did not save the database with the new project
    SpanNode *node = [[SpanNode alloc] initWithContext:ctx];
    node.path = _node.path;
    node.id = (int32_t)_index;
    node.project = proj;
    NSError *error;
    if (![self loadMetadata:&error into:node withContext:ctx])
        NSLog(@"Warning: failed to load metadata for %@: %@", _node.path, error);
    node.runs = [[NSMutableSet alloc] init];
    if (![self loadRunsInto:(NSMutableSet *)node.runs context:ctx withError:&error])
        NSLog(@"Warning: failed to load runs for %@: %@", _node.path, error);
    node.events = [[NSMutableSet alloc] init];
    if (![self loadEventsInto:(NSMutableSet *)node.events context:ctx withError:&error])
        NSLog(@"Warning: failed to load events for %@: %@", _node.path, error);
    if (![ctx save:&error])
        NSLog(@"Warning: failed to save database for %@: %@", _node.path, error);
}

@end
