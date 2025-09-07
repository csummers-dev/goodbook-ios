import SwiftUI
import UIKit

/// A UIKit-backed selectable text view that renders an entire chapter as a single attributed string.
/// - Why: SwiftUI's `Text` does not provide native word-level text selection with handles across views.
/// - How: Uses `UITextView` with selection enabled and a precomputed mapping from `NSRange` to
///   `(verse, wordIndex)` positions so we can convert user selections into a `WordSpan`.
struct SelectableChapterTextView: UIViewRepresentable {
    /// Input: Book and chapter context for mapping selections.
    let bookId: String
    let chapter: BibleChapter
    /// Theme-aware font size from settings.
    let fontSize: CGFloat
    /// Existing highlights to render into the attributed text (word or verse level).
    let highlights: [Highlight]
    /// Callback invoked when the user selection changes.
    let onSelectionChange: (WordSpan?) -> Void

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.delegate = context.coordinator
        tv.allowsEditingTextAttributes = false
        tv.linkTextAttributes = [:]
        tv.dataDetectorTypes = []
        tv.isScrollEnabled = false
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let build = AttributedChapterBuilder(bookId: bookId, chapter: chapter, fontSize: fontSize, highlights: highlights)
        let result = build.build()
        context.coordinator.mapping = result.mapping
        uiView.attributedText = result.attributed
        uiView.isUserInteractionEnabled = true
        uiView.isSelectable = true
    }

    func makeCoordinator() -> Coordinator { Coordinator(bookId: bookId, chapter: chapter, onSelectionChange: onSelectionChange) }

    // MARK: - Coordinator
    final class Coordinator: NSObject, UITextViewDelegate {
        private let bookId: String
        private let chapter: BibleChapter
        private let onSelectionChange: (WordSpan?) -> Void
        /// Mapping from word boundaries to `NSRange` segments.
        var mapping: [NSRange: VerseWordPosition] = [:]

        init(bookId: String, chapter: BibleChapter, onSelectionChange: @escaping (WordSpan?) -> Void) {
            self.bookId = bookId
            self.chapter = chapter
            self.onSelectionChange = onSelectionChange
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            let selRange = textView.selectedRange
            guard selRange.length > 0 else { onSelectionChange(nil); return }

            // Find nearest word boundaries for selection start and end.
            guard let start = nearestWordPosition(for: selRange.location),
                  let end = nearestWordPosition(for: selRange.location + selRange.length - 1) else {
                onSelectionChange(nil); return
            }
            let span = WordSpan(bookId: bookId, chapter: chapter.number, start: start, end: end)
            onSelectionChange(span)
        }

        private func nearestWordPosition(for location: Int) -> VerseWordPosition? {
            // Linear scan is acceptable for small chapters. Optimize with an interval tree if needed.
            var best: (distance: Int, pos: VerseWordPosition)?
            for (range, pos) in mapping {
                let distance: Int
                if location < range.location { distance = range.location - location }
                else if location > range.location + range.length { distance = location - (range.location + range.length) }
                else { distance = 0 }
                if best == nil || distance < best!.distance { best = (distance, pos) }
            }
            return best?.pos
        }
    }
}

// MARK: - Attributed text builder

/// Builds an attributed string for a chapter and a mapping from word `NSRange`s to `VerseWordPosition`s.
/// This design centralizes tokenization and styling logic and makes it easy to test.
struct AttributedChapterBuilder {
    let bookId: String
    let chapter: BibleChapter
    let fontSize: CGFloat
    let highlights: [Highlight]

    struct Result { let attributed: NSAttributedString; let mapping: [NSRange: VerseWordPosition] }

    func build() -> Result {
        let mutable = NSMutableAttributedString()
        var mapping: [NSRange: VerseWordPosition] = [:]

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4

        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraph
        ]

        for verse in chapter.verses {
            // Verse number prefix (non-selectable intent, but part of text for simplicity)
            let numberAttr = NSAttributedString(string: "\(verse.number) ", attributes: baseAttrs)
            mutable.append(numberAttr)

            // Tokenize words for mapping; simple split by whitespace. Extend with punctuation handling if needed.
            let words = verse.text.split(separator: " ")
            var cursor = mutable.length
            for (index, word) in words.enumerated() {
                let token = String(word)
                let attr = NSAttributedString(string: token, attributes: baseAttrs)
                let range = NSRange(location: cursor, length: attr.length)
                mapping[range] = VerseWordPosition(verse: verse.number, wordIndex: index)
                mutable.append(attr)
                cursor += attr.length
                if index < words.count - 1 {
                    let space = NSAttributedString(string: " ", attributes: baseAttrs)
                    mutable.append(space)
                    cursor += 1
                }
            }

            // Newline after each verse
            mutable.append(NSAttributedString(string: "\n", attributes: baseAttrs))
        }

        // Apply highlight background attributes using `highlights` and mapping.
        // Iterate all mapping entries and tint those that fall within any highlight.
        for (range, pos) in mapping {
            guard let color = backgroundColorForWord(at: pos) else { continue }
            mutable.addAttribute(.backgroundColor, value: color, range: range)
        }

        return Result(attributed: mutable, mapping: mapping)
    }

    /// Returns a background UIColor for a given word position if any highlight covers it.
    private func backgroundColorForWord(at position: VerseWordPosition) -> UIColor? {
        for h in highlights {
            guard h.range.bookId == bookId, h.range.chapter == chapter.number else { continue }
            guard h.range.startVerse <= position.verse && position.verse <= h.range.endVerse else { continue }
            if let span = h.wordSpan {
                // Restrict to word boundaries if wordSpan is present.
                let s = span.normalized.start
                let e = span.normalized.end
                let isAfterStart = (position.verse > s.verse) || (position.verse == s.verse && position.wordIndex >= s.wordIndex)
                let isBeforeEnd = (position.verse < e.verse) || (position.verse == e.verse && position.wordIndex <= e.wordIndex)
                if isAfterStart && isBeforeEnd { return uiColor(for: h.color) }
            } else {
                // Verse-level: entire verse is tinted.
                return uiColor(for: h.color)
            }
        }
        return nil
    }

    private func uiColor(for color: HighlightColor) -> UIColor {
        switch color {
        case .yellow: return UIColor.yellow.withAlphaComponent(0.35)
        case .green: return UIColor.green.withAlphaComponent(0.35)
        case .blue: return UIColor.blue.withAlphaComponent(0.35)
        case .pink: return UIColor.systemPink.withAlphaComponent(0.35)
        case .orange: return UIColor.orange.withAlphaComponent(0.35)
        }
    }
}


