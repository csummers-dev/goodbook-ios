import SwiftUI

/// Reading screen for rendering chapters and managing highlights and selection.
/// - Supports: highlight visibility toggle, native selection with bottom action bar,
///   context menus per verse, and optional note editing.
struct ReadingView: View {
	// MARK: - Environment
	@EnvironmentObject private var env: AppEnvironment
	@EnvironmentObject private var settings: SettingsStore
	@EnvironmentObject private var highlightStore: HighlightStore

	// MARK: - State
	@StateObject private var viewModel: ReadingViewModel
	/// If set, the note editor sheet should present for this context.
	@State private var editorContext: (range: VerseRange, existing: Highlight?)?
	/// Transient selection representation used to drive the action bar and notes toggle.
	@State private var activeSelection: TextSelection?
	/// Controls visibility of the bottom selection action bar.
	@State private var isActionBarVisible: Bool = false
    @State private var editorSheet: EditorSheet?
	/// Word-level selection produced by native iOS selection handles.
	@State private var wordSpanSelection: WordSpan?

	init(bookId: String) {
		// Initialize with minimal dependencies; will be configured on appear
		_viewModel = StateObject(wrappedValue: ReadingViewModel(bookId: bookId))
	}

	// MARK: - Body
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
					.scrollDisabled(isActionBarVisible)

					if isActionBarVisible {
						selectionActionBar()
					}

					// Test hook: tiny, non-interactive flag signaling active selection state
					if isActionBarVisible {
						Color.clear
							.frame(width: 1, height: 1)
							.allowsHitTesting(false)
							.accessibilityIdentifier("reading.selection.active")
					}
				}
			}
		}
		// MARK: - Toolbar
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Toggle(isOn: $viewModel.isShowingHighlights) { Image(systemName: viewModel.isShowingHighlights ? "eye" : "eye.slash") }
					.toggleStyle(.button)
					.accessibilityIdentifier("reading.toggle.highlights")
			}
		}
		// MARK: - Sheets
		.sheet(item: $editorSheet) { sheet in
			HighlightEditorView(range: sheet.range, existing: sheet.existing) { highlight in
				highlightStore.upsert(highlight)
				closeEditor()
			}
		}
		// MARK: - Observers
		.onChange(of: settings.selectedTranslation) { _, _ in
			Task { await viewModel.reloadForTranslationChange() }
		}
		// MARK: - Overlays
		.overlay(alignment: .top) {
			if let message = viewModel.errorMessage {
				Text(message).font(.footnote).padding(8).background(.thinMaterial).cornerRadius(8).padding()
			}
		}
		.task { await initialConfigureAndLoad() }
	}

	// MARK: - Types
	private struct EditorSheet: Identifiable {
		let id: String
		let range: VerseRange
		let existing: Highlight?
	}

	// MARK: - Lifecycle
	/// Wires dependencies and kicks off the initial data load.
	private func initialConfigureAndLoad() async {
		viewModel.configure(provider: env.bibleProvider, settings: settings)
		await viewModel.load()
	}

	// MARK: - Subviews
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

	/// Bottom action bar shown when a selection is active. Taps outside dismiss it.
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
				.accessibilityIdentifier("reading.action.highlight")
			}
			.accessibilityIdentifier("reading.actionbar")
			.padding(.horizontal)
			.padding(.vertical, 12)
			.background(.thinMaterial)
		}
		.transition(.move(edge: .bottom))
	}

	// MARK: - Actions
	/// Commits the temporary selection into a persisted highlight or opens the note editor.
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

	/// Presents the highlight editor sheet for `range`, optionally seeding with `existing`.
	private func openEditor(range: VerseRange, existing: Highlight?) {
		let id = "\(range.bookId)-\(range.chapter)-\(range.startVerse)-\(range.endVerse)"
		editorSheet = EditorSheet(id: id, range: range, existing: existing)
	}

	/// Dismisses the editor and clears selection/action bar state.
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
