import XCTest
@testable import RA7ALCarTV

final class M3UParserTests: XCTestCase {
    let pid = UUID()

    func testExtendedPlaylist() {
        let text = """
        #EXTM3U x-tvg-url="http://epg.example/guide.xml"
        #EXTINF:-1 tvg-id="AlArabiya.ae" tvg-logo="http://logo/a.png" group-title="News",Al Arabiya (1080p)
        http://stream.example/arabiya.m3u8
        #EXTINF:-1 tvg-id="X" group-title="Movies;Entertainment",Top Gear (720p)
        #EXTVLCOPT:http-user-agent=Mozilla
        https://stream.example/topgear.m3u8
        """
        let ch = M3UParser.parse(text, playlistID: pid)
        XCTAssertEqual(ch.count, 2)
        XCTAssertEqual(ch[0].name, "Al Arabiya (1080p)")
        XCTAssertEqual(ch[0].group, "News")
        XCTAssertEqual(ch[0].logo?.absoluteString, "http://logo/a.png")
        XCTAssertEqual(ch[0].tvgID, "AlArabiya.ae")
        XCTAssertEqual(ch[1].group, "Movies;Entertainment")
    }

    func testCommaInsideQuotedAttribute() {
        let text = "#EXTM3U\n#EXTINF:-1 group-title=\"News, Arabic\" tvg-name=\"N\",Name, With Comma\nhttp://a/b.ts"
        let ch = M3UParser.parse(text, playlistID: pid)
        XCTAssertEqual(ch.first?.group, "News, Arabic")
        XCTAssertEqual(ch.first?.name, "Name, With Comma")
    }

    func testCRLFBomAndExtGrp() {
        let text = "\u{FEFF}#EXTM3U\r\n#EXTINF:0,Ch1\r\n#EXTGRP:Sports\r\nhttp://a/1.m3u8\r\n"
        let ch = M3UParser.parse(text, playlistID: pid)
        XCTAssertEqual(ch.count, 1)
        XCTAssertEqual(ch[0].name, "Ch1")
        XCTAssertEqual(ch[0].group, "Sports")
    }

    func testPlainUrlListAndInvalidLines() {
        let text = "http://a/live/news.m3u8\nnot a url\nftp://x/y\nhttps://b/sports.ts"
        let ch = M3UParser.parse(text, playlistID: pid)
        XCTAssertEqual(ch.map(\.name), ["news", "sports"])
    }

    func testDuplicateUrlsGetUniqueIDs() {
        let text = "#EXTM3U\n#EXTINF:-1,A\nhttp://a/1\n#EXTINF:-1,B\nhttp://a/1"
        let ch = M3UParser.parse(text, playlistID: pid)
        XCTAssertEqual(Set(ch.map(\.id)).count, 2)
    }

    func testNameFallsBackToTvgName() {
        let text = "#EXTM3U\n#EXTINF:-1 tvg-name=\"Backup\",\nhttp://a/1"
        XCTAssertEqual(M3UParser.parse(text, playlistID: pid).first?.name, "Backup")
    }

    func testLooksLikeM3U() {
        XCTAssertTrue(M3UParser.looksLikeM3U("#EXTM3U\n"))
        XCTAssertFalse(M3UParser.looksLikeM3U("<html></html>"))
    }

    func testBrowserResolve() {
        XCTAssertEqual(BrowserStore.resolve("netflix.com")?.absoluteString, "https://netflix.com")
        XCTAssertEqual(BrowserStore.resolve("https://x.y/z")?.absoluteString, "https://x.y/z")
        XCTAssertEqual(BrowserStore.resolve("car tv")?.host, "www.google.com")
        XCTAssertNil(BrowserStore.resolve("   "))
    }

    func testEveryKeyHasBothLanguages() {
        XCTAssertEqual(Set(L10n.en.keys), Set(L10n.ar.keys))
    }
}
