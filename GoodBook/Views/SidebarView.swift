import SwiftUI

/// Swipeable left sidebar for book navigation.
/// - What: A left drawer listing books grouped by Old Testament, Apocrypha, and New Testament.
/// - Why: Fast, predictable access to books while maintaining context in the reader.
/// - How: Custom drawer built with `ScrollView` + `LazyVStack`, with a scrim and interactive drag gestures.
struct SidebarView: View {
	/// Whether the sidebar is currently open.
	@Binding var isOpen: Bool
	/// Currently selected translation; used to compute availability per row.
	let selectedTranslation: Translation
	/// Callback when a book is selected (only invoked for available books).
	let onSelectBook: (String) -> Void

	/// In-flight drag offset used to track interactive gesture progress.
	@State private var dragOffsetX: CGFloat = 0
	/// Width of the drawer as a fraction of the screen.
	private let drawerWidthFraction: CGFloat = 0.82
	/// Maximum opacity of the scrim when the drawer is fully open.
	private let maxShadowOpacity: Double = 0.35
	/// Minimum drag distance to toggle open/close when gesture ends.
	private let openThreshold: CGFloat = 80

	/// Availability checker for books per translation. Constructed per-render; inexpensive.
	private var availability: TranslationAvailabilityService { TranslationAvailabilityService() }

	var body: some View {
		GeometryReader { geo in
			let drawerWidth = geo.size.width * drawerWidthFraction

			ZStack(alignment: .leading) {
				// Scrim
				Color.black.opacity(isOpen ? maxShadowOpacity : 0)
					.ignoresSafeArea()
					.accessibilityIdentifier("sidebar.scrim")
					.accessibilityHidden(!isOpen)
					.onTapGesture { withAnimation(.interactiveSpring()) { isOpen = false } }
					.allowsHitTesting(isOpen)

				// Drawer content
				drawerContent(width: drawerWidth)
					.frame(width: drawerWidth, alignment: .leading)
					.background(.thinMaterial)
					.offset(x: currentXOffset(baseWidth: drawerWidth))
					.shadow(radius: 8, x: 2, y: 0)
					.gesture(dragGesture(drawerWidth: drawerWidth))
			}
			// NOTE(csummers-dev): The drawer currently snaps open/closed a bit too quickly.
			// Keep as-is for now to ship the feature; revisit to tune spring response/damping
			// for a slower, more polished feel without regressing gesture responsiveness.
			.animation(.interactiveSpring(), value: isOpen)
		}
		.accessibilityIdentifier("sidebar.root")
		.accessibilityHidden(!isOpen)
	}

	/// Compute the current X offset combining open state and in-flight drag.
	private func currentXOffset(baseWidth: CGFloat) -> CGFloat {
		let closedX = -baseWidth
		let openX: CGFloat = 0
		return (isOpen ? openX : closedX) + dragOffsetX
	}

	/// Drag gesture to open/close the drawer interactively.
	private func dragGesture(drawerWidth: CGFloat) -> some Gesture {
		DragGesture(minimumDistance: 5, coordinateSpace: .local)
			.onChanged { value in
				// Only track horizontal movement; clamp so the drawer never overshoots to the right.
				let translation = value.translation.width
				let proposed = isOpen ? max(-drawerWidth, min(0, translation)) : min(0, translation)
				dragOffsetX = proposed
			}
			.onEnded { value in
				let translation = value.translation.width
				let velocity = value.velocity?.width ?? 0
				let shouldOpen = (translation > openThreshold) || (isOpen && velocity > 350)
				let shouldClose = (translation < -openThreshold) || (!isOpen && velocity < -350)
				withAnimation(.interactiveSpring()) {
					if shouldClose { isOpen = false }
					else if shouldOpen { isOpen = true }
					dragOffsetX = 0
				}
			}
	}

	/// Drawer content built with ScrollView + LazyVStack for full control.
	@ViewBuilder
	private func drawerContent(width: CGFloat) -> some View {
		VStack(alignment: .leading, spacing: 0) {
			Text("Library")
				.font(.title2).bold()
				.padding(.horizontal)
				.padding(.vertical, 12)
			Divider()
			ScrollView {
				// Use Section + pinned headers so group titles remain visible while scrolling.
				// Note: LazyVStack only instantiates views on-screen; UI tests must scroll to realize later headers.
				LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
					ForEach(BibleCatalog.allGroupsInOrder, id: \.group) { section in
						Section(header: sectionHeader(section.group)) {
							ForEach(section.books) { book in
								bookRow(book)
							}
						}
					}
				}
			}
			.accessibilityIdentifier("sidebar.scroll")
		}
	}

	@ViewBuilder
	private func sectionHeader(_ group: BibleCatalog.Group) -> some View {
		Text(group.rawValue)
			.font(.callout.weight(.semibold))
			.foregroundColor(Color(UIColor.secondaryLabel))
			.padding(.horizontal)
			.padding(.vertical, 8)
			// Background ensures content scrolling underneath is not visible through the header.
			.background(.ultraThinMaterial)
			// Subtle divider for separation.
			.overlay(alignment: .bottom) { Divider().opacity(0.5) }
			// Slight elevation to keep the header above rows.
			.zIndex(1)
			.accessibilityElement()
			.accessibilityIdentifier(identifierFor(group))
			.accessibilityAddTraits(.isHeader)
	}

	private func identifierFor(_ group: BibleCatalog.Group) -> String {
		switch group {
		case .oldTestament: return "sidebar.section.ot"
		case .apocrypha: return "sidebar.section.apocrypha"
		case .newTestament: return "sidebar.section.nt"
		}
	}

	@ViewBuilder
	private func bookRow(_ meta: BibleCatalog.BookMeta) -> some View {
		let available = availability.isBookAvailable(bookId: meta.id, translation: selectedTranslation)
		Button(action: { if available { onSelectBook(meta.id); isOpen = false } }) {
			HStack {
				Text(meta.name)
					.foregroundStyle(available ? .primary : AppColors.disabledContent)
				Spacer()
			}
			.padding(.horizontal)
			.padding(.vertical, 10)
		}
		.buttonStyle(.plain)
		.disabled(!available)
		.accessibilityIdentifier("sidebar.book.\(meta.id)")
	}
}

private extension DragGesture.Value {
	/// Approximate horizontal velocity in points/second if available.
	var velocity: CGSize? {
		#if canImport(UIKit)
		return self.predictedEndLocation - self.location
		#else
		return nil
		#endif
	}
}

private func - (lhs: CGPoint, rhs: CGPoint) -> CGSize { CGSize(width: lhs.x - rhs.x, height: lhs.y - rhs.y) }


