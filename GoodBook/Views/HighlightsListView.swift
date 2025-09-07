import SwiftUI

/// Shows all saved highlights grouped by location. Future versions will add grouping
/// by book/chapter/verse and filtering by color.
struct HighlightsListView: View {
	@EnvironmentObject private var store: HighlightStore

	var body: some View {
		List(store.highlights) { h in
			VStack(alignment: .leading) {
				let displayRange = h.wordSpan?.toVerseRange() ?? h.range
				Text("\(displayRange.bookId) \(displayRange.chapter):\(displayRange.startVerse)\(displayRange.endVerse == displayRange.startVerse ? "" : "-\(displayRange.endVerse)")")
					.font(.headline)
				if let note = h.note, !note.isEmpty {
					Text(note).font(.subheadline)
				}
			}
		}
		.navigationTitle("Highlights")
	}
}

#Preview {
	HighlightsListView().environmentObject(HighlightStore())
}
