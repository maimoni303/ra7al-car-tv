import SwiftUI

/// Directory of free, public playlists from the iptv-org project
/// (https://github.com/iptv-org/iptv), grouped by country, language and category.
enum IPTVDirectory {
    struct Entry: Identifiable, Hashable {
        var id: String { url }
        let name: String
        let code: String
        let url: String
        let icon: String
        var iconIsEmoji = false
    }

    struct Country: Hashable { let code: String; let en: String; let ar: String; let langs: [String] }
    struct Language: Hashable { let code: String; let en: String; let ar: String }
    struct Category: Hashable { let code: String; let en: String; let ar: String; let icon: String }

    static let base = "https://iptv-org.github.io/iptv"

    static let countries: [Country] = [
        Country(code: "sa", en: "Saudi Arabia", ar: "السعودية", langs: ["ara", "eng"]), Country(code: "ae", en: "United Arab Emirates", ar: "الإمارات", langs: ["ara", "eng"]),
        Country(code: "kw", en: "Kuwait", ar: "الكويت", langs: ["ara", "eng"]), Country(code: "qa", en: "Qatar", ar: "قطر", langs: ["ara", "eng"]),
        Country(code: "bh", en: "Bahrain", ar: "البحرين", langs: ["ara", "eng"]), Country(code: "om", en: "Oman", ar: "عُمان", langs: ["ara", "eng"]),
        Country(code: "ye", en: "Yemen", ar: "اليمن", langs: ["ara"]), Country(code: "iq", en: "Iraq", ar: "العراق", langs: ["ara", "kur"]),
        Country(code: "jo", en: "Jordan", ar: "الأردن", langs: ["ara"]), Country(code: "sy", en: "Syria", ar: "سوريا", langs: ["ara"]),
        Country(code: "lb", en: "Lebanon", ar: "لبنان", langs: ["ara", "fra"]), Country(code: "ps", en: "Palestine", ar: "فلسطين", langs: ["ara"]),
        Country(code: "eg", en: "Egypt", ar: "مصر", langs: ["ara"]), Country(code: "sd", en: "Sudan", ar: "السودان", langs: ["ara"]),
        Country(code: "ly", en: "Libya", ar: "ليبيا", langs: ["ara"]), Country(code: "tn", en: "Tunisia", ar: "تونس", langs: ["ara", "fra"]),
        Country(code: "dz", en: "Algeria", ar: "الجزائر", langs: ["ara", "fra"]), Country(code: "ma", en: "Morocco", ar: "المغرب", langs: ["ara", "fra"]),
        Country(code: "tr", en: "Turkey", ar: "تركيا", langs: ["tur"]), Country(code: "ir", en: "Iran", ar: "إيران", langs: ["fas"]),
        Country(code: "pk", en: "Pakistan", ar: "باكستان", langs: ["urd", "eng"]), Country(code: "in", en: "India", ar: "الهند", langs: ["hin", "eng"]),
        Country(code: "bd", en: "Bangladesh", ar: "بنغلاديش", langs: ["ben"]), Country(code: "id", en: "Indonesia", ar: "إندونيسيا", langs: ["ind"]),
        Country(code: "my", en: "Malaysia", ar: "ماليزيا", langs: ["msa", "eng"]), Country(code: "ph", en: "Philippines", ar: "الفلبين", langs: ["fil", "eng"]),
        Country(code: "us", en: "United States", ar: "الولايات المتحدة", langs: ["eng", "spa"]), Country(code: "gb", en: "United Kingdom", ar: "المملكة المتحدة", langs: ["eng"]),
        Country(code: "ca", en: "Canada", ar: "كندا", langs: ["eng", "fra"]), Country(code: "au", en: "Australia", ar: "أستراليا", langs: ["eng"]),
        Country(code: "fr", en: "France", ar: "فرنسا", langs: ["fra"]), Country(code: "de", en: "Germany", ar: "ألمانيا", langs: ["deu"]),
        Country(code: "es", en: "Spain", ar: "إسبانيا", langs: ["spa"]), Country(code: "it", en: "Italy", ar: "إيطاليا", langs: ["ita"]),
        Country(code: "nl", en: "Netherlands", ar: "هولندا", langs: ["nld"]), Country(code: "ru", en: "Russia", ar: "روسيا", langs: ["rus"]),
        Country(code: "br", en: "Brazil", ar: "البرازيل", langs: ["por"]), Country(code: "mx", en: "Mexico", ar: "المكسيك", langs: ["spa"]),
        Country(code: "ar", en: "Argentina", ar: "الأرجنتين", langs: ["spa"]), Country(code: "jp", en: "Japan", ar: "اليابان", langs: ["jpn"]),
        Country(code: "kr", en: "South Korea", ar: "كوريا الجنوبية", langs: ["kor"]), Country(code: "cn", en: "China", ar: "الصين", langs: ["zho"])
    ]

