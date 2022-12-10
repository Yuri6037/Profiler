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
#import "Cpu+CoreDataClass.h"
#import "Target+CoreDataClass.h"

@interface ProjectImporter()

- (BOOL)loadInfoFile:(NSError **)error into:(Project *)proj withContext:(NSManagedObjectContext *)ctx;

@end

@implementation ProjectImporter {
    NSString *_dir;
    NSString *_treeFile;
    NSString *_projectFile;
    NSPersistentContainer *_container;
    NSManagedObjectID *_oid;
    NSOperationQueue *_queue;
}

- (BOOL)loadInfoFile:(NSError **)error into:(Project *)proj withContext:(NSManagedObjectContext *)ctx {
    BufferedTextFile *file = [[BufferedTextFile alloc] init:_projectFile bufferSize:8192 withError:error];
    CSVParser *parser = [[CSVParser alloc] init:','];
    NSString *targetOs = nil;
    NSString *targetFamily = nil;
    NSString *targetArch = nil;
    NSString *cpuName = nil;
    int32_t cpuCoreCount = 0;
    NSString *line;
    if (file == nil)
        return NO;
    *error = nil;
    while ((line = [file readLine:error]) != nil) {
        CSVRow row = [parser parseRow:line];
        if (row.count < 2)
            continue;
        NSString *key = [row objectAtIndex:0];
        NSString *value = [row objectAtIndex:1];
        if ([key isEqualToString:@"Name"])
            proj.name = value;
        else if ([key isEqualToString:@"AppName"])
            proj.appName = value;
        else if ([key isEqualToString:@"CommandLine"])
            proj.commandLine = value;
        else if ([key isEqualToString:@"Version"])
            proj.version = value;
        else if ([key isEqualToString:@"TargetOs"] && value.length > 0)
            targetOs = value;
        else if ([key isEqualToString:@"TargetFamily"] && value.length > 0)
            targetFamily = value;
        else if ([key isEqualToString:@"TargetArch"] && value.length > 0)
            targetArch = value;
        else if ([key isEqualToString:@"CpuName"] && value.length > 0)
            cpuName = value;
        else if ([key isEqualToString:@"CpuCoreCount"])
            cpuCoreCount = (int32_t)[value integerValue];
    }
    if (targetOs != nil && targetFamily != nil && targetArch != nil) {
        NSFetchRequest<Target *> *request = [NSFetchRequest fetchRequestWithEntityName:@"Target"];
        request.predicate = [NSPredicate predicateWithFormat:@"os = %@ AND family = %@ AND arch = %@", targetOs, targetFamily, targetArch];
        Target *target = [[ctx executeFetchRequest:request error:error] firstObject];
        if (target != nil)
            proj.target = target;
        else {
            proj.target = [[Target alloc] initWithContext:ctx];
            proj.target.os = targetOs;
            proj.target.family = targetFamily;
            proj.target.arch = targetArch;
        }
    }
    if (cpuName != nil && cpuCoreCount > 0) {
        NSFetchRequest<Cpu *> *request = [NSFetchRequest fetchRequestWithEntityName:@"Cpu"];
        request.predicate = [NSPredicate predicateWithFormat:@"name = %@ AND coreCount = %d", cpuName, cpuCoreCount];
        Cpu *cpu = [[ctx executeFetchRequest:request error:error] firstObject];
        if (cpu != nil)
            proj.cpu = cpu;
        else {
            proj.cpu = [[Cpu alloc] initWithContext:ctx];
            proj.cpu.name = cpuName;
            proj.cpu.coreCount = cpuCoreCount;
        }
    }
    return *error == nil;
}

- (instancetype)initWithDirectory:(NSString *)dir container:(NSPersistentContainer *)container {
    _dir = dir;
    _treeFile = [_dir stringByAppendingString:@"/tree.txt"];
    _projectFile = [_dir stringByAppendingString:@"/info.csv"];
    _container = container;
    _oid = nil;
    _queue = [[NSOperationQueue alloc] init];
    _queue.name = dir;
    return self;
}

- (BOOL)loadProject:(NSError **)error {
    NSManagedObjectContext *ctx = _container.viewContext;
    Project *proj = [[Project alloc] initWithContext:ctx];
    proj.timestamp = [NSDate now];
    if (![self loadInfoFile:error into:proj withContext:ctx])
        return NO;
    if (![ctx save:error])
        return NO;
    _oid = proj.objectID;
    return YES;
}

- (BOOL)importTree:(NSError **)error {
    BufferedTextFile *file = [[BufferedTextFile alloc] init:_treeFile bufferSize:8192 withError:error];
    NSString *line;
    if (file == nil)
        return NO;
    *error = nil;
    while ((line = [file readLine:error]) != nil) {
        TreeNode *node = [[TreeNode alloc] initFromString:line];
        NodeImportTask *task = [[NodeImportTask alloc] initWithTreeNode:node directory:_dir container:_container projectId:_oid];
        [_queue addOperation:task];
    }
    return *error == nil;
}

@end
