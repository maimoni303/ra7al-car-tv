import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: PlaylistStore
    @Environment(\.openURL) private var openURL

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section(L10n.t("settings.media")) {
                    NavigationLink { ManageSourcesView() } label: {
                        SettingsRow(icon: "antenna.radiowaves.left.and.right",
                                    title: L10n.t("sources.title"),
                                    subtitle: store.playlists.isEmpty ? L10n.t("sources.none")
                                        : store.playlists.map(\.name).joined(separator: " · "),
                                    showsChevron: false)
                    }
                }

                Section(L10n.t("settings.preferences")) {
                    NavigationLink { AppearancePicker() } label: {
                        SettingsRow(icon: "iphone", title: L10n.t("settings.appearance"),
                                    value: settings.label(forAppearance: settings.appearance), showsChevron: false)
                    }
                    NavigationLink { LanguagePicker() } label: {
                        SettingsRow(icon: "globe", title: L10n.t("settings.language"),
                                    value: settings.label(forLanguage: settings.language), showsChevron: false)
                    }
                    Toggle(isOn: $settings.blockAds) {
                        SettingsRow(icon: "hand.raised", title: L10n.t("settings.blockAds"), showsChevron: false)
                    }
                    .tint(Brand.accent)
                }

                Section(L10n.t("settings.about")) {
                    ShareLink(item: L10n.t("settings.shareText")) {
                        SettingsRow(icon: "square.and.arrow.up", title: L10n.t("settings.share"))
                    }
                    Button { mail(subject: "RA7AL Car TV – Review") } label: {
                        SettingsRow(icon: "star", title: L10n.t("settings.review"))
                    }
                    Button { mail(subject: "RA7AL Car TV – Support") } label: {
                        SettingsRow(icon: "envelope", title: L10n.t("settings.contact"), subtitle: Brand.supportEmail)
                    }
                    Button { whatsapp() } label: {
                        SettingsRow(icon: "bubble.left.and.bubble.right", title: L10n.t("settings.whatsapp"),
                                    subtitle: L10n.t("settings.whatsappBody"))
                    }
                }

                Section(L10n.t("settings.legal")) {
                    NavigationLink { InfoPage(titleKey: "settings.privacy", bodyKey: "legal.privacy") } label: {
                        SettingsRow(icon: "hand.raised", title: L10n.t("settings.privacy"), showsChevron: false)
                    }
                    NavigationLink { InfoPage(titleKey: "settings.terms", bodyKey: "legal.terms") } label: {
                        SettingsRow(icon: "doc.text", title: L10n.t("settings.terms"), showsChevron: false)
                    }
                }

                Section {
                    Text("RA7AL Car TV · \(L10n.t("settings.version")) \(version)")
                        .font(.footnote).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.insetGrouped)
            .listRowSpacing(0)
            .navigationTitle(L10n.t("tab.settings"))
        }
    }

    private func mail(subject: String) {
        var c = URLComponents()
        c.scheme = "mailto"
        c.path = Brand.supportEmail
        c.queryItems = [URLQueryItem(name: "subject", value: subject)]
        if let u = c.url { openURL(u) }
    }

    private func whatsapp() {
        if let u = URL(string: "https://wa.me/\(Brand.whatsapp)") { openURL(u) }
    }
}

struct AppearancePicker: View {
    @EnvironmentObject var settings: AppSettings
    var body: some View {
        List {
            ForEach(["system", "light", "dark"], id: \.self) { v in
                Button { settings.appearance = v } label: {
                    HStack {
                        Text(settings.label(forAppearance: v)).foregroundStyle(.primary)
                        Spacer()
                        if settings.appearance == v { Image(systemName: "checkmark").foregroundStyle(Brand.accent) }
                    }
                }
            }
        }
        .navigationTitle(L10n.t("settings.appearance"))
    }
}

struct LanguagePicker: View {
    @EnvironmentObject var settings: AppSettings
    var body: some View {
        List {
            ForEach(["system", "ar", "en"], id: \.self) { v in
                Button { settings.language = v } label: {
                    HStack {
                        Text(settings.label(forLanguage: v)).foregroundStyle(.primary)
                        Spacer()
                        if settings.language == v { Image(systemName: "checkmark").foregroundStyle(Brand.accent) }
                    }
                }
            }
        }
        .navigationTitle(L10n.t("settings.language"))
    }
}

struct InfoPage: View {
    let titleKey: String
    let bodyKey: String
    var body: some View {
        ScrollView {
            Text(L10n.t(bodyKey)).font(.body).lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle(L10n.t(titleKey))
        .navigationBarTitleDisplayMode(.inline)
    }
}
