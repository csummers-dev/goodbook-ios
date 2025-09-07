import Foundation

/// Service to determine if a specific Bible book resource exists for a translation.
/// - What: Checks for presence of `AppResources/Bibles/<TRANSLATION>/<BookId>.json` in the bundle.
/// - Why: Drives UI availability (enabled/disabled) without decoding content.
final class TranslationAvailabilityService {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    /// Returns true if the JSON resource for the given book/translation exists in the bundle.
    func isBookAvailable(bookId: String, translation: Translation) -> Bool {
        let fileName = bookId
        let subpath = "AppResources/Bibles/\(translation.rawValue)/\(fileName)"
        // Locate JSON under sub-bundle path; support both flat and nested resources when packaged.
        if let url = bundle.url(forResource: subpath, withExtension: "json") {
            return FileManager.default.fileExists(atPath: url.path)
        }
        // Fallback: try exact folder reference resolution if the toolchain flattens differently.
        if let url = bundle.url(forResource: fileName, withExtension: "json", subdirectory: "AppResources/Bibles/\(translation.rawValue)") {
            return FileManager.default.fileExists(atPath: url.path)
        }
        return false
    }
}


