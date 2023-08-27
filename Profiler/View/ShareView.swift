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
import SwiftUI

#if os(iOS)

struct ShareView: UIViewControllerRepresentable {
    let url: NSURL;
    @Binding var isPresented: Bool;

    typealias UIViewControllerType = UIActivityViewController;

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil);
        controller.completionWithItemsHandler = { (_, _, _, _) in
            self.isPresented = false;
        };
        return controller;
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

#elseif os(macOS)

struct SharePicker: NSViewRepresentable {
    let url: NSURL;
    @Binding var isPresented: Bool;

    typealias NSViewType = NSView;

    func makeNSView(context: Context) -> NSView {
        return NSView();
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if isPresented {
            let picker = NSSharingServicePicker(items: [url]);
            picker.delegate = context.coordinator;
            DispatchQueue.main.async {
                picker.show(relativeTo: .zero, of: nsView, preferredEdge: .minY);
            }
        }
    }

    class Coordinator: NSObject, NSSharingServicePickerDelegate {
        private let owner: SharePicker;

        init(owner: SharePicker) {
            self.owner = owner;
        }

        func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
            sharingServicePicker.delegate = nil;
            self.owner.isPresented = false;
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(owner: self);
    }
}

#endif

struct Share: ViewModifier {
    let url: NSURL;
    @Binding var isPresented: Bool;

    func body(content: Content) -> some View {
#if os(iOS)
        return content.sheet(isPresented: $isPresented) {
            ShareView(url: url, isPresented: $isPresented)
        }
#elseif os(macOS)
        return content.background(SharePicker(url: url, isPresented: $isPresented))
#endif
    }
}

extension View {
    public func share(isPresented: Binding<Bool>, url: URL) -> some View {
        return modifier(Share(url: url as NSURL, isPresented: isPresented))
    }
}

struct ShareView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Button("Test") {
                
            }
        }.share(isPresented: .constant(true), url: URL(string: "https://yuristudio.net")!)
    }
}
