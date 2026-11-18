package com.ra7al.cartv.data

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import com.ra7al.cartv.ui.L10n
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.util.UUID

class SourceException(message: String) : Exception(message)

private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

/** Sources (M3U playlists), favorites and history — stored as JSON files in the app folder. */
class PlaylistStore(private val context: Context) {
    private val dir = File(context.filesDir, "store").apply { mkdirs() }

    private val _playlists = MutableStateFlow<List<Playlist>>(emptyList())
    val playlists: StateFlow<List<Playlist>> = _playlists
    private val _channels = MutableStateFlow<Map<String, List<Channel>>>(emptyMap())
    val channels: StateFlow<Map<String, List<Channel>>> = _channels
    private val _favorites = MutableStateFlow<List<String>>(emptyList())
    val favorites: StateFlow<List<String>> = _favorites
    private val _recents = MutableStateFlow<List<String>>(emptyList())
    val recents: StateFlow<List<String>> = _recents
    val selected = MutableStateFlow<String?>(null)

    init {
        _playlists.value = read("playlists.json") ?: emptyList()
        _favorites.value = read("favorites.json") ?: emptyList()
        _recents.value = read("recents.json") ?: emptyList()
        _channels.value = _playlists.value.associate { it.id to (read<List<Channel>>("channels-${it.id}.json") ?: emptyList()) }
    }

    fun visibleChannels(): List<Channel> {
        val sel = selected.value
        return if (sel != null) _channels.value[sel].orEmpty()
        else _playlists.value.flatMap { _channels.value[it.id].orEmpty() }
    }

    fun allChannels(): List<Channel> = _playlists.value.flatMap { _channels.value[it.id].orEmpty() }
    fun count(p: Playlist) = _channels.value[p.id]?.size ?: 0
    fun total() = _playlists.value.sumOf { count(it) }

    fun search(q: String, list: List<Channel>): List<Channel> {
        val t = q.trim()
        if (t.isEmpty()) return list
        return list.filter { it.name.contains(t, ignoreCase = true) || it.group.contains(t, ignoreCase = true) }
    }

    fun favoriteChannels(): List<Channel> {
        val index = allChannels().associateBy { it.key }
        return _favorites.value.mapNotNull { index[it] }
    }

    fun isFavorite(c: Channel) = _favorites.value.contains(c.key)

    fun toggleFavorite(c: Channel) {
        val f = _favorites.value.toMutableList()
        if (!f.remove(c.key)) f += c.key
        _favorites.value = f
        write("favorites.json", f)
    }

    fun markWatched(c: Channel) {
        val r = _recents.value.toMutableList()
        r.remove(c.key); r.add(0, c.key)
        _recents.value = r.take(30)
        write("recents.json", _recents.value)
    }

    /** Link or pasted M3U content, like the iPhone "Add a Source" screen. */
    suspend fun addSource(input: String, name: String = ""): Playlist {
        val trimmed = input.trim()
        if (trimmed.isEmpty()) throw SourceException(L10n.t("err.invalidURL"))
        if (M3uParser.looksLikeM3u(trimmed)) {
            val id = UUID.randomUUID().toString()
            val list = parseOrThrow(trimmed, id)
            val p = Playlist(id, name.ifEmpty { "${L10n.t("playlist.default")} ${_playlists.value.size + 1}" },
                null, true, list.size)
            commit(p, list)
            return p
        }
        val first = trimmed.lines().first().trim()
        var derived = name
        if (derived.isEmpty()) {
            derived = runCatching { Uri.parse(first).lastPathSegment?.substringBeforeLast('.') }.getOrNull().orEmpty()
            if (derived.isEmpty()) derived = Uri.parse(first).host.orEmpty()
        }
        return addFromUrl(derived, first)
    }

    suspend fun addFromUrl(name: String, url: String): Playlist {
        val scheme = Uri.parse(url).scheme?.lowercase()
        if (scheme != "http" && scheme != "https") throw SourceException(L10n.t("err.invalidURL"))
        val text = download(url)
        val id = UUID.randomUUID().toString()
        val list = parseOrThrow(text, id)
        val p = Playlist(id, name.ifEmpty { Uri.parse(url).host ?: L10n.t("playlist.default") }, url, false, list.size)
        commit(p, list)
        return p
    }

