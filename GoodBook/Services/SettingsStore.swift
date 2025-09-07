import Foundation
import SwiftUI
import Combine

/// App-wide settings with persistence via UserDefaults.
/// Avoids property observers during initialization to prevent accessing `self`
/// before all stored properties are initialized.
final class SettingsStore: ObservableObject {
	// Keys for persistence; kept internal for future migration/sync
	private static let keySelectedTranslation = "selectedTranslation"
	private static let keyPreferredTheme = "preferredTheme"
	private static let keyReaderFontSize = "readerFontSize"
    private static let keyLastHighlightColor = "lastHighlightColor"

	@Published var selectedTranslation: Translation
	@Published var preferredTheme: Theme
	@Published var readerFontSize: Double
    /// Last color chosen for a highlight, used as default for new highlights.
    @Published var lastHighlightColor: HighlightColor

	private let userDefaults: UserDefaults
	private var cancellables: Set<AnyCancellable> = []

	/// Initialize from stored defaults, falling back to sensible values.
	init(userDefaults: UserDefaults = .standard) {
		self.userDefaults = userDefaults

		// Read initial values without touching self's stored properties via wrappers
        let tRaw = userDefaults.string(forKey: Self.keySelectedTranslation) ?? Translation.esv.rawValue
        let themeRaw = userDefaults.string(forKey: Self.keyPreferredTheme) ?? Theme.system.rawValue
        let font = (userDefaults.object(forKey: Self.keyReaderFontSize) as? Double) ?? 18
        let colorRaw = userDefaults.string(forKey: Self.keyLastHighlightColor) ?? HighlightColor.yellow.rawValue

        selectedTranslation = Translation(rawValue: tRaw) ?? .esv
        preferredTheme = Theme(rawValue: themeRaw) ?? .system
        readerFontSize = font
        lastHighlightColor = HighlightColor(rawValue: colorRaw) ?? .yellow

		// Persist changes after initialization
		$selectedTranslation
			.dropFirst()
			.sink { [weak self] value in
				self?.userDefaults.set(value.rawValue, forKey: Self.keySelectedTranslation)
			}
			.store(in: &cancellables)

		$preferredTheme
			.dropFirst()
			.sink { [weak self] value in
				self?.userDefaults.set(value.rawValue, forKey: Self.keyPreferredTheme)
			}
			.store(in: &cancellables)

		$readerFontSize
			.dropFirst()
			.sink { [weak self] value in
				self?.userDefaults.set(value, forKey: Self.keyReaderFontSize)
			}
			.store(in: &cancellables)

        $lastHighlightColor
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value.rawValue, forKey: Self.keyLastHighlightColor)
            }
            .store(in: &cancellables)
	}
}

/// App theme selection.
enum Theme: String, CaseIterable, Identifiable, Codable {
	case system, light, dark, sepia
	var id: String { rawValue }

	/// Map to SwiftUI color scheme. `nil` respects the system setting.
	var colorScheme: ColorScheme? {
		switch self {
		case .system: return nil
		case .light: return .light
		case .dark: return .dark
		case .sepia: return nil
		}
	}
}
