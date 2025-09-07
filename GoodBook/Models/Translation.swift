import Foundation

/// Supported Bible translations used to lookup bundled JSON under
/// `AppResources/Bibles/<TRANSLATION>/`.
/// Extend this list as licenses are added.
enum Translation: String, CaseIterable, Codable, Identifiable {
	case kjv = "KJV"
	case nkjv = "NKJV"
	case esv = "ESV"
	case niv = "NIV"
	case csb = "CSB"
	case nrsv = "NRSV"

	var id: String { rawValue }
	/// Human-friendly name shown in the UI.
	var displayName: String { rawValue }
}
