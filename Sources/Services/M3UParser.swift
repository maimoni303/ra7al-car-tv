import Foundation

/// Parses M3U / M3U8 (extended) playlists used by IPTV providers.
/// Supports: #EXTINF attributes (tvg-id, tvg-name, tvg-logo, group-title),
/// #EXTGRP group lines, plain URL-only lists, CRLF line endings, BOM,
/// and commas inside quoted attribute values.
enum M3UParser {

    struct ExtInf {
        var name: String
        var attributes: [String: String]
    }

    static func looksLikeM3U(_ text: String) -> Bool {
        let head = text.prefix(2048).uppercased()
        return head.contains("#EXTM3U") || head.contains("#EXTINF")
    }

    static func parse(_ rawText: String, playlistID: UUID) -> [Channel] {
        var text = rawText
        if text.hasPrefix("\u{FEFF}") { text.removeFirst() }

        var channels: [Channel] = []
        var pending: ExtInf?
        var pendingGroup: String?
        var seen: [String: Int] = [:]

        for raw in text.components(separatedBy: CharacterSet.newlines) {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }

            if line.uppercased().hasPrefix("#EXTINF") {
                pending = parseExtInf(line)
                continue
            }
            if line.uppercased().hasPrefix("#EXTGRP:") {
                pendingGroup = String(line.dropFirst(8)).trimmingCharacters(in: .whitespaces)
                continue
            }
            if line.hasPrefix("#") { continue }

            guard let url = URL(string: line), let scheme = url.scheme?.lowercased(),
                  ["http", "https", "rtmp", "rtsp", "rtp", "udp", "mms"].contains(scheme) else {
                pending = nil
                pendingGroup = nil
                continue
            }

            let attrs = pending?.attributes ?? [:]
            var name = pending?.name ?? ""
            if name.isEmpty { name = attrs["tvg-name"] ?? "" }
            if name.isEmpty { name = url.deletingPathExtension().lastPathComponent }
            if name.isEmpty { name = url.host ?? line }

            var group = (attrs["group-title"] ?? "").trimmingCharacters(in: .whitespaces)
            if group.isEmpty { group = pendingGroup ?? "" }

            let logo = attrs["tvg-logo"].flatMap { $0.isEmpty ? nil : URL(string: $0) }
            let tvgID = attrs["tvg-id"].flatMap { $0.isEmpty ? nil : $0 }

            let baseID = playlistID.uuidString + "|" + line
            let count = seen[baseID, default: 0]
            seen[baseID] = count + 1
            let id = count == 0 ? baseID : baseID + "#\(count)"

            channels.append(Channel(id: id, name: name, url: url, logo: logo,
                                    group: group, tvgID: tvgID, playlistID: playlistID))
            pending = nil
            pendingGroup = nil
        }
        return channels
    }

    /// `#EXTINF:-1 tvg-id="x" group-title="News, Arabic",Channel Name`
    static func parseExtInf(_ line: String) -> ExtInf {
        var inQuotes = false
        var separator: String.Index?
        // Skip "#EXTINF:" before scanning.
        let start = line.index(line.startIndex, offsetBy: min(8, line.count))
        var idx = start
        while idx < line.endIndex {
            let c = line[idx]
            if c == "\"" {
                inQuotes.toggle()
            } else if c == "," && !inQuotes {
                separator = idx
                break
            }
            idx = line.index(after: idx)
        }

        let header: Substring
        let name: String
        if let sep = separator {
            header = line[start..<sep]
            name = String(line[line.index(after: sep)...]).trimmingCharacters(in: .whitespaces)
        } else {
            header = line[start...]
            name = ""
        }
        return ExtInf(name: name, attributes: parseAttributes(String(header)))
    }

    static func parseAttributes(_ header: String) -> [String: String] {
        var result: [String: String] = [:]
        guard let regex = try? NSRegularExpression(pattern: "([A-Za-z0-9_\\-]+)\\s*=\\s*\"([^\"]*)\"") else {
            return result
        }
        let ns = header as NSString
        for match in regex.matches(in: header, range: NSRange(location: 0, length: ns.length)) {
            let key = ns.substring(with: match.range(at: 1)).lowercased()
            let value = ns.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
            result[key] = value
        }
        return result
    }
}
