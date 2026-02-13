import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum HapticManager {
    /// Triggers a standard success haptic on supported devices.
    public static func success() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #else
        // No-op on platforms without UIKit haptics
        #endif
    }

    /// Triggers a standard warning haptic on supported devices.
    public static func warning() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
        #else
        // No-op on platforms without UIKit haptics
        #endif
    }

    /// Triggers a standard error haptic on supported devices.
    public static func error() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
        #else
        // No-op on platforms without UIKit haptics
        #endif
    }

    /// Triggers a light impact haptic.
    public static func lightImpact() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #else
        // No-op on platforms without UIKit haptics
        #endif
    }

    /// Triggers a medium impact haptic.
    public static func mediumImpact() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #else
        // No-op on platforms without UIKit haptics
        #endif
    }

    /// Triggers a heavy impact haptic.
    public static func heavyImpact() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
        #else
        // No-op on platforms without UIKit haptics
        #endif
    }
}
