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
#import "SpanVariable+CoreDataClass.h"
#include "NodeDuration.h"

typedef duration_t NodeDuration;

typedef struct NodeDurationInfo {
    NodeDuration min;
    NodeDuration max;
    NodeDuration average;
} NodeDurationInfo;

@interface NodeImportTask()

- (BOOL)loadMetadata:(NSError **)error into:(SpanNode *)node withContext:(NSManagedObjectContext *)ctx;

+ (int16_t)levelFromString:(NSString *)str;

- (BOOL)loadRunsInto:(SpanNode *)node context:(NSManagedObjectContext *)ctx withError:(NSError **)error;
- (BOOL)loadEventsInto:(SpanNode *)node context:(NSManagedObjectContext *)ctx withError:(NSError **)error;

+ (BOOL)parseDurationOld:(CSVRow)row into:(NodeDuration *)duration;
+ (BOOL)parseDurationNew:(CSVRow)row into:(NodeDuration *)duration;

+ (SpanRun *)parseRun:(CSVRow)row withContext:(NSManagedObjectContext *)ctx info:(NodeDurationInfo *)info;
+ (SpanEvent *)parseEvent:(CSVRow)row withContext:(NSManagedObjectContext *)ctx;

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

+ (BOOL)parseDurationOld:(CSVRow)row into:(NodeDuration *)duration {
    NSScanner *scan = [NSScanner scannerWithString:[row objectAtIndex:2]];
    Float64 secs;
    if (![scan scanDouble:&secs])
        return NO;
    duration_from_seconds(duration, secs);
    return YES;
}

+ (BOOL)parseDurationNew:(CSVRow)row into:(NodeDuration *)duration {
    NSScanner *s = [NSScanner scannerWithString:[row objectAtIndex:2]];
    NSScanner *ms = [NSScanner scannerWithString:[row objectAtIndex:3]];
    NSScanner *us = [NSScanner scannerWithString:[row objectAtIndex:4]];
    uint64_t temp;
    if (![s scanUnsignedLongLong:&temp])
        return NO;
    duration->seconds = (uint32_t)temp;
    if (![ms scanUnsignedLongLong:&temp])
        return NO;
    duration->millis = (uint16_t)temp;
    if (![us scanUnsignedLongLong:&temp])
        return NO;
    duration->micros = (uint16_t)temp;
    return YES;
}

+ (SpanRun *)parseRun:(CSVRow)row withContext:(NSManagedObjectContext *)ctx info:(NodeDurationInfo *)info {
    if (row.count < 3)
        return nil;
    NodeDuration duration;
    NSUInteger start = 3;
    if (row.count >= 5 && ![[row objectAtIndex:2] containsString:@"."]) {
        start = 5;
        if (![NodeImportTask parseDurationNew:row into:&duration])
            return nil;
    } else {
        if (![NodeImportTask parseDurationOld:row into:&duration])
            return nil;
    }
    if (duration_is_greater_than(&duration, &info->max))
        duration_copy(&info->max, &duration);
    if (duration_is_less_than(&duration, &info->min))
        duration_copy(&info->min, &duration);
    duration_add(&info->average, &duration);
    NSString *msg = [row objectAtIndex:1];
    SpanRun *run = [[SpanRun alloc] initWithContext:ctx];
    run.id = [NSUUID UUID];
    run.message = msg.length > 0 ? msg : nil;
    run.seconds = duration.seconds;
    run.milliSeconds = duration.millis;
    run.microSeconds = duration.micros;
    run.variables = [[NSMutableSet alloc] init];
    for (NSUInteger i = start; i != row.count; ++i) {
        NSString *variable = [row objectAtIndex:i];
        if (variable.length == 0)
            continue;
        SpanVariable *var = [[SpanVariable alloc] initWithContext:ctx];
        var.run = run;
        var.id = [NSUUID UUID];
        var.data = variable;
        [(NSMutableSet *)run.variables addObject:var];
    }
    return run;
}

+ (SpanEvent *)parseEvent:(CSVRow)row withContext:(NSManagedObjectContext *)ctx {
    if (row.count < 2)
        return nil;
    NSString *msg = [row objectAtIndex:1];
    SpanEvent *event = [[SpanEvent alloc] initWithContext:ctx];
    event.id = [NSUUID UUID];
    event.message = msg.length > 0 ? msg : nil;
    event.variables = [[NSMutableSet alloc] init];
    for (NSUInteger i = 2; i != row.count; ++i) {
        NSString *variable = [row objectAtIndex:i];
        if (variable.length == 0)
            continue;
        SpanVariable *var = [[SpanVariable alloc] initWithContext:ctx];
        var.id = [NSUUID UUID];
        var.event = event;
        var.data = variable;
        [(NSMutableSet *)event.variables addObject:var];
    }
    return event;
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
    return *error == nil;
}

- (BOOL)loadRunsInto:(SpanNode *)node context:(NSManagedObjectContext *)ctx withError:(NSError **)error {
    NSMutableSet<SpanRun *> *runs = (NSMutableSet *)node.runs;
    BufferedTextFile *file = [[BufferedTextFile alloc] init:_runsFile bufferSize:8192 withError:error];
    CSVParser *parser = [[CSVParser alloc] init:','];
    NodeDurationInfo info;
    duration_set_zero(&info.max);
    info.min.seconds = UINT32_MAX;
    info.min.millis = UINT16_MAX;
    info.min.micros = UINT16_MAX;
    int count = 0;
    duration_set_zero(&info.average);
    NSString *line;
    if (file == nil)
        return NO;
    *error = nil;
    while ((line = [file readLine:error]) != nil) {
        CSVRow row = [parser parseRow:line];
        SpanRun *run = [NodeImportTask parseRun:row withContext:ctx info:&info];
        if (run == nil) {
            *error = [NSError errorWithDomain:@"Parse error" code:0 userInfo:nil];
            return NO;
        }
        run.node = node;
        [runs addObject:run];
        count += 1;
    }
    duration_mul_scalar(&info.average, 1.0f / (float)count);
    node.averageSeconds = info.average.seconds;
    node.averageMilliSeconds = info.average.millis;
    node.averageMicroSeconds = info.average.micros;
    node.minSeconds = info.min.seconds;
    node.minMilliSeconds = info.min.millis;
    node.minMicroSeconds = info.min.micros;
    node.maxSeconds = info.max.seconds;
    node.maxMilliSeconds = info.max.millis;
    node.maxMicroSeconds = info.max.micros;
    return *error == nil;
}

- (BOOL)loadEventsInto:(SpanNode *)node context:(NSManagedObjectContext *)ctx withError:(NSError **)error {
    NSMutableSet<SpanEvent *> *events = (NSMutableSet *)node.events;
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
        event.node = node;
        [events addObject:event];
    }
    return *error == nil;
}

- (void)main {
    NSManagedObjectContext *ctx = [_container newBackgroundContext];
    ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
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
    if (![self loadRunsInto:node context:ctx withError:&error])
        NSLog(@"Warning: failed to load runs for %@: %@", _node.path, error);
    node.events = [[NSMutableSet alloc] init];
    if (![self loadEventsInto:node context:ctx withError:&error])
        NSLog(@"Warning: failed to load events for %@: %@", _node.path, error);
    if (![ctx save:&error])
        NSLog(@"Warning: failed to save database for %@: %@", _node.path, error);
}

@end
