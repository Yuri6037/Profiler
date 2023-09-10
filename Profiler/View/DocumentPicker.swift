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
import UniformTypeIdentifiers

#if os(iOS)

import MobileCoreServices

struct DocumentPicker: UIViewControllerRepresentable {
    private let callback: (URL) -> ()
    private let export: URL?;
    private let type: UTType;
    @Binding private var isPresented: Bool;

    init(callback: @escaping (URL) -> (), isPresented: Binding<Bool>, type: UTType, export: URL? = nil) {
        self.callback = callback
        self.export = export;
        _isPresented = isPresented;
        self.type = type;
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentPicker>) {
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = export != nil ? UIDocumentPickerViewController(forExporting: [export!]) : UIDocumentPickerViewController(forOpeningContentTypes: [type])
        controller.allowsMultipleSelection = false
        controller.shouldShowFileExtensions = true
        controller.delegate = context.coordinator
        return controller
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        init(_ pickerController: DocumentPicker) {
            self.parent = pickerController
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.callback(urls[0])
            parent.isPresented = false
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.isPresented = false
        }
    }
}

#else

import AppKit

struct DocumentPicker: NSViewRepresentable {
    private let callback: (URL) -> ()
    private let export: URL?;
    private let type: UTType;
    @Binding private var isPresented: Bool;

    typealias NSViewType = NSView

    init(callback: @escaping (URL) -> (), isPresented: Binding<Bool>, type: UTType, export: URL? = nil) {
        self.callback = callback
        self.export = export;
        _isPresented = isPresented;
        self.type = type;
    }

    func makeNSView(context _: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if isPresented {
            if let export = export {
                let panel = NSSavePanel()
                panel.allowedContentTypes = [type]
                panel.beginSheetModal(for: nsView.window!) { res in
                    if res == .OK {
                        if let url = panel.url {
                            callback(url)
                        }
                    }
                    isPresented = false;
                }
            } else {
                let panel = NSOpenPanel();
                panel.canChooseFiles = true;
                panel.canChooseDirectories = false;
                panel.allowsMultipleSelection = false;
                panel.allowedContentTypes = [type];
                panel.beginSheetModal(for: nsView.window!) { res in
                    if res == .OK {
                        if let url = panel.url {
                            callback(url)
                        }
                    }
                    isPresented = false;
                }
            }
        }
    }
}

#endif

struct Document: ViewModifier {
    private let callback: (URL) -> ()
    private let export: URL?;
    private let type: UTType;
    @Binding private var isPresented: Bool;

    init(isPresented: Binding<Bool>, type: UTType, export: URL? = nil, callback: @escaping (URL) -> ()) {
        self.callback = callback
        self.export = export;
        _isPresented = isPresented;
        self.type = type;
    }

    func body(content: Content) -> some View {
        #if os(iOS)
            return content.sheet(isPresented: $isPresented) {
                DocumentPicker(callback: callback, isPresented: $isPresented, type: type)
            }
        #elseif os(macOS)
            return content.background(DocumentPicker(callback: callback, isPresented: $isPresented, type: type))
        #endif
    }
}

public extension View {
    func document(isPresented: Binding<Bool>, type: UTType, export: URL? = nil, callback: @escaping (URL) -> ()) -> some View {
        modifier(Document(isPresented: isPresented, type: type, callback: callback))
    }
}
