import SwiftUI

/// App-wide color tokens.
/// Centralize theme-aware colors for consistent styling and easy future tuning.
enum AppColors {
	/// Disabled content color for unavailable items (e.g., books not in the selected translation).
	/// Uses a medium-dark gray tone adapted to light/dark mode via semantic colors.
	static var disabledContent: Color {
		#if os(iOS)
		return Color(UIColor { trait in
			// Start from secondaryLabel (adapts to theme) and bias slightly darker for clarity.
			let base = UIColor.secondaryLabel
			var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alpha: CGFloat = 0
			base.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha)
			let adjusted = UIColor(hue: hue, saturation: min(sat * 0.7, 1.0), brightness: max(bri * 0.75, 0.0), alpha: alpha)
			return adjusted
		})
		#else
		return Color.secondary
		#endif
	}
}
