package com.ra7al.cartv.data

import kotlinx.serialization.Serializable

@Serializable
data class Channel(
    val id: String,
    val name: String,
    val url: String,
    val logo: String? = null,
    val group: String = "",
    val tvgId: String? = null,
    val playlistId: String,
) {
    val key: String get() = url
}

@Serializable
data class Playlist(
    val id: String,
    val name: String,
    val sourceUrl: String? = null,
    val isLocal: Boolean = false,
    val channelCount: Int = 0,
    val lastUpdated: Long = System.currentTimeMillis(),
    val lastError: String? = null,
    val lastChecked: Long? = null,
)

data class ChannelGroup(val name: String, val channels: List<Channel>)

/** Same rules as the iPhone parser (M3UParser.swift). */
object M3uParser {
    private val schemes = setOf("http", "https", "rtmp", "rtsp", "rtp", "udp", "mms")
    private val attr = Regex("""([A-Za-z0-9_\-]+)\s*=\s*"([^"]*)"""")
    private val schemeRx = Regex("""^([A-Za-z][A-Za-z0-9+.\-]*):""")

    fun looksLikeM3u(text: String): Boolean {
        val head = text.take(2048).uppercase()
        return head.contains("#EXTM3U") || head.contains("#EXTINF")
    }

    fun parse(raw: String, playlistId: String): List<Channel> {
        val text = raw.removePrefix("﻿")
        val out = ArrayList<Channel>()
        var pending: Pair<String, Map<String, String>>? = null
        var pendingGroup: String? = null
        val seen = HashMap<String, Int>()

        for (rawLine in text.split("\r\n", "\n", "\r")) {
            val line = rawLine.trim()
            if (line.isEmpty()) continue
            val upper = line.uppercase()
            if (upper.startsWith("#EXTINF")) { pending = parseExtInf(line); continue }
            if (upper.startsWith("#EXTGRP:")) { pendingGroup = line.substring(8).trim(); continue }
            if (line.startsWith("#")) continue

            val scheme = schemeRx.find(line)?.groupValues?.get(1)?.lowercase()
            if (scheme == null || scheme !in schemes || line.contains(' ')) {
                pending = null; pendingGroup = null; continue
            }
            val attrs = pending?.second ?: emptyMap()
            var name = pending?.first.orEmpty()
            if (name.isEmpty()) name = attrs["tvg-name"].orEmpty()
            if (name.isEmpty()) {
                val last = line.trimEnd('/').substringAfterLast('/').substringBefore('?')
                name = if (last.contains('.')) last.substringBeforeLast('.') else last
            }
            if (name.isEmpty()) name = line

            var group = attrs["group-title"].orEmpty().trim()
            if (group.isEmpty()) group = pendingGroup.orEmpty()

            val base = "$playlistId|$line"
            val n = seen.getOrDefault(base, 0)
            seen[base] = n + 1
            out += Channel(
                id = if (n == 0) base else "$base#$n",
                name = name,
                url = line,
                logo = attrs["tvg-logo"]?.takeIf { it.isNotEmpty() },
                group = group,
                tvgId = attrs["tvg-id"]?.takeIf { it.isNotEmpty() },
                playlistId = playlistId,
            )
            pending = null; pendingGroup = null
        }
        return out
    }

    fun parseExtInf(line: String): Pair<String, Map<String, String>> {
        val start = minOf(8, line.length)
        var inQuotes = false
        var sep = -1
        for (i in start until line.length) {
            val c = line[i]
            if (c == '"') inQuotes = !inQuotes
            else if (c == ',' && !inQuotes) { sep = i; break }
        }
        val header = if (sep >= 0) line.substring(start, sep) else line.substring(start)
        val name = if (sep >= 0) line.substring(sep + 1).trim() else ""
        val map = attr.findAll(header).associate { it.groupValues[1].lowercase() to it.groupValues[2].trim() }
        return name to map
    }

    /** Groups channels by category; "A;B" puts a channel in both. */
    fun group(channels: List<Channel>, other: String): List<ChannelGroup> {
        val order = ArrayList<String>()
        val buckets = HashMap<String, MutableList<Channel>>()
        for (c in channels) {
            val parts = c.group.split(';').map { it.trim() }.filter { it.isNotEmpty() }.ifEmpty { listOf(other) }
            for (g in parts) {
                val list = buckets.getOrPut(g) { order += g; ArrayList() }
                list += c
            }
        }
        return order.map { ChannelGroup(it, buckets[it].orEmpty()) }
    }
}
