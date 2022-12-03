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

import Foundation
import CoreData

func sampleCpu(context: NSManagedObjectContext) -> Cpu {
    let cpu = Cpu.new(context: context);
    cpu.coreCount = 10;
    cpu.name = "Apple M1 Max";
    return cpu;
}

func sampleTarget(context: NSManagedObjectContext) -> Target {
    let target = Target.new(context: context);
    target.os = "macOS";
    target.family = "unix";
    target.arch = "aarch64";
    return target;
}

func sampleMetadata(context: NSManagedObjectContext) -> SpanMetadata {
    let metadata = SpanMetadata.new(context: context);
    metadata.name = "test";
    metadata.target = "test target";
    metadata.level = 0;
    return metadata;
}

func sampleProject(context: NSManagedObjectContext) {
    let project = Project.new(context: context);
    project.name = "Test";
    project.timestamp = Date();
    project.cpu = sampleCpu(context: context);
    project.target = sampleTarget(context: context);
    let node = SpanNode(context: context);
    node.project = project;
    node.path = "root";
    node.metadata = sampleMetadata(context: context);
}
