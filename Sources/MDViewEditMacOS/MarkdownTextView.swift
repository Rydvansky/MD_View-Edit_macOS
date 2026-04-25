import AppKit
import SwiftUI

struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    let fontSize: CGFloat
    let scrollTarget: MarkdownScrollTarget?
    let onLineSelected: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onLineSelected: onLineSelected)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFindPanel = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.textColor = .textColor
        textView.insertionPointColor = .textColor
        textView.textContainerInset = NSSize(width: 14, height: 14)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.string = text

        scrollView.documentView = textView
        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        textView.backgroundColor = .textBackgroundColor
        textView.textColor = .textColor
        textView.insertionPointColor = .textColor
        textView.needsDisplay = true
        scrollView.needsDisplay = true

        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        if textView.font != font {
            textView.font = font
        }

        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }

        if let scrollTarget, scrollTarget.source != .editor, context.coordinator.lastScrollTarget != scrollTarget {
            context.coordinator.lastScrollTarget = scrollTarget
            context.coordinator.scroll(toLine: scrollTarget.line, in: scrollView)
        }

        context.coordinator.onLineSelected = onLineSelected
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        var onLineSelected: (Int) -> Void
        weak var textView: NSTextView?
        var lastScrollTarget: MarkdownScrollTarget?
        private var lastSelectedLine: Int?

        init(text: Binding<String>, onLineSelected: @escaping (Int) -> Void) {
            _text = text
            self.onLineSelected = onLineSelected
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
            publishSelectedLine(from: textView)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            publishSelectedLine(from: textView)
        }

        func scroll(toLine targetLine: Int, in scrollView: NSScrollView) {
            guard let textView else { return }

            let characterOffset = characterOffset(forLine: targetLine, in: textView.string)
            let range = NSRange(location: min(characterOffset, (textView.string as NSString).length), length: 0)

            guard
                let layoutManager = textView.layoutManager,
                let textContainer = textView.textContainer
            else {
                textView.scrollRangeToVisible(range)
                return
            }

            layoutManager.ensureLayout(for: textContainer)
            let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            rect.origin.x += textView.textContainerOrigin.x
            rect.origin.y += textView.textContainerOrigin.y

            let y = max(0, rect.minY - 200)
            scrollView.contentView.scroll(to: NSPoint(x: 0, y: y))
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }

        private func characterOffset(forLine targetLine: Int, in source: String) -> Int {
            let nsString = source as NSString
            var currentLine = 0
            var location = 0

            while currentLine < targetLine && location < nsString.length {
                let lineRange = nsString.lineRange(for: NSRange(location: location, length: 0))
                location = NSMaxRange(lineRange)
                currentLine += 1
            }

            return min(location, nsString.length)
        }

        private func publishSelectedLine(from textView: NSTextView) {
            let selectedLocation = textView.selectedRange().location
            let line = lineNumber(at: selectedLocation, in: textView.string)
            guard line != lastSelectedLine else { return }

            lastSelectedLine = line
            onLineSelected(line)
        }

        private func lineNumber(at location: Int, in source: String) -> Int {
            let nsString = source as NSString
            let cappedLocation = min(location, nsString.length)
            var line = 0
            var cursor = 0

            while cursor < cappedLocation {
                let lineRange = nsString.lineRange(for: NSRange(location: cursor, length: 0))
                let next = NSMaxRange(lineRange)
                guard next <= cappedLocation, next > cursor else { break }
                cursor = next
                line += 1
            }

            return line
        }
    }
}
