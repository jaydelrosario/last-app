// LastApp/Features/Notes/Views/RichTextEditor.swift
import SwiftUI
import UIKit

/// UIViewRepresentable wrapping UITextView for rich text editing.
/// - `attributedText`: two-way binding to the NSAttributedString content
/// - `onTextChange`: called whenever text changes (for updating modifiedAt)
/// - `textViewRef`: exposes the underlying UITextView so the toolbar can call formatting helpers
struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var onTextChange: () -> Void = {}
    var textViewRef: ((UITextView) -> Void)? = nil

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.font = .systemFont(ofSize: 17)
        tv.textColor = .label
        tv.delegate = context.coordinator
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 4, bottom: 120, right: 4)
        tv.typingAttributes = [
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: UIColor.label
        ]
        textViewRef?(tv)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        // Only update if content actually changed to avoid cursor jumping
        if tv.attributedText != attributedText {
            let selected = tv.selectedRange
            tv.attributedText = attributedText
            tv.selectedRange = selected
        }
        textViewRef?(tv)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
            parent.onTextChange()
        }
    }
}

// MARK: - Formatting helpers (called by the toolbar)

extension UITextView {

    /// Toggle bold on the current selection (or typing attributes if no selection)
    func toggleBold() {
        applyFontTrait(.traitBold)
    }

    /// Toggle italic on the current selection
    func toggleItalic() {
        applyFontTrait(.traitItalic)
    }

    private func applyFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        if selectedRange.length == 0 {
            let current = typingAttributes[.font] as? UIFont ?? .systemFont(ofSize: 17)
            typingAttributes[.font] = current.hasTrait(trait)
                ? current.withoutTrait(trait)
                : current.withTrait(trait)
        } else {
            textStorage.beginEditing()
            textStorage.enumerateAttribute(.font, in: selectedRange) { value, range, _ in
                let font = (value as? UIFont) ?? .systemFont(ofSize: 17)
                let newFont = font.hasTrait(trait) ? font.withoutTrait(trait) : font.withTrait(trait)
                textStorage.addAttribute(.font, value: newFont, range: range)
            }
            textStorage.endEditing()
        }
    }

    /// Toggle heading style (larger bold font) on the entire current line
    func toggleHeading() {
        let lineRange = (text as NSString).lineRange(for: selectedRange)
        let headingFont = UIFont.systemFont(ofSize: 22, weight: .bold)
        let bodyFont = UIFont.systemFont(ofSize: 17)
        textStorage.beginEditing()
        let currentFont = textStorage.attribute(.font, at: lineRange.location, effectiveRange: nil) as? UIFont
        let isHeading = currentFont.map { $0.pointSize >= 20 } ?? false
        textStorage.addAttribute(.font, value: isHeading ? bodyFont : headingFont, range: lineRange)
        textStorage.endEditing()
    }

    /// Toggle yellow highlight on the current selection
    func toggleHighlight() {
        if selectedRange.length == 0 { return }
        textStorage.beginEditing()
        let current = textStorage.attribute(.backgroundColor, at: selectedRange.location, effectiveRange: nil)
        if current != nil {
            textStorage.removeAttribute(.backgroundColor, range: selectedRange)
        } else {
            textStorage.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.4), range: selectedRange)
        }
        textStorage.endEditing()
    }

    /// Toggle strikethrough on the current selection
    func toggleStrikethrough() {
        if selectedRange.length == 0 { return }
        textStorage.beginEditing()
        let existing = textStorage.attribute(.strikethroughStyle, at: selectedRange.location, effectiveRange: nil) as? Int
        if existing != nil {
            textStorage.removeAttribute(.strikethroughStyle, range: selectedRange)
        } else {
            textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
        }
        textStorage.endEditing()
    }

    /// Toggle inline code style on the current selection
    func toggleCode() {
        if selectedRange.length == 0 { return }
        textStorage.beginEditing()
        let existing = textStorage.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont
        let isCode = existing?.fontDescriptor.symbolicTraits.contains(.traitMonoSpace) ?? false
        let newFont: UIFont = isCode
            ? .systemFont(ofSize: 17)
            : .monospacedSystemFont(ofSize: 15, weight: .regular)
        let bgColor: UIColor? = isCode ? nil : UIColor.systemGray5
        textStorage.addAttribute(.font, value: newFont, range: selectedRange)
        if let bg = bgColor {
            textStorage.addAttribute(.backgroundColor, value: bg, range: selectedRange)
        } else {
            textStorage.removeAttribute(.backgroundColor, range: selectedRange)
        }
        textStorage.endEditing()
    }

    /// Insert "• " at the start of the current line
    func insertBullet() {
        insertLinePrefix("• ")
    }

    /// Insert a numbered prefix at the start of the current line
    func insertNumberedItem() {
        let lineRange = (text as NSString).lineRange(for: selectedRange)
        let linesBefore = (text as NSString).substring(to: lineRange.location)
        let count = linesBefore.components(separatedBy: "\n").filter { $0.first?.isNumber == true }.count + 1
        insertLinePrefix("\(count). ")
    }

    /// Insert "☐ " at the start of the current line
    func insertCheckbox() {
        insertLinePrefix("☐ ")
    }

    private func insertLinePrefix(_ prefix: String) {
        let lineRange = (text as NSString).lineRange(for: selectedRange)
        let lineStart = NSRange(location: lineRange.location, length: 0)
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: lineStart, with: prefix)
        textStorage.endEditing()
        selectedRange = NSRange(location: selectedRange.location + prefix.count, length: selectedRange.length)
    }

    /// Insert a horizontal divider at the current position
    func insertDivider() {
        let divider = "\n────────────────────\n"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.separator
        ]
        let attrDivider = NSAttributedString(string: divider, attributes: attrs)
        textStorage.beginEditing()
        textStorage.insert(attrDivider, at: selectedRange.location)
        textStorage.endEditing()
        selectedRange = NSRange(location: selectedRange.location + divider.count, length: 0)
    }

    /// Apply a link on the current selection
    func applyLink(_ urlString: String) {
        guard selectedRange.length > 0, let url = URL(string: urlString) else { return }
        textStorage.beginEditing()
        textStorage.addAttribute(.link, value: url, range: selectedRange)
        textStorage.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: selectedRange)
        textStorage.endEditing()
    }

    /// Remove link from the current selection
    func removeLink() {
        if selectedRange.length == 0 { return }
        textStorage.beginEditing()
        textStorage.removeAttribute(.link, range: selectedRange)
        textStorage.removeAttribute(.foregroundColor, range: selectedRange)
        textStorage.endEditing()
    }

    /// True when the cursor is positioned inside a linked range
    var cursorIsInLink: Bool {
        guard selectedRange.location < textStorage.length else { return false }
        return textStorage.attribute(.link, at: selectedRange.location, effectiveRange: nil) != nil
    }
}

// MARK: - UIFont helpers

extension UIFont {
    func hasTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> Bool {
        fontDescriptor.symbolicTraits.contains(trait)
    }

    func withTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let desc = fontDescriptor.withSymbolicTraits(fontDescriptor.symbolicTraits.union(trait)) else { return self }
        return UIFont(descriptor: desc, size: pointSize)
    }

    func withoutTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let desc = fontDescriptor.withSymbolicTraits(fontDescriptor.symbolicTraits.subtracting(trait)) else { return self }
        return UIFont(descriptor: desc, size: pointSize)
    }
}
