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

/// User highlight spanning a contiguous verse range, with optional note.
struct Highlight: Codable, Identifiable, Equatable {
	let id: UUID
	let range: VerseRange
	var color: HighlightColor
	var note: String?

	init(id: UUID = UUID(), range: VerseRange, color: HighlightColor, note: String?) {
		self.id = id
		self.range = range
		self.color = color
		self.note = note
	}
}