    static let languages: [Language] = [
        Language(code: "ara", en: "Arabic", ar: "العربية"), Language(code: "eng", en: "English", ar: "الإنجليزية"), Language(code: "fra", en: "French", ar: "الفرنسية"),
        Language(code: "spa", en: "Spanish", ar: "الإسبانية"), Language(code: "tur", en: "Turkish", ar: "التركية"), Language(code: "urd", en: "Urdu", ar: "الأردية"),
        Language(code: "hin", en: "Hindi", ar: "الهندية"), Language(code: "fas", en: "Persian", ar: "الفارسية"), Language(code: "kur", en: "Kurdish", ar: "الكردية"),
        Language(code: "deu", en: "German", ar: "الألمانية"), Language(code: "ita", en: "Italian", ar: "الإيطالية"), Language(code: "por", en: "Portuguese", ar: "البرتغالية"),
        Language(code: "rus", en: "Russian", ar: "الروسية"), Language(code: "ind", en: "Indonesian", ar: "الإندونيسية"), Language(code: "msa", en: "Malay", ar: "الملايوية"),
        Language(code: "fil", en: "Filipino", ar: "الفلبينية"), Language(code: "ben", en: "Bengali", ar: "البنغالية"), Language(code: "nld", en: "Dutch", ar: "الهولندية"),
        Language(code: "jpn", en: "Japanese", ar: "اليابانية"), Language(code: "kor", en: "Korean", ar: "الكورية"), Language(code: "zho", en: "Chinese", ar: "الصينية")
    ]

    static let categories: [Category] = [
        Category(code: "news", en: "News", ar: "أخبار", icon: "newspaper"), Category(code: "sports", en: "Sports", ar: "رياضة", icon: "sportscourt"),
        Category(code: "movies", en: "Movies", ar: "أفلام", icon: "film"), Category(code: "series", en: "Series", ar: "مسلسلات", icon: "tv"),
        Category(code: "entertainment", en: "Entertainment", ar: "ترفيه", icon: "popcorn"), Category(code: "kids", en: "Kids", ar: "أطفال", icon: "figure.and.child.holdinghands"),
        Category(code: "animation", en: "Animation", ar: "رسوم متحركة", icon: "sparkles"), Category(code: "documentary", en: "Documentary", ar: "وثائقي", icon: "globe.europe.africa"),
        Category(code: "religious", en: "Religious", ar: "ديني", icon: "book"), Category(code: "music", en: "Music", ar: "موسيقى", icon: "music.note"),
        Category(code: "education", en: "Education", ar: "تعليم", icon: "graduationcap"), Category(code: "cooking", en: "Cooking", ar: "طبخ", icon: "fork.knife"),
        Category(code: "travel", en: "Travel", ar: "سفر", icon: "airplane"), Category(code: "outdoor", en: "Outdoor", ar: "برّية", icon: "mountain.2"),
        Category(code: "auto", en: "Auto", ar: "سيارات", icon: "car"), Category(code: "business", en: "Business", ar: "أعمال", icon: "chart.line.uptrend.xyaxis"),
        Category(code: "science", en: "Science", ar: "علوم", icon: "atom"), Category(code: "weather", en: "Weather", ar: "طقس", icon: "cloud.sun"),
        Category(code: "general", en: "General", ar: "عام", icon: "square.grid.2x2"), Category(code: "family", en: "Family", ar: "عائلي", icon: "house"),
        Category(code: "culture", en: "Culture", ar: "ثقافة", icon: "building.columns"), Category(code: "comedy", en: "Comedy", ar: "كوميديا", icon: "face.smiling"),
        Category(code: "classic", en: "Classic", ar: "كلاسيكي", icon: "clock"), Category(code: "lifestyle", en: "Lifestyle", ar: "أسلوب حياة", icon: "heart"),
        Category(code: "shop", en: "Shopping", ar: "تسوّق", icon: "bag")
    ]

    static func name(_ en: String, _ ar: String) -> String { L10n.current == "ar" ? ar : en }

    static func flag(_ code: String) -> String {
        code.uppercased().unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) }
            .map(String.init).joined()
    }

    static func countryEntry(_ c: Country) -> Entry {
        Entry(name: name(c.en, c.ar), code: c.code.uppercased(), url: "\(base)/countries/\(c.code).m3u", icon: flag(c.code), iconIsEmoji: true)
    }

    static func languageEntry(_ code: String) -> Entry? {
        guard let l = languages.first(where: { $0.code == code }) else { return nil }
        return Entry(name: name(l.en, l.ar), code: l.code.uppercased(), url: "\(base)/languages/\(l.code).m3u", icon: "character.bubble")
    }

    static var categoryEntries: [Entry] {
        categories.map { Entry(name: name($0.en, $0.ar), code: $0.code.uppercased(),
                               url: "\(base)/categories/\($0.code).m3u", icon: $0.icon) }
    }
}

