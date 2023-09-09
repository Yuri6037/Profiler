// Copyright 2023 Yuri6037
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

struct FileUtils {
    static func getDataDirectory() throws -> URL {
        let path = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(Bundle.main.bundleIdentifier!)
        try path.createDirsIfNotExists();
        return path
    }

    static func getAppSupportDirectory() throws -> URL {
        let path = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        try path.createDirsIfNotExists();
        return path
    }

    static func getDocumentsDirectory() throws -> URL {
        let path = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        try path.createDirsIfNotExists();
        return path
    }

    static func copy(from: URL, to: URL) throws {
        if FileManager.default.fileExists(atPath: to.path) {
            try FileManager.default.removeItem(at: to)
        }
        try FileManager.default.copyItem(at: from, to: to)
    }

    static func delete(url: URL) throws {
        try FileManager.default.removeItem(at: url);
    }
}

extension URL {
    func createDirsIfNotExists() throws {
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir) {
            try FileManager.default.createDirectory(at: self, withIntermediateDirectories: true, attributes: nil)
        }
    }
}
