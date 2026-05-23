import AppKit
import SwiftTerm

class DragDropTerminalView: LocalProcessTerminalView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDragDrop()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDragDrop()
    }

    private func setupDragDrop() {
        registerForDraggedTypes([.fileURL])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if hasFileURL(sender) {
            return .copy
        }
        return []
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingContentsConformToTypes: ["public.item"]
        ]) as? [URL], !urls.isEmpty else {
            return false
        }

        let pathStrings = urls.map { "@\($0.path)" }
        let combined = pathStrings.joined(separator: " ")

        if let data = combined.data(using: .utf8) {
            let slice = ArraySlice(data)
            process.send(data: slice)
        }

        return true
    }

    private func hasFileURL(_ sender: NSDraggingInfo) -> Bool {
        return sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: [
            .urlReadingContentsConformToTypes: ["public.item"]
        ])
    }
}
