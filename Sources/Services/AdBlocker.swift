import WebKit

/// Compiles a WebKit content-blocking rule list for common ad and tracker hosts.
@MainActor
enum AdBlocker {
    private static var cached: WKContentRuleList?

    private static let hosts = [
        "doubleclick.net", "googlesyndication.com", "googleadservices.com", "adservice.google.com",
        "google-analytics.com", "googletagservices.com", "adnxs.com", "adsrvr.org", "taboola.com",
        "outbrain.com", "criteo.com", "criteo.net", "pubmatic.com", "rubiconproject.com",
        "openx.net", "amazon-adsystem.com", "moatads.com", "scorecardresearch.com", "zedo.com",
        "popads.net", "popcash.net", "propellerads.com", "adsterra.com", "exoclick.com",
        "juicyads.com", "mgid.com", "revcontent.com", "advertising.com", "yieldmo.com",
        "smartadserver.com", "teads.tv", "media.net", "quantserve.com", "hotjar.com"
    ]

    static func ruleJSON() -> String {
        var rules: [[String: Any]] = hosts.map { host in
            let escaped = host.replacingOccurrences(of: ".", with: "\\.")
            return ["trigger": ["url-filter": "^https?://([^/]+\\.)?" + escaped + "[:/]"],
                    "action": ["type": "block"]]
        }
        rules.append(["trigger": ["url-filter": ".*"],
                      "action": ["type": "css-display-none",
                                 "selector": ".ad, .ads, .adsbygoogle, [id^='google_ads'], [class*='ad-banner'], [id*='ad-container']"]])
        let data = (try? JSONSerialization.data(withJSONObject: rules)) ?? Data("[]".utf8)
        return String(decoding: data, as: UTF8.self)
    }

    static func apply(to controller: WKUserContentController, enabled: Bool) async {
        controller.removeAllContentRuleLists()
        guard enabled else { return }
        if cached == nil {
            cached = try? await WKContentRuleListStore.default()
                .compileContentRuleList(forIdentifier: "ra7al-adblock", encodedContentRuleList: ruleJSON())
        }
        if let list = cached { controller.add(list) }
    }
}
