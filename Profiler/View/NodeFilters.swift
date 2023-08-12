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

class NodeFilters: ObservableObject {
    enum Order {
        case insertion;
        case minimum;
        case maximum;
    }

    enum Distribution {
        case even;
        case nFirst;
        case nLast;
    }

    @Published var order: Order = .insertion;
    @Published var distribution: Distribution = .even;
    @Published var text: String = "";
    //TODO: fixme
    //private var _textFilter = NodeTextFilter();
    private var _lastUpdate: Date = Date();

    func updateTextFilter(_ newText: String, action: @escaping () -> Void) {
        //TODO: fixme
        //_textFilter.text = newText;
        _lastUpdate = Date();
        DispatchQueue.main.schedule(after: .init(.now().advanced(by: .seconds(2)))) {
            if Date() - self._lastUpdate >= 1 {
                action();
            }
        };
    }

    func getSortDescriptors() -> [NSSortDescriptor] {
        switch order {
        case .insertion:
            if distribution == .nLast {
                return [ NSSortDescriptor(keyPath: \SpanRun.order, ascending: false) ];
            } else {
                return [ NSSortDescriptor(keyPath: \SpanRun.order, ascending: true) ];
            }
        case .minimum:
            if distribution == .nLast {
                return [
                    NSSortDescriptor(keyPath: \SpanRun.time, ascending: false),
                ];
            } else {
                return [
                    NSSortDescriptor(keyPath: \SpanRun.time, ascending: true),
                ];
            }
        case .maximum:
            if distribution == .nLast {
                return [
                    NSSortDescriptor(keyPath: \SpanRun.time, ascending: true),
                ];
            } else {
                return [
                    NSSortDescriptor(keyPath: \SpanRun.time, ascending: false),
                ];
            }
        }
    }

    func getPredicate(size: Int, maxSize: Int, node: NSManagedObject) -> NSPredicate {
        var predicates = [NSPredicate(format: "node=%@", node)];
        //TODO: fixme
        //predicates.append(contentsOf: _textFilter.getPredicates() ?? []);
        if distribution == .even && size > maxSize {
            //Compute how many times to halve the rows in order to be under 20K
            var halves = 2;
            while size / halves > maxSize {
                halves += 1;
            }
            predicates.append(NSPredicate(format: "modulus:by:(order, %d) == 0", halves));
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates);
    }
}
