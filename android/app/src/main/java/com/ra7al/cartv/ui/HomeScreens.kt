package com.ra7al.cartv.ui

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.view.ViewGroup
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.Sort
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.ui.PlayerView
import coil.compose.SubcomposeAsyncImage
import com.ra7al.cartv.App
import com.ra7al.cartv.data.Channel
import com.ra7al.cartv.data.M3uParser

@Composable
fun rememberGroups(): List<com.ra7al.cartv.data.ChannelGroup> {
    val app = App.get(LocalContext.current)
    val playlists by app.store.playlists.collectAsState()
    val channels by app.store.channels.collectAsState()
    val selected by app.store.selected.collectAsState()
    return remember(playlists, channels, selected, L10n.current) {
        M3uParser.group(app.store.visibleChannels(), L10n.t("cat.uncategorized"))
    }
}

@Composable
fun HomeScreen() {
    val app = App.get(LocalContext.current)
    val nav = LocalNav.current
    val playlists by app.store.playlists.collectAsState()
    val selected by app.store.selected.collectAsState()
    val groups = rememberGroups()
    var query by remember { mutableStateOf("") }
    var menu by remember { mutableStateOf(false) }

    fun play(c: Channel, list: List<Channel>) { app.player.play(c, list); nav.push(Route.Player) }

    LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(bottom = 24.dp)) {
        item {
            LargeTitle(L10n.t("tab.home")) {
                Box {
                    CircleButton(Icons.AutoMirrored.Filled.Sort, L10n.t("home.sources"), "sourceMenu") { menu = true }
                    DropdownMenu(menu, { menu = false }) {
                        DropdownMenuItem(text = { Text("${L10n.t("home.allSources")} (${app.store.total().grouped()})") },
                            leadingIcon = { if (selected == null) Icon(Icons.Filled.Check, null) },
                            onClick = { app.store.selected.value = null; menu = false })
                        playlists.forEach { p ->
                            DropdownMenuItem(text = { Text("${p.name} (${app.store.count(p).grouped()})") },
                                leadingIcon = { if (selected == p.id) Icon(Icons.Filled.Check, null) },
                                onClick = { app.store.selected.value = p.id; menu = false })
                        }
                        HorizontalDivider()
                        DropdownMenuItem(text = { Text(L10n.t("common.add")) }, leadingIcon = { Icon(Icons.Filled.Add, null) },
                            onClick = { menu = false; nav.push(Route.AddSource) })
                    }
                }
            }
        }
        item { Box(Modifier.padding(horizontal = 16.dp, vertical = 6.dp)) { SearchField(query, { query = it }, L10n.t("home.search")) } }

        if (playlists.isEmpty()) {
            item {
                EmptyState(Icons.Filled.SettingsInputAntenna, L10n.t("home.emptyTitle"), L10n.t("home.emptyBody"),
                    L10n.t("home.addSource")) { nav.push(Route.AddSource) }
            }
        } else if (query.isNotBlank()) {
            val results = app.store.search(query, app.store.visibleChannels()).take(300)
            if (results.isEmpty()) {
                item { Text(L10n.t("home.noResults"), color = Muted, modifier = Modifier.fillMaxWidth().padding(40.dp), textAlign = TextAlign.Center) }
            } else {
                items(results.chunked(2)) { row ->
                    Row(Modifier.padding(horizontal = 16.dp, vertical = 8.dp), horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                        row.forEach { c -> ChannelCard(c, Modifier.weight(1f)) { play(c, results) } }
                        if (row.size == 1) Spacer(Modifier.weight(1f))
                    }
                }
            }
        } else {
            items(groups, key = { it.name }) { g ->
                Column(Modifier.padding(top = 18.dp)) {
                    Row(Modifier.fillMaxWidth().combinedClickableCompat { nav.push(Route.Category(g.name)) }
                        .padding(horizontal = 20.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(g.name, fontSize = 24.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                        Text("${g.channels.size.grouped()} ${L10n.t("home.channels")}", color = Muted, fontSize = 16.sp)
                        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Muted)
                    }
                    Spacer(Modifier.height(12.dp))
                    LazyRow(contentPadding = PaddingValues(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                        items(g.channels.take(25), key = { it.id }) { c -> ChannelCard(c, Modifier.width(230.dp)) { play(c, g.channels) } }
                    }
                }
            }
        }
    }
}

@Composable
fun CategoryScreen(name: String) {
    val app = App.get(LocalContext.current)
    val nav = LocalNav.current
    val groups = rememberGroups()
    var query by remember { mutableStateOf("") }
    val list = app.store.search(query, groups.firstOrNull { it.name == name }?.channels.orEmpty())
    Column {
        BackBar(name, nav::pop)
        Box(Modifier.padding(horizontal = 16.dp)) { SearchField(query, { query = it }, L10n.t("home.search")) }
        LazyVerticalGrid(GridCells.Fixed(2), contentPadding = PaddingValues(16.dp),
            horizontalArrangement = Arrangement.spacedBy(14.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
            items(list, key = { it.id }) { c -> ChannelCard(c) { app.player.play(c, list); nav.push(Route.Player) } }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ChannelCard(c: Channel, modifier: Modifier = Modifier, onClick: () -> Unit) {
    val app = App.get(LocalContext.current)
    val ctx = LocalContext.current
    val current by app.player.current.collectAsState()
    var menu by remember { mutableStateOf(false) }
    Column(modifier.combinedClickable(onClick = onClick, onLongClick = { menu = true }).testTag("channel-${c.name}")) {
        Box(Modifier.fillMaxWidth().aspectRatio(16f / 9f).clip(RoundedCornerShape(14.dp)).background(Color(0xFF1F1F1F))
            .border(2.dp, Color(0x99000000), RoundedCornerShape(14.dp)), contentAlignment = Alignment.Center) {
            if (c.logo != null) {
                SubcomposeAsyncImage(c.logo, c.name, Modifier.fillMaxSize(0.5f),
                    error = { Initials(c.name) }, loading = { Initials(c.name) })
            } else Initials(c.name)
            if (current?.id == c.id) {
                Icon(Icons.Filled.GraphicEq, null, tint = Color.White,
                    modifier = Modifier.align(Alignment.TopEnd).padding(8.dp).clip(RoundedCornerShape(50)).background(BrandGreen).padding(5.dp).size(14.dp))
            }
        }
        Spacer(Modifier.height(8.dp))
        Text(c.name, fontSize = 17.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        DropdownMenu(menu, { menu = false }) {
            val fav = app.store.isFavorite(c)
            DropdownMenuItem(text = { Text(L10n.t(if (fav) "common.unfavorite" else "common.favorite")) },
                leadingIcon = { Icon(if (fav) Icons.Filled.HeartBroken else Icons.Outlined.FavoriteBorder, null) },
                onClick = { app.store.toggleFavorite(c); menu = false })
            DropdownMenuItem(text = { Text(L10n.t("common.copyLink")) }, leadingIcon = { Icon(Icons.Filled.ContentCopy, null) },
                onClick = { copy(ctx, c.url); menu = false })
        }
    }
}

@Composable
private fun Initials(name: String) {
    Text(name.take(2).uppercase(), color = Color.White.copy(alpha = 0.85f), fontSize = 28.sp, fontWeight = FontWeight.Bold)
}

fun copy(ctx: Context, text: String) {
    (ctx.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager).setPrimaryClip(ClipData.newPlainText("link", text))
}

@OptIn(ExperimentalFoundationApi::class)
fun Modifier.combinedClickableCompat(onClick: () -> Unit) = this.combinedClickable(onClick = onClick)

@Composable
fun PlayerScreen() {
    val app = App.get(LocalContext.current)
    val nav = LocalNav.current
    val c by app.player.current.collectAsState()
    val playing by app.player.isPlaying.collectAsState()
    val buffering by app.player.buffering.collectAsState()
    val error by app.player.error.collectAsState()
    val favs by app.store.favorites.collectAsState()

    Column(Modifier.fillMaxSize().background(Color.Black)) {
        Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(nav::pop, Modifier.clip(RoundedCornerShape(50)).background(Color.White.copy(alpha = 0.12f)).testTag("closePlayer")) {
                Icon(Icons.Filled.KeyboardArrowDown, L10n.t("player.close"), tint = Color.White)
            }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(c?.name.orEmpty(), color = Color.White, fontWeight = FontWeight.SemiBold, maxLines = 1)
                if (!c?.group.isNullOrEmpty()) Text(c!!.group.split(';').map { it.trim() }.filter { it.isNotEmpty() }.joinToString(" · "), color = Color.White.copy(alpha = 0.7f), fontSize = 13.sp, maxLines = 1)
            }
            c?.let { ch ->
                val fav = favs.contains(ch.key)
                IconButton({ app.store.toggleFavorite(ch) }) {
                    Icon(if (fav) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder, L10n.t("common.favorite"),
                        tint = if (fav) Color.Red else Color.White)
                }
            }
        }
        Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
            AndroidView(factory = { ctx ->
                PlayerView(ctx).apply {
                    player = app.player.player
                    layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
                    useController = true
                    setShowNextButton(false); setShowPreviousButton(false)
                }
            }, modifier = Modifier.fillMaxWidth().aspectRatio(16f / 9f))
            if (buffering && error == null) CircularProgressIndicator(color = Color.White)
            error?.let {
                Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.padding(24.dp)) {
                    Icon(Icons.Filled.Warning, null, tint = Color(0xFFE5483B), modifier = Modifier.size(40.dp))
                    Text(it, color = Color.White, textAlign = TextAlign.Center)
                    Spacer(Modifier.height(10.dp))
                    Button({ app.player.retry() }, colors = ButtonDefaults.buttonColors(containerColor = BrandGreen)) { Text(L10n.t("player.retry")) }
                }
            }
        }
        Row(Modifier.fillMaxWidth().padding(bottom = 40.dp), horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically) {
            IconButton({ app.player.previous() }) { Icon(Icons.Filled.SkipPrevious, L10n.t("player.previous"), tint = Color.White, modifier = Modifier.size(36.dp)) }
            IconButton({ app.player.toggle() }, Modifier.size(72.dp)) {
                Icon(if (playing) Icons.Filled.PauseCircle else Icons.Filled.PlayCircle, L10n.t(if (playing) "player.pause" else "player.play"),
                    tint = Color.White, modifier = Modifier.size(68.dp))
            }
            IconButton({ app.player.next() }) { Icon(Icons.Filled.SkipNext, L10n.t("player.next"), tint = Color.White, modifier = Modifier.size(36.dp)) }
        }
    }
}

@Suppress("unused") private val unusedDp: Dp = 0.dp
