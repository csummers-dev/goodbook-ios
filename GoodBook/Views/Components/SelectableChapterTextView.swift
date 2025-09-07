import SwiftUI
import UIKit

/// A UIKit-backed selectable text view that renders a whole chapter as one attributed string.
/// - Why: SwiftUI `Text` does not support native selection handles; `UITextView` does.
/// - How: We build one attributed string per chapter, keep a map of word ranges to
///   `VerseWordPosition`, and use native selection gestures to produce `WordSpan`s.
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

    // MARK: - UIViewRepresentable lifecycle

    /// Creates and configures the backing `UITextView`.
    func makeUIView(context: Context) -> UITextView {
        let tv = SelectionTextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.backgroundColor = .clear
        // Remove default paddings so wrapping aligns with SwiftUI container edges.
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        // Track the text view's width so the text wraps at the container width.
        tv.textContainer.widthTracksTextView = true
        // Ensure wrapping occurs instead of horizontal expansion.
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.defaultLow, for: .horizontal)
        // Encourage full vertical expansion so content isn't clipped.
        tv.setContentHuggingPriority(.required, for: .vertical)
        tv.setContentCompressionResistancePriority(.required, for: .vertical)
        tv.delegate = context.coordinator
        tv.allowsEditingTextAttributes = false
        tv.linkTextAttributes = [:]
        tv.dataDetectorTypes = []
        // Let outer SwiftUI ScrollView scroll; but keep internal scroll disabled.
        tv.isScrollEnabled = false
        // Ensure selection handles can be tapped/dragged: don't intercept touches unnecessarily.
        tv.isUserInteractionEnabled = true
        // Ensure long-press within the text view triggers native selection even inside a SwiftUI ScrollView.
        let lp = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        lp.minimumPressDuration = 0.5
        lp.cancelsTouchesInView = false
        lp.delaysTouchesBegan = false
        lp.delegate = context.coordinator
        tv.addGestureRecognizer(lp)

        // Double-tap: select the tapped word to kick off selection reliably.
        let dt = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        dt.numberOfTapsRequired = 2
        dt.cancelsTouchesInView = false
        dt.delegate = context.coordinator
        tv.addGestureRecognizer(dt)

        // Single tap: clear selection when tapping outside, to dismiss action bar.
        let st = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSingleTap(_:)))
        st.numberOfTapsRequired = 1
        st.require(toFail: dt)
        st.cancelsTouchesInView = false
        st.delegate = context.coordinator
        tv.addGestureRecognizer(st)
        return tv
    }

    /// Rebuilds attributed content and preserves selection during updates.
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Preserve selection to avoid clearing the menu and action bar mid-update.
        let priorSelectedRange = uiView.selectedRange

        // Build key: only rebuild attributed text when inputs change, not on every selection change.
        let highlightsSignature = highlights.map { h in
            let s = h.wordSpan?.start
            let e = h.wordSpan?.end
            return "\(h.id.uuidString):\(h.range.bookId)-\(h.range.chapter)-\(h.range.startVerse)-\(h.range.endVerse):\(s?.verse ?? -1)-\(s?.wordIndex ?? -1)-\(e?.verse ?? -1)-\(e?.wordIndex ?? -1):\(h.color.rawValue)"
        }.joined(separator: ",")
        let buildKey = "\(bookId)|\(chapter.number)|\(fontSize)|\(highlightsSignature)"

        if context.coordinator.lastBuildKey != buildKey {
            let build = AttributedChapterBuilder(bookId: bookId, chapter: chapter, fontSize: fontSize, highlights: highlights)
            let result = build.build()
            context.coordinator.mapping = result.mapping
            context.coordinator.spacingAfter = result.spacingAfter
            uiView.attributedText = result.attributed
            context.coordinator.lastBuildKey = buildKey
        }

        // Restore selection if still valid in the current content.
        if priorSelectedRange.location >= 0,
           priorSelectedRange.location + priorSelectedRange.length <= uiView.attributedText.length {
            uiView.selectedRange = priorSelectedRange
        }
        uiView.isUserInteractionEnabled = true
        uiView.isSelectable = true
        uiView.isAccessibilityElement = true
        uiView.accessibilityIdentifier = "reading.chapter.\(chapter.number)"
    }

    // Ensure SwiftUI asks UIKit for the correct height based on the given width.
    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize {
        let width = proposal.width ?? uiView.bounds.width
        let targetWidth = max(width, 0)
        let size = uiView.sizeThatFits(CGSize(width: targetWidth, height: .greatestFiniteMagnitude))
        return CGSize(width: targetWidth, height: size.height)
    }

    func makeCoordinator() -> Coordinator { Coordinator(bookId: bookId, chapter: chapter, onSelectionChange: onSelectionChange) }

    // MARK: - Coordinator
    // MARK: - Coordinator

    /// Orchestrates selection handling and text-to-word mapping lookups.
    final class Coordinator: NSObject, UITextViewDelegate, UIGestureRecognizerDelegate {
        private let bookId: String
        private let chapter: BibleChapter
        private let onSelectionChange: (WordSpan?) -> Void
        /// Mapping from word boundaries to `NSRange` segments.
        var mapping: [NSRange: VerseWordPosition] = [:]
        /// Mapping from trailing space ranges to the preceding word position (same verse/wordIndex).
        var spacingAfter: [NSRange: VerseWordPosition] = [:]
        /// Track the last build inputs to avoid resetting text during selection drags.
        var lastBuildKey: String?

        init(bookId: String, chapter: BibleChapter, onSelectionChange: @escaping (WordSpan?) -> Void) {
            self.bookId = bookId
            self.chapter = chapter
            self.onSelectionChange = onSelectionChange
        }

        /// Handles long-press initiation of selection at the touch location.
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let textView = gesture.view as? UITextView else { return }
            if gesture.state == .began {
                let point = gesture.location(in: textView)
                selectNearestWord(in: textView, at: point)
            }
        }

        /// Handles double-tap to select the tapped word.
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView = gesture.view as? UITextView else { return }
            let point = gesture.location(in: textView)
            selectNearestWord(in: textView, at: point)
        }

        /// Handles single tap outside selection to clear selection and dismiss action bar.
        @objc func handleSingleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView = gesture.view as? UITextView else { return }
            let point = gesture.location(in: textView)
            if let pos = textView.closestPosition(to: point), let caret = textView.textRange(from: pos, to: pos) {
                textView.selectedTextRange = caret
            }
        }

        // Allow system text view gestures (double-tap, drag) to work; give precedence to selection handles.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            // If the user is interacting near selection handles, prefer the system recognizers.
            if let tv = gestureRecognizer.view as? UITextView {
                let point = gestureRecognizer.location(in: tv)
                // Hit-test for selection rects: if near, let system handle it by returning false.
                if isNearSelectionHandle(in: tv, at: point) { return false }
            }
            return true
        }

        private func isNearSelectionHandle(in textView: UITextView, at point: CGPoint) -> Bool {
            // Heuristic: check proximity to the rects of the current selected text range.
            guard let range = textView.selectedTextRange else { return false }
            let startRect = textView.firstRect(for: range)
            let endRect = textView.caretRect(for: range.end)
            let handleRadius: CGFloat = 24
            return startRect.insetBy(dx: -handleRadius, dy: -handleRadius).contains(point) || endRect.insetBy(dx: -handleRadius, dy: -handleRadius).contains(point)
        }

        /// Selects the word at the given point if possible; otherwise places a caret.
        ///
        /// This yields a non-empty selection to ensure the system edit menu has performable actions (e.g., Copy).
        private func selectNearestWord(in textView: UITextView, at point: CGPoint) {
            let localPoint = CGPoint(x: point.x - textView.textContainerInset.left,
                                     y: point.y - textView.textContainerInset.top)
            guard let pos = textView.closestPosition(to: localPoint) else { return }
            let beginning = textView.beginningOfDocument
            let tappedIndex = textView.offset(from: beginning, to: pos)
            let nsText = textView.text as NSString
            let length = nsText.length
            guard length > 0 else { return }

            // Expand to the nearest word boundaries.
            let bounds = wordBoundaryIndices(in: nsText, around: tappedIndex)

            textView.becomeFirstResponder()
            if let (start, end) = bounds,
               let startPos = textView.position(from: beginning, offset: start),
               let endPos = textView.position(from: beginning, offset: end),
               let range = textView.textRange(from: startPos, to: endPos) {
                textView.selectedTextRange = range
            } else {
                textView.selectedTextRange = textView.textRange(from: pos, to: pos)
            }
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            let selRange = textView.selectedRange
            guard selRange.length > 0 else {
                DispatchQueue.main.async { self.onSelectionChange(nil) }
                return
            }

            // Translate current selection into approximate word boundaries.
            guard let start = nearestWordPosition(for: selRange.location),
                  let end = nearestWordPosition(for: selRange.location + selRange.length - 1) else {
                onSelectionChange(nil); return
            }
            let span = WordSpan(bookId: bookId, chapter: chapter.number, start: start, end: end)
            DispatchQueue.main.async { self.onSelectionChange(span) }
        }

        // MARK: - Word mapping helpers

        /// Returns the best matching `VerseWordPosition` for a character location.
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

        /// Computes word boundary character indices in `text` surrounding `index`.
        /// - Returns: `(start, end)` indices for a non-empty word range, or `nil` if none found.
        private func wordBoundaryIndices(in text: NSString, around index: Int) -> (start: Int, end: Int)? {
            let length = text.length
            guard length > 0 else { return nil }
            let breakers = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)

            func isBreaker(at i: Int) -> Bool {
                let ch = text.character(at: i)
                guard let scalar = UnicodeScalar(ch) else { return true }
                return breakers.contains(scalar)
            }

            var start = index
            while start > 0 {
                if isBreaker(at: start - 1) { break }
                start -= 1
            }

            var end = index
            while end < length {
                if isBreaker(at: end) { break }
                end += 1
            }

            if start == end {
                var i = index
                while i < length, isBreaker(at: i) { i += 1 }
                var j = i
                while j < length, !isBreaker(at: j) { j += 1 }
                if j > i { start = i; end = j }
            }

            return (start < end) ? (start, end) : nil
        }
    }
}

