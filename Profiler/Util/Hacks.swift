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
import CoreData

// More hacks because Swift is too badly broken to include proper subtraction operators in Date...
extension Date {
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }

    func toISO8601() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return dateFormatter.string(from: self)
    }

    init?(fromISO8601: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        guard let date = dateFormatter.date(from: fromISO8601) else { return nil }
        self = date
    }

    func toTimestamp() -> UInt64 {
        return UInt64(self.timeIntervalSince1970 * 1000000)
    }

    init(fromTimestamp: UInt64) {
        self = Self(timeIntervalSince1970: Double(fromTimestamp) / 1000000.0)
    }
}

#if os(iOS)

//This hack is required because reflection is half broken under iOS
extension NSEntityDescription {
    var attributeKeys: [String] {
        self.attributesByName.map { v in v.key }
    }

    var toOneRelationshipKeys: [String] {
        self.relationshipsByName.filter { v in !v.value.isToMany }.map { v in v.key }
    }

    var toManyRelationshipKeys: [String] {
        self.relationshipsByName.filter { v in v.value.isToMany }.map { v in v.key }
    }
}

#endif
