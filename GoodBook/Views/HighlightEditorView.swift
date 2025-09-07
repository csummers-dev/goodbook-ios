import SwiftUI

/// Editor for creating or updating a highlight and optional note.
struct HighlightEditorView: View {
	let range: VerseRange
	var existing: Highlight?
	var onSave: (Highlight) -> Void

	@Environment(
		\.dismiss) private var dismiss
	@State private var color: HighlightColor
	@State private var note: String

	init(range: VerseRange, existing: Highlight?, onSave: @escaping (Highlight) -> Void) {
		self.range = range
		self.existing = existing
		self.onSave = onSave
		_color = State(initialValue: existing?.color ?? .yellow)
		_note = State(initialValue: existing?.note ?? "")
	}

	var body: some View {
		NavigationStack {
			Form {
				Section("Color") {
					Picker("Color", selection: $color) {
						ForEach(HighlightColor.allCases) { c in
							Text(c.rawValue.capitalized).tag(c)
						}
					}
				}
				Section("Notes (optional)") {
					TextEditor(text: $note).frame(minHeight: 120)
				}
			}
			.navigationTitle("Highlight")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") { dismiss() }
						.accessibilityIdentifier("editor.cancel")
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Save") {
						let base = existing ?? Highlight(range: range, color: color, note: nil)
						var updated = base
						updated.color = color
						updated.note = note.isEmpty ? nil : note
						onSave(updated)
						dismiss()
					}
					.accessibilityIdentifier("editor.save")
				}
			}
		}
	}
}

#Preview {
	HighlightEditorView(range: VerseRange(bookId: "John", chapter: 10, startVerse: 10, endVerse: 12), existing: nil) { _ in }
}
