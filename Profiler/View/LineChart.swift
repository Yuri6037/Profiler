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

import SwiftUI

struct LineChart: View {
    let width: CGFloat
    let height: CGFloat
    let points: [Double]

    var stepX: CGFloat {
        width / CGFloat(points.count - 1)
    }

    var stepY: CGFloat {
        let min = points.min()!
        let max = points.max()!
        return height / CGFloat(max - min)
    }

    var body: some View {
        Path { path in
            let offset = points.min()!
            let p1 = CGPoint(x: 0, y: CGFloat(points[0] - offset) * stepY)
            path.move(to: p1)
            for i in 1 ..< points.count {
                let p = CGPoint(x: stepX * CGFloat(i), y: stepY * CGFloat(points[i] - offset))
                path.addLine(to: p)
            }
        }
        .stroke(Color.accentColor, style: StrokeStyle(
            lineWidth: 3,
            lineJoin: .round
        ))
        .rotationEffect(.degrees(180), anchor: .center)
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        .drawingGroup()
        .frame(width: width, height: height)
    }
}

struct LineChart_Previews: PreviewProvider {
    static var previews: some View {
        LineChart(width: 300, height: 300, points: [1, 2, -2, 3, -6, 7])
    }
}
