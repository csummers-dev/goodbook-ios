import Foundation
import SwiftUI

/// Available highlight colors used for display and filtering.
enum HighlightColor: String, Codable, CaseIterable, Identifiable {
	case yellow, green, blue, pink, orange
	var id: String { rawValue }

	/// SwiftUI color to render the highlight background.
	var color: Color {
		switch self {
		case .yellow: return .yellow.opacity(0.35)
		case .green: return .green.opacity(0.35)
		case .blue: return .blue.opacity(0.35)
		case .pink: return .pink.opacity(0.35)
		case .orange: return .orange.opacity(0.35)
		}
	}
}

/// User highlight with required contiguous verse range and optional precise word span.
/// - Why: Preserve portability via verse ranges while allowing word-level fidelity in the reader.
/// - How: `range` is persisted and used for list display; `wordSpan` refines in-reader rendering when present.
struct Highlight: Codable, Identifiable, Equatable {
	let id: UUID
	let range: VerseRange
	/// Optional word-level span that refines the highlight inside `range`.
	/// If absent, the highlight applies to the entire verses in `range`.
	var wordSpan: WordSpan?
	var color: HighlightColor
	var note: String?

	init(id: UUID = UUID(), range: VerseRange, wordSpan: WordSpan? = nil, color: HighlightColor, note: String?) {
		self.id = id
		self.range = range
		self.wordSpan = wordSpan
		self.color = color
		self.note = note
	}
}