    suspend fun importFile(uri: Uri): Playlist = withContext(Dispatchers.IO) {
        val text = context.contentResolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() }
            ?: throw SourceException(L10n.t("err.notM3U"))
        val id = UUID.randomUUID().toString()
        val list = parseOrThrow(text, id)
        val p = Playlist(id, displayName(uri)?.substringBeforeLast('.') ?: L10n.t("playlist.default"), null, true, list.size)
        withContext(Dispatchers.Main) { commit(p, list) }
        p
    }

    suspend fun refresh(p: Playlist) {
        val url = p.sourceUrl ?: return
        val list = parseOrThrow(download(url), p.id)
        val now = System.currentTimeMillis()
        val latest = _playlists.value.firstOrNull { it.id == p.id } ?: p
        commit(latest.copy(channelCount = list.size, lastUpdated = now, lastChecked = now, lastError = null), list)
    }

    @Volatile private var checking = false

    /** Daily check: re-downloads link sources not checked in 24 h and flags broken links. */
    suspend fun refreshDueSources(force: Boolean = false) {
        if (checking) return
        checking = true
        try {
            val day = 24L * 60 * 60 * 1000
            for (p in _playlists.value.filter { !it.isLocal && it.sourceUrl != null }) {
                val last = p.lastChecked ?: p.lastUpdated
                if (!force && System.currentTimeMillis() - last < day) continue
                try { refresh(p) } catch (e: Exception) {
                    _playlists.value = _playlists.value.map {
                        if (it.id == p.id) it.copy(lastError = e.message ?: L10n.t("common.error"), lastChecked = System.currentTimeMillis()) else it
                    }
                    write("playlists.json", _playlists.value)
                }
            }
        } finally { checking = false }
    }

    fun rename(p: Playlist, name: String) {
        if (name.isBlank()) return
        _playlists.value = _playlists.value.map { if (it.id == p.id) it.copy(name = name.trim()) else it }
        write("playlists.json", _playlists.value)
    }

    fun delete(p: Playlist) {
        _playlists.value = _playlists.value.filterNot { it.id == p.id }
        _channels.value = _channels.value - p.id
        if (selected.value == p.id) selected.value = null
        File(dir, "channels-${p.id}.json").delete()
        write("playlists.json", _playlists.value)
    }

    private fun parseOrThrow(text: String, id: String): List<Channel> {
        val list = M3uParser.parse(text, id)
        if (list.isEmpty()) {
            throw SourceException(L10n.t(if (M3uParser.looksLikeM3u(text)) "err.empty" else "err.notM3U"))
        }
        return list
    }

    private suspend fun download(url: String): String = withContext(Dispatchers.IO) {
        val conn = URL(url).openConnection() as HttpURLConnection
        conn.connectTimeout = 30_000
        conn.readTimeout = 60_000
        conn.instanceFollowRedirects = true
        conn.setRequestProperty("User-Agent", "RA7AL-CarTV/1.0")
        try {
            val code = conn.responseCode
            if (code !in 200..299) throw SourceException("${L10n.t("err.http")} ($code)")
            conn.inputStream.bufferedReader().use { it.readText() }
        } finally { conn.disconnect() }
    }

    private fun commit(p: Playlist, list: List<Channel>) {
        val cur = _playlists.value.toMutableList()
        val i = cur.indexOfFirst { it.id == p.id }
        if (i >= 0) cur[i] = p else cur += p
        _channels.value = _channels.value + (p.id to list)
        _playlists.value = cur
        write("playlists.json", cur)
        write("channels-${p.id}.json", list)
    }

    private fun displayName(uri: Uri): String? =
        context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) it.getString(0) else null
        }

    private inline fun <reified T> read(name: String): T? =
        runCatching { json.decodeFromString<T>(File(dir, name).readText()) }.getOrNull()

    private inline fun <reified T> write(name: String, value: T) {
        runCatching {
            val tmp = File(dir, "$name.tmp")
            tmp.writeText(json.encodeToString(value))
            tmp.renameTo(File(dir, name))
        }
    }
}

@Serializable
data class LocalVideo(val id: String, val title: String, val fileName: String, val added: Long, val durationMs: Long = 0)

/** Videos imported from the gallery or files, copied into the app. */
class LibraryStore(private val context: Context) {
    val folder = File(context.filesDir, "videos").apply { mkdirs() }
    private val index = File(folder, "library.json")
    private val _videos = MutableStateFlow<List<LocalVideo>>(emptyList())
    val videos: StateFlow<List<LocalVideo>> = _videos

    init {
        _videos.value = runCatching { json.decodeFromString<List<LocalVideo>>(index.readText()) }.getOrDefault(emptyList())
            .filter { File(folder, it.fileName).exists() }
    }

    fun file(v: LocalVideo) = File(folder, v.fileName)

