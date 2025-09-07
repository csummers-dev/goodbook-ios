import SwiftUI

/// Reading screen that displays a book's chapters and verses.
/// - Supports: highlight visibility toggle, long-press selection with action bar,
///   context menu per verse, and optional note editing.
struct ReadingView: View {
	@EnvironmentObject private var env: AppEnvironment
	@EnvironmentObject private var settings: SettingsStore
	@EnvironmentObject private var highlightStore: HighlightStore

	@StateObject private var viewModel: ReadingViewModel
	@State private var editorContext: (range: VerseRange, existing: Highlight?)?
	@State private var activeSelection: TextSelection?
	@State private var isActionBarVisible: Bool = false
    @State private var editorSheet: EditorSheet?
	/// Word-level selection produced by native text selection handles.
	@State private var wordSpanSelection: WordSpan?

	init(bookId: String) {
		// Initialize with minimal dependencies; will be configured on appear
		_viewModel = StateObject(wrappedValue: ReadingViewModel(bookId: bookId))
	}

	var body: some View {
		Group {
			switch viewModel.book {
			case .none:
				ProgressView()
			case .some(let book):
				ZStack(alignment: .bottom) {
					ScrollView {
						LazyVStack(alignment: .leading, spacing: 12) {
							ForEach(book.chapters) { chapter in
								chapterHeader(chapter)
								SelectableChapterTextView(
									bookId: book.id,
									chapter: chapter,
									fontSize: CGFloat(settings.readerFontSize),
									highlights: viewModel.isShowingHighlights ? highlightStore.highlights(for: book.id, chapter: chapter.number) : [],
									onSelectionChange: { span in
										wordSpanSelection = span
										if let span {
											// Also populate activeSelection to reuse Notes toggle plumbing
											activeSelection = TextSelection(
												bookId: book.id,
												chapter: chapter.number,
												start: span.start,
												end: span.end,
												notesEnabled: activeSelection?.notesEnabled ?? false
											)
											withAnimation { isActionBarVisible = true }
										} else {
											withAnimation { isActionBarVisible = false }
										}
									}
								)
							}
						}
						.padding(.horizontal)
					}

					if isActionBarVisible {
						selectionActionBar()
					}
				}
			}
		}
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Toggle(isOn: $viewModel.isShowingHighlights) { Image(systemName: viewModel.isShowingHighlights ? "eye" : "eye.slash") }
					.toggleStyle(.button)
					.accessibilityIdentifier("reading.toggle.highlights")
			}
		}
		.sheet(item: $editorSheet) { sheet in
			HighlightEditorView(range: sheet.range, existing: sheet.existing) { highlight in
				highlightStore.upsert(highlight)
				closeEditor()
			}
		}
		.onChange(of: settings.selectedTranslation) { _, _ in
			Task { await viewModel.reloadForTranslationChange() }
		}
		.overlay(alignment: .top) {
			if let message = viewModel.errorMessage {
				Text(message).font(.footnote).padding(8).background(.thinMaterial).cornerRadius(8).padding()
			}
		}
		.task { await initialConfigureAndLoad() }
	}

	private struct EditorSheet: Identifiable {
		let id: String
		let range: VerseRange
		let existing: Highlight?
	}

	/// Wire dependencies and kick off the initial load.
	private func initialConfigureAndLoad() async {
		viewModel.configure(provider: env.bibleProvider, settings: settings)
		await viewModel.load()
	}

	@ViewBuilder
	private func chapterHeader(_ chapter: BibleChapter) -> some View {
		Text("Chapter \(chapter.number)")
			.font(.title2).bold()
			.padding(.top, 8)
	}

	@ViewBuilder
	private func verseRow(bookId: String, chapter: Int, verse: BibleVerse) -> some View {
		let range = VerseRange(bookId: bookId, chapter: chapter, startVerse: verse.number, endVerse: verse.number)
		let highlights = highlightStore.highlights(for: bookId, chapter: chapter)
		let existing = highlights.first { $0.range.startVerse <= verse.number && verse.number <= $0.range.endVerse }

		Text("\(verse.number)  \(verse.text)")
			.font(.system(size: settings.readerFontSize))
			.padding(.vertical, 2)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(viewModel.isShowingHighlights ? existing?.color.color : .clear)
			.contentShape(Rectangle())
			.accessibilityIdentifier("reading.verse.\(chapter)-\(verse.number)")
			// Long-press approximation retained for fallback; primary path uses native selection above.
			.contextMenu {
				Button(action: {
					editorContext = (range, existing)
				}) { Text(existing == nil ? "Add Highlight" : "Edit Highlight") }
				if let existing {
					Button(role: .destructive, action: { highlightStore.delete(existing) }) { Text("Remove Highlight") }
				}
			}
	}

	// Bottom action bar shown when a selection is active. Taps outside dismiss it.
	@ViewBuilder
	private func selectionActionBar() -> some View {
		VStack(spacing: 0) {
			Color.black.opacity(0.001)
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.contentShape(Rectangle())
				.onTapGesture { withAnimation { isActionBarVisible = false; activeSelection = nil; wordSpanSelection = nil } }

			HStack(spacing: 16) {
				Toggle(isOn: Binding(get: { (activeSelection?.notesEnabled ?? false) }, set: { value in
					self.activeSelection?.notesEnabled = value
				})) {
					Text("Notes")
				}
				.toggleStyle(.switch)

				Spacer()

				Button(action: { commitSelection() }) {
					Label("Highlight", systemImage: "highlighter")
				}
			}
			.padding(.horizontal)
			.padding(.vertical, 12)
			.background(.thinMaterial)
		}
		.transition(.move(edge: .bottom))
	}

	/// Commit the temporary selection into a persisted highlight or open the note editor.
	private func commitSelection() {
		if let span = wordSpanSelection {
			let range = span.toVerseRange()
			if activeSelection?.notesEnabled == true {
				let base = Highlight(range: range, wordSpan: span, color: settings.lastHighlightColor, note: nil)
				openEditor(range: range, existing: base)
			} else {
				let highlight = Highlight(range: range, wordSpan: span, color: settings.lastHighlightColor, note: nil)
				highlightStore.upsert(highlight)
			}
		} else if let selection = activeSelection {
			let range = selection.toVerseRange()
			if selection.notesEnabled {
				// Open editor with default color from settings
				let base = Highlight(range: range, color: settings.lastHighlightColor, note: nil)
				openEditor(range: range, existing: base)
			} else {
				let highlight = Highlight(range: range, color: settings.lastHighlightColor, note: nil)
				highlightStore.upsert(highlight)
			}
		}
		closeEditor()
	}

	private func openEditor(range: VerseRange, existing: Highlight?) {
		let id = "\(range.bookId)-\(range.chapter)-\(range.startVerse)-\(range.endVerse)"
		editorSheet = EditorSheet(id: id, range: range, existing: existing)
	}

	private func closeEditor() {
		withAnimation { isActionBarVisible = false }
		activeSelection = nil
		wordSpanSelection = nil
		editorSheet = nil
	}
}

#Preview {
	ReadingView(bookId: "John")
		.environmentObject(AppEnvironment(bibleProvider: LocalJSONBibleProvider()))
		.environmentObject(SettingsStore())
		.environmentObject(HighlightStore())
}