// MARK: - Attributed text builder

/// Builds an attributed string for a chapter and a mapping from word `NSRange`s to `VerseWordPosition`s.
/// This design centralizes tokenization and styling logic and makes it easy to test.
/// Constructs styled chapter text and the range-to-word mapping used for selection.
struct AttributedChapterBuilder {
    let bookId: String
    let chapter: BibleChapter
    let fontSize: CGFloat
    let highlights: [Highlight]

    /// Result of building the chapter string and auxiliary selection maps.
    struct Result { let attributed: NSAttributedString; let mapping: [NSRange: VerseWordPosition]; let spacingAfter: [NSRange: VerseWordPosition] }

    /// Builds the attributed text and selection maps for the current chapter.
    func build() -> Result {
        let mutable = NSMutableAttributedString()
        var mapping: [NSRange: VerseWordPosition] = [:]
        var spacingAfter: [NSRange: VerseWordPosition] = [:]

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        paragraph.lineBreakMode = .byWordWrapping

        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraph
        ]
        let verseNumberAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: max(fontSize * 0.7, 8)),
            .baselineOffset: max(fontSize * 0.35, 2),
            .foregroundColor: verseNumberUIColor()
        ]

        for verse in chapter.verses {
            // Verse number prefix (non-selectable intent, but part of text for simplicity)
            let numberAttr = NSAttributedString(string: "\(verse.number) ", attributes: verseNumberAttrs)
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
                    // Track the trailing space so highlights can include whitespace between words.
                    let spaceRange = NSRange(location: cursor, length: 1)
                    spacingAfter[spaceRange] = VerseWordPosition(verse: verse.number, wordIndex: index)
                    mutable.append(space)
                    cursor += 1
                }
            }

            // Newline after each verse
            mutable.append(NSAttributedString(string: "\n", attributes: baseAttrs))
        }

        // Apply highlight backgrounds for words covered by any highlight.
        for (range, pos) in mapping {
            guard let color = backgroundColorForWord(at: pos) else { continue }
            mutable.addAttribute(.backgroundColor, value: color, range: range)
        }
        // Also tint trailing spaces after highlighted words for continuous background.
        for (spaceRange, pos) in spacingAfter {
            guard let color = backgroundColorForWord(at: pos) else { continue }
            mutable.addAttribute(.backgroundColor, value: color, range: spaceRange)
        }

        return Result(attributed: mutable, mapping: mapping, spacingAfter: spacingAfter)
    }

    /// Returns a background color for a given word position if any highlight covers it.
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

    private func verseNumberUIColor() -> UIColor {
        #if os(iOS)
        // Derive from secondaryLabel to adapt to themes; slightly lighter for unobtrusive look.
        let base = UIColor.secondaryLabel
        var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
        base.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
        let adjusted = UIColor(hue: hue, saturation: max(sat * 0.85, 0), brightness: min(bri * 1.05, 1.0), alpha: alpha)
        return adjusted
        #else
        return UIColor.secondaryLabel
        #endif
    }
}


// MARK: - Always-allow-Copy TextView subclass
/// Ensures the Copy action is available whenever there is a non-empty selection,
/// which stabilizes the edit menu presentation even in edge cases.
final class SelectionTextView: UITextView {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) {
            return selectedRange.length > 0
        }
        return super.canPerformAction(action, withSender: sender)
    }
}

