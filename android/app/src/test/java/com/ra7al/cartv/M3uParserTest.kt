package com.ra7al.cartv

import com.ra7al.cartv.data.M3uParser
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class M3uParserTest {
    @Test fun extendedPlaylist() {
        val ch = M3uParser.parse("""#EXTM3U
#EXTINF:-1 tvg-id="A" tvg-logo="http://logo/a.png" group-title="News",Al Arabiya (1080p)
http://s/a.m3u8
#EXTINF:-1 group-title="Movies;Entertainment",Top Gear (720p)
#EXTVLCOPT:x=y
https://s/t.m3u8""", "p")
        assertEquals(2, ch.size)
        assertEquals("Al Arabiya (1080p)", ch[0].name)
        assertEquals("News", ch[0].group)
        assertEquals("http://logo/a.png", ch[0].logo)
        val groups = M3uParser.group(ch, "Other")
        assertEquals(listOf("News", "Movies", "Entertainment"), groups.map { it.name })
    }

    @Test fun commaInsideQuotes() {
        val ch = M3uParser.parse("#EXTM3U\n#EXTINF:-1 group-title=\"News, Arabic\",Name, With Comma\nhttp://a/b.ts", "p")
        assertEquals("News, Arabic", ch[0].group)
        assertEquals("Name, With Comma", ch[0].name)
    }

    @Test fun crlfBomExtGrp() {
        val ch = M3uParser.parse("﻿#EXTM3U\r\n#EXTINF:0,Ch1\r\n#EXTGRP:Sports\r\nhttp://a/1.m3u8\r\n", "p")
        assertEquals(1, ch.size)
        assertEquals("Sports", ch[0].group)
    }

    @Test fun plainUrlsAndInvalidLines() {
        val ch = M3uParser.parse("http://a/live/news.m3u8\nnot a url\nftp://x/y\nhttps://b/sports.ts", "p")
        assertEquals(listOf("news", "sports"), ch.map { it.name })
    }

    @Test fun duplicateIdsAreUnique() {
        val ch = M3uParser.parse("#EXTM3U\n#EXTINF:-1,A\nhttp://a/1\n#EXTINF:-1,B\nhttp://a/1", "p")
        assertEquals(2, ch.map { it.id }.toSet().size)
    }

    @Test fun detectsM3u() {
        assertTrue(M3uParser.looksLikeM3u("#EXTM3U\n"))
        assertFalse(M3uParser.looksLikeM3u("<html>"))
    }

    @Test fun stringsHaveBothLanguages() {
        assertEquals(com.ra7al.cartv.ui.L10n.keysEn, com.ra7al.cartv.ui.L10n.keysAr)
    }
}