struct FindLinksView: View {
    @EnvironmentObject var store: PlaylistStore
    @Environment(\.dismiss) private var dismiss
    var onPick: (String) -> Void

    enum Tab: String, CaseIterable { case forYou, countries, languages, categories }
    @State private var tab: Tab = .forYou
    @State private var query = ""
    @State private var countryCode = (Locale.current.region?.identifier ?? "SA").lowercased()
    @State private var copied: String?
    @State private var adding: String?
    @State private var added: Set<String> = []
    @State private var errorText: String?

    private var country: IPTVDirectory.Country {
        IPTVDirectory.countries.first { $0.code == countryCode } ?? IPTVDirectory.countries[0]
    }

    private var list: [IPTVDirectory.Entry] {
        let all: [IPTVDirectory.Entry]
        switch tab {
        case .forYou:
            all = [IPTVDirectory.countryEntry(country)]
                + country.langs.compactMap(IPTVDirectory.languageEntry)
                + Array(IPTVDirectory.categoryEntries.prefix(8))
        case .countries: all = IPTVDirectory.countries.map(IPTVDirectory.countryEntry)
        case .languages: all = IPTVDirectory.languages.compactMap { IPTVDirectory.languageEntry($0.code) }
        case .categories: all = IPTVDirectory.categoryEntries
        }
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(q) || $0.code.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                recommendedCard
                SearchField(prompt: L10n.t("find.search"), text: $query)
                Picker("", selection: $tab) {
                    Text(L10n.t("find.forYou")).tag(Tab.forYou)
                    Text(L10n.t("find.countries")).tag(Tab.countries)
                    Text(L10n.t("find.languages")).tag(Tab.languages)
                    Text(L10n.t("find.categories")).tag(Tab.categories)
                }
                .pickerStyle(.segmented)

                ForEach(list) { e in entryCard(e) }
                Text(L10n.t("find.credit")).font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(L10n.t("add.findLinks"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.t("common.error"), isPresented: Binding(get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
            Button(L10n.t("common.ok")) { errorText = nil }
        } message: { Text(errorText ?? "") }
    }

    private var header: some View {
        HStack {
            Label("RA7AL Playlists", systemImage: "car.fill").font(.headline)
            Spacer()
            Menu {
                Picker("", selection: $countryCode) {
                    ForEach(IPTVDirectory.countries, id: \.self) { c in
                        Text("\(IPTVDirectory.flag(c.code)) \(IPTVDirectory.name(c.en, c.ar))").tag(c.code)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Circle().fill(Brand.accent).frame(width: 8, height: 8)
                    Text("\(IPTVDirectory.flag(country.code)) \(IPTVDirectory.name(country.en, country.ar))")
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.down").font(.caption)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground), in: Capsule())
            }
        }
    }

    private var recommendedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            (Text(L10n.t("find.recommended") + " ") + Text(IPTVDirectory.name(country.en, country.ar)).foregroundColor(Brand.accent))
                .font(.title2.bold())
            Text(L10n.t("find.recommendedBody")).font(.subheadline).foregroundStyle(.secondary)
            entryCard(IPTVDirectory.countryEntry(country), highlighted: true)
            ForEach(country.langs.compactMap(IPTVDirectory.languageEntry)) { e in entryCard(e) }
        }
    }

    private func entryCard(_ e: IPTVDirectory.Entry, highlighted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if e.iconIsEmoji {
                    Text(e.icon).font(.title)
                } else {
                    Image(systemName: e.icon).font(.title2).foregroundStyle(Brand.accent).frame(width: 34)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(e.name).font(.headline)
                    Text(e.code).font(.caption.bold()).foregroundStyle(Brand.accent)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Brand.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 5))
                }
                Spacer()
            }
            Text(e.url).font(.system(.footnote, design: .monospaced)).lineLimit(1).truncationMode(.tail)
                .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
            HStack(spacing: 10) {
                Button {
                    UIPasteboard.general.string = e.url
                    onPick(e.url)
                    copied = e.url
                } label: {
                    Label(L10n.t(copied == e.url ? "find.copied" : "find.copy"),
                          systemImage: copied == e.url ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                Button { add(e) } label: {
                    Group {
                        if adding == e.url { ProgressView().tint(.white) }
                        else { Label(L10n.t(added.contains(e.url) ? "find.added" : "common.add"),
                                     systemImage: added.contains(e.url) ? "checkmark" : "plus") }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(Brand.accent, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(adding != nil || added.contains(e.url))
            }
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(highlighted ? Brand.accent : .clear, lineWidth: 1.5))
    }

    private func add(_ e: IPTVDirectory.Entry) {
        adding = e.url
        Task {
            do {
                try await store.addPlaylist(name: e.name, urlString: e.url)
                added.insert(e.url)
            } catch {
                errorText = error.localizedDescription
            }
            adding = nil
        }
    }
}
