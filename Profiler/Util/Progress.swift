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

class Progress: ObservableObject, Identifiable {
    let id = UUID();
    let text: String;
    let total: UInt;
    @Published var current: UInt = 0;
    var value: CGFloat { total == 0 && current == 0 ? 0 : CGFloat(current) / CGFloat(total) }
    var isValid = true;

    init(text: String, total: UInt) {
        self.text = text;
        self.total = total;
    }

    func advance(count: UInt = 1) {
        if !isValid {
            return;
        }
        DispatchQueue.main.async {
            self.current += count;
        }
    }
}

class ProgressList: ObservableObject {
    @Published var array: [Progress] = [];

    func begin(text: String, total: UInt) -> Progress {
        let prog = Progress(text: text, total: total);
        DispatchQueue.main.async {
            self.array.append(prog);
        }
        return prog;
    }

    func end(_ prog: Progress) {
        prog.isValid = false;
        DispatchQueue.main.async {
            self.array.removeAll(where: { v in v === prog });
        }
    }
}
