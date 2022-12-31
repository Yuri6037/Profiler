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

#import "ProjectImporter.h"
#import "ImporterManager.h"
#include <deque>

struct Item {
    NSString *path;
    BOOL deleteDirectory;
};

@interface ImporterManager()

- (void)timerFireMethod:(NSTimer *)timer;

- (BOOL)initCurrent:(NSError **)error;

- (void)deleteDirectory;

@end

@implementation ImporterManager {
    std::deque<Item> _items;
    ProjectImporter *_current;
    NSString *_currentPath;
    NSPersistentContainer *_container;
    BOOL _currentDeleteFlag;
    NSUInteger _nodesCurrent;
    NSUInteger _nodesTotal;
    void (^_block)(NSUInteger current, NSUInteger total);
    void (^_errorBlock)(NSError *error);
}

- (instancetype)initWithContainer:(NSPersistentContainer *)container {
    _current = nil;
    _block = nil;
    _errorBlock = nil;
    _currentDeleteFlag = false;
    _container = container;
    _currentPath = nil;
    return self;
}

- (void)importDirectory:(NSString *)dir deleteAfterImport:(BOOL)flag {
    _items.push_back(Item { dir, flag });
}

- (BOOL)initCurrent:(NSError **)error {
    if (![_current loadProject:error])
        return NO;
    if (![_current importTree:error])
        return NO;
    return YES;
}

- (void)deleteDirectory {
    if (_currentPath != nil) {
        NSFileManager *manager = [NSFileManager defaultManager];
        NSError *error;
        if (![manager removeItemAtPath:_currentPath error:&error])
            NSLog(@"Failed to delete dataset directory %@: %@", _currentPath, error);
        _currentPath = nil;
    }
}

- (void)timerFireMethod:(NSTimer *)timer {
    if (_current == nil && !_items.empty()) {
        _currentDeleteFlag = _items.front().deleteDirectory;
        _current = [[ProjectImporter alloc] initWithDirectory:_items.front().path container:_container];
        _currentPath = _items.front().path;
        _nodesCurrent = 0;
        _nodesTotal = 0;
        NSError *error;
        if (![self initCurrent:&error]) {
            if (_currentDeleteFlag)
                [self deleteDirectory];
            if (_errorBlock != nil)
                (_errorBlock)(error);
            _current = nil;
            _currentDeleteFlag = false;
        }
        _nodesTotal = _current.totalNodes;
        _items.pop_front();
    } else if (_current != nil) {
        NSUInteger current = [_current importedNodes];
        NSUInteger total = _current.totalNodes;
        if (total != _nodesTotal || current != _nodesCurrent) {
            if (_block)
                (_block)(current, total);
            if (current >= total) {
                [_current wait];
                _current = nil;
                if (_currentDeleteFlag)
                    [self deleteDirectory];
            }
        }
    }
}

- (void)setEventBlock:(void (^)(NSUInteger current, NSUInteger total))block {
    _block = block;
    if (_current != nil && _block != nil)
        (_block)([_current importedNodes], _current.totalNodes);
}

- (void)setErrorBlock:(void (^)(NSError *error))errorBlock {
    _errorBlock = errorBlock;
}

- (void)clearEventBlock {
    _block = nil;
}

- (void)start {
    SEL sel = @selector(timerFireMethod:);
    NSTimer *timer = [NSTimer timerWithTimeInterval:0 target:self selector:sel userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

@end