    suspend fun import(uri: Uri) = withContext(Dispatchers.IO) {
        val name = context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) it.getString(0) else null
        } ?: "video.mp4"
        val ext = name.substringAfterLast('.', "mp4")
        val id = UUID.randomUUID().toString()
        val dest = File(folder, "$id.$ext")
        context.contentResolver.openInputStream(uri)?.use { input -> dest.outputStream().use { input.copyTo(it) } }
        val duration = runCatching {
            val r = android.media.MediaMetadataRetriever()
            r.setDataSource(dest.absolutePath)
            val d = r.extractMetadata(android.media.MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLong() ?: 0
            r.release(); d
        }.getOrDefault(0)
        val v = LocalVideo(id, name.substringBeforeLast('.'), dest.name, System.currentTimeMillis(), duration)
        withContext(Dispatchers.Main) {
            _videos.value = listOf(v) + _videos.value
            save()
        }
    }

    fun rename(v: LocalVideo, title: String) {
        if (title.isBlank()) return
        _videos.value = _videos.value.map { if (it.id == v.id) it.copy(title = title.trim()) else it }
        save()
    }

    fun delete(v: LocalVideo) {
        file(v).delete()
        _videos.value = _videos.value.filterNot { it.id == v.id }
        save()
    }

    fun asChannel(v: LocalVideo) = Channel("local|${v.id}", v.title, Uri.fromFile(file(v)).toString(),
        null, L10n.t("tab.library"), null, v.id)

    private fun save() { runCatching { index.writeText(json.encodeToString(_videos.value)) } }
}

@Serializable
data class Site(val title: String, val url: String)

class BrowserStore(context: Context) {
    private val prefs = context.getSharedPreferences("browser", Context.MODE_PRIVATE)
    private val _recents = MutableStateFlow<List<Site>>(emptyList())
    val recents: StateFlow<List<Site>> = _recents
    private val _last = MutableStateFlow<Site?>(null)
    val last: StateFlow<Site?> = _last
    private val _tabs = MutableStateFlow<List<Site>>(emptyList())
    val tabs: StateFlow<List<Site>> = _tabs

    init {
        _recents.value = prefs.getString("recents", null)?.let { runCatching { json.decodeFromString<List<Site>>(it) }.getOrNull() } ?: emptyList()
        _last.value = prefs.getString("last", null)?.let { runCatching { json.decodeFromString<Site>(it) }.getOrNull() }
        _tabs.value = prefs.getString("tabs", null)?.let { runCatching { json.decodeFromString<List<Site>>(it) }.getOrNull() } ?: emptyList()
    }

    fun visited(s: Site) {
        _last.value = s
        val host = Uri.parse(s.url).host
        _recents.value = (listOf(s) + _recents.value.filterNot { Uri.parse(it.url).host == host }).take(8)
        persist()
    }

    fun openTab(s: Site): Int { _tabs.value = _tabs.value + s; persist(); return _tabs.value.size - 1 }
    fun updateTab(i: Int, s: Site) { if (i in _tabs.value.indices) { _tabs.value = _tabs.value.toMutableList().also { it[i] = s }; persist() } }
    fun closeTab(i: Int) { if (i in _tabs.value.indices) { _tabs.value = _tabs.value.toMutableList().also { it.removeAt(i) }; persist() } }
    fun clearHistory() { _recents.value = emptyList(); _last.value = null; persist() }

    private fun persist() {
        prefs.edit()
            .putString("recents", json.encodeToString(_recents.value))
            .putString("last", _last.value?.let { json.encodeToString(it) })
            .putString("tabs", json.encodeToString(_tabs.value))
            .apply()
    }

    companion object {
        fun resolve(text: String): String? {
            val t = text.trim()
            if (t.isEmpty()) return null
            if (t.startsWith("http://", true) || t.startsWith("https://", true)) return t
            if (!t.contains(' ') && t.contains('.')) return "https://$t"
            return "https://www.google.com/search?q=" + Uri.encode(t)
        }
    }
}

class SettingsStore(context: Context) {
    private val prefs = context.getSharedPreferences("settings", Context.MODE_PRIVATE)
    val language = MutableStateFlow(prefs.getString("lang", "system")!!)
    val appearance = MutableStateFlow(prefs.getString("appearance", "system")!!)
    val blockAds = MutableStateFlow(prefs.getBoolean("blockAds", true))

    fun setLanguage(v: String) { language.value = v; prefs.edit().putString("lang", v).apply(); L10n.current = resolvedLanguage() }
    fun setAppearance(v: String) { appearance.value = v; prefs.edit().putString("appearance", v).apply() }
    fun setBlockAds(v: Boolean) { blockAds.value = v; prefs.edit().putBoolean("blockAds", v).apply() }

    fun resolvedLanguage(): String = when (val l = language.value) {
        "system" -> if (java.util.Locale.getDefault().language == "ar") "ar" else "en"
        else -> l
    }

    init { L10n.current = resolvedLanguage() }
}
