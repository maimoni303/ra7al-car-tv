import SwiftUI

/// App-wide settings: language, appearance and ad blocking.
@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    private let defaults = UserDefaults.standard

    /// "system" | "ar" | "en"
    @Published var language: String {
        didSet { defaults.set(language, forKey: "lang"); L10n.current = resolvedLanguage }
    }
    /// "system" | "light" | "dark"
    @Published var appearance: String {
        didSet { defaults.set(appearance, forKey: "appearance") }
    }
    @Published var blockAds: Bool {
        didSet { defaults.set(blockAds, forKey: "blockAds") }
    }

    init() {
        language = defaults.string(forKey: "lang") ?? "system"
        appearance = defaults.string(forKey: "appearance") ?? "system"
        blockAds = defaults.object(forKey: "blockAds") as? Bool ?? true
        L10n.current = resolvedLanguage
    }

    var resolvedLanguage: String {
        if language == "system" {
            return Locale.preferredLanguages.first?.hasPrefix("ar") == true ? "ar" : "en"
        }
        return language
    }

    var colorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var layoutDirection: LayoutDirection { resolvedLanguage == "ar" ? .rightToLeft : .leftToRight }
    var locale: Locale { Locale(identifier: resolvedLanguage) }

    func label(forLanguage value: String) -> String {
        switch value {
        case "ar": return "العربية"
        case "en": return "English"
        default: return L10n.t("common.system")
        }
    }

    func label(forAppearance value: String) -> String {
        switch value {
        case "light": return L10n.t("settings.light")
        case "dark": return L10n.t("settings.dark")
        default: return L10n.t("common.system")
        }
    }
}

/// Car connection state shared between the CarPlay scene and the phone UI.
@MainActor
final class CarState: ObservableObject {
    static let shared = CarState()
    @Published var connected = false
    @Published var videoWindowAvailable = false
    @Published var mirroring = false
}

enum Brand {
    static let accent = Color(red: 0.345, green: 0.733, blue: 0.239)   // #58BB3D
    static let appGroup = "group.com.ra7al.cartv"
    static let supportEmail = "ra7al.server@gmail.com"
    static let whatsapp = "966555588921"
}
