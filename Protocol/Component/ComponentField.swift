// Copyright 2024 Yuri6037
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
import NIO

public enum FieldType: Component {
    case i8
    case i16
    case i32
    case i64
    case u8
    case u16
    case u32
    case u64
    case f64
    case str
    case bool

    public init(fromRaw: UInt8) {
        switch fromRaw {
        case 1:
            self = .i8
        case 2:
            self = .i16
        case 3:
            self = .i32
        case 4:
            self = .i64
        case 5:
            self = .u8
        case 6:
            self = .u16
        case 7:
            self = .u32
        case 8:
            self = .u64
        case 9:
            self = .f64
        case 10:
            self = .str
        default:
            self = .bool
        }
    }

    public static func read(buffer: inout ByteBuffer) -> FieldType {
        return .init(fromRaw: .read(buffer: &buffer))
    }
}

public struct FieldValue: Component {
    public enum Value {
        case signed(Int)
        case unsigned(UInt)
        case float(Double)
        case string(String)
        case bool(Bool)
    }

    public let type: FieldType
    public let value: Value

    public static func read(buffer: inout ByteBuffer) throws -> FieldValue {
        let type = FieldType.read(buffer: &buffer);
        let value: Value;
        switch (type) {
        case .i8:
            value = .signed(Int(Int8.read(buffer: &buffer)))
        case .i16:
            value = .signed(Int(Int16.read(buffer: &buffer)))
        case .i32:
            value = .signed(Int(Int32.read(buffer: &buffer)))
        case .i64:
            value = .signed(Int(Int64.read(buffer: &buffer)))
        case .u8:
            value = .unsigned(UInt(UInt8.read(buffer: &buffer)))
        case .u16:
            value = .unsigned(UInt(UInt16.read(buffer: &buffer)))
        case .u32:
            value = .unsigned(UInt(UInt32.read(buffer: &buffer)))
        case .u64:
            value = .unsigned(UInt(UInt64.read(buffer: &buffer)))
        case .f64:
            value = .float(Float64.read(buffer: &buffer))
        case .str:
            value = .string(try .read(buffer: &buffer))
        case .bool:
            value = .bool(.read(buffer: &buffer))
        }
        return .init(type: type, value: value)
    }
}

public struct Field: Component {
    public let name: String
    public let value: FieldValue

    public static func read(buffer: inout ByteBuffer) throws -> Field {
        Field(
            name: try .read(buffer: &buffer),
            value: try .read(buffer: &buffer)
        )
    }
}
