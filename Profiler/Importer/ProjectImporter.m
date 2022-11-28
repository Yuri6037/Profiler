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
#import "Project+CoreDataClass.h"
#import "System+CoreDataClass.h"

@interface ProjectImporter()

- (BOOL)loadInfoFile:(NSError **)error into:(Project *)proj withContext:(NSManagedObjectContext *)ctx;

@end

@implementation ProjectImporter {
    NSString *_dir;
    NSString *_treeFile;
    NSString *_projectFile;
    NSPersistentContainer *_container;
    NSManagedObjectID *_oid;
}

- (BOOL)loadInfoFile:(NSError **)error into:(Project *)proj withContext:(NSManagedObjectContext *)ctx {
    BufferedTextFile *file = [[BufferedTextFile alloc] init:_treeFile bufferSize:8192 withError:error];
    CSVParser *parser = [[CSVParser alloc] init:','];
    NSString *os = nil;
    NSString *cpuName = nil;
    int32_t cpuCoreCount = 0;
    NSString *line;
    if (file == nil)
        return NO;
    *error = nil;
    while ((line = [file readLine:error]) != nil) {
        CSVRow row = [parser parseRow:line];
        NSString *key = [row objectAtIndex:0];
        NSString *value = [row objectAtIndex:1];
        if ([key isEqualToString:@"Name"])
            proj.name = value;
        else if ([key isEqualToString:@"Version"])
            proj.version = value;
        else if ([key isEqualToString:@"Os"])
            os = value;
        else if ([key isEqualToString:@"CpuName"])
            cpuName = value;
        else if ([key isEqualToString:@"CpuCoreCount"])
            cpuCoreCount = (int32_t)[value integerValue];
    }
    if (cpuName != nil && os != nil) {
        NSFetchRequest<System *> *request = [NSFetchRequest fetchRequestWithEntityName:@"System"];
        request.predicate = [NSPredicate predicateWithFormat:@"cpuName = %@ AND os = %@ AND cpuCoreCound = %d", cpuName, os, cpuCoreCount];
        System *sys = [[ctx executeFetchRequest:request error:error] firstObject];
        if (sys != nil)
            proj.system = sys;
        else {
            proj.system = [[System alloc] initWithContext:ctx];
            proj.system.id = [NSUUID UUID];
            proj.system.os = os;
            proj.system.cpuName = cpuName;
            proj.system.cpuCoreCount = cpuCoreCount;
        }
    }
    return error == nil;
}

- (instancetype)initWithDirectory:(NSString *)dir container:(NSPersistentContainer *)container {
    _dir = dir;
    _treeFile = [_dir stringByAppendingString:@"/tree.txt"];
    _projectFile = [_dir stringByAppendingString:@"/info.csv"];
    _container = container;
    _oid = nil;
    return self;
}

- (BOOL)loadProject:(NSError **)error {
    NSManagedObjectContext *ctx = _container.viewContext;
    Project *proj = [[Project alloc] initWithContext:ctx];
    proj.id = [NSUUID UUID];
    proj.timestamp = [NSDate now];
    if (![self loadInfoFile:error into:proj withContext:ctx])
        return NO;
    if (![ctx save:error])
        return NO;
    _oid = proj.objectID;
    return NO;
}

- (BOOL)importTreeInQueue:(NSOperationQueue *)queue withContainer:(NSPersistentContainer *)container error:(NSError **)error {
    BufferedTextFile *file = [[BufferedTextFile alloc] init:_treeFile bufferSize:8192 withError:error];
    NSString *line;
    if (file == nil)
        return NO;
    *error = nil;
    while ((line = [file readLine:error]) != nil) {
        TreeNode *node = [[TreeNode alloc] initFromString:line];
        NodeImportTask *task = [[NodeImportTask alloc] initWithTreeNode:node directory:_dir container:container projectId:_oid];
        [queue addOperation:task];
    }
    return error == nil;
}

@end
