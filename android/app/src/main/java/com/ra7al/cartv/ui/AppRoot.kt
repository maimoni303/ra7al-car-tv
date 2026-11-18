package com.ra7al.cartv.ui

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.repeatOnLifecycle
import coil.compose.AsyncImage
import com.ra7al.cartv.App
import com.ra7al.cartv.data.Channel
import com.ra7al.cartv.data.Playlist

enum class Tab(val key: String, val icon: ImageVector) {
    Home("tab.home", Icons.Filled.Home),
    Browser("tab.browser", Icons.Filled.Language),
    Cast("tab.cast", Icons.Filled.Tv),
    Library("tab.library", Icons.Filled.VideoLibrary),
    Settings("tab.settings", Icons.Filled.Settings),
}

/** Screens pushed on top of the tabs. */
sealed interface Route {
    data class Category(val name: String) : Route
    data object ManageSources : Route
    data class SourceDetail(val playlist: Playlist) : Route
    data object AddSource : Route
    data object FindLinks : Route
    data class Info(val titleKey: String, val bodyKey: String) : Route
    data class Web(val url: String, val tab: Int?) : Route
    data class Picker(val kind: String) : Route   // "language" | "appearance"
    data object Player : Route
}

class Nav {
    val stack = mutableStateListOf<Route>()
    var tab by mutableStateOf(Tab.Home)
    var addSourceText by mutableStateOf("")
    fun push(r: Route) { stack.add(r) }
    fun pop() { if (stack.isNotEmpty()) stack.removeAt(stack.lastIndex) }
}

val LocalNav = staticCompositionLocalOf<Nav> { error("no nav") }

@Composable
fun AppRoot(sharedText: String?, seedDemo: Boolean) {
    val app = App.get(LocalContext.current)
    val lang by app.settings.language.collectAsState()
    val appearance by app.settings.appearance.collectAsState()
    val nav = remember { Nav() }

    LaunchedEffect(seedDemo) {
        if (seedDemo && app.store.playlists.value.isEmpty()) runCatching { app.store.addSource(DemoData.SAMPLE, "demo") }
    }
    // Check every source link once a day when the app starts or comes back to the front.
    val lifecycle = androidx.lifecycle.compose.LocalLifecycleOwner.current.lifecycle
    LaunchedEffect(lifecycle) {
        lifecycle.repeatOnLifecycle(androidx.lifecycle.Lifecycle.State.RESUMED) {
            if (!seedDemo) app.store.refreshDueSources()
        }
    }
    LaunchedEffect(sharedText) {
        if (!sharedText.isNullOrBlank()) { nav.addSourceText = sharedText; nav.push(Route.AddSource) }
    }

    key(lang) {
        L10n.current = app.settings.resolvedLanguage()
        CarTvTheme(appearance) {
            CompositionLocalProvider(
                LocalNav provides nav,
                LocalLayoutDirection provides if (L10n.current == "ar") LayoutDirection.Rtl else LayoutDirection.Ltr,
            ) {
                Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                    Shell(nav)
                }
            }
        }
    }
}

@Composable
private fun Shell(nav: Nav) {
    val app = App.get(LocalContext.current)
    val current by app.player.current.collectAsState()
    BackHandler(enabled = nav.stack.isNotEmpty()) { nav.pop() }
    ExternalDisplayHost()

    Box(Modifier.fillMaxSize()) {
        Box(Modifier.fillMaxSize().statusBarsPadding().padding(bottom = if (current == null) 92.dp else 168.dp)) {
            when (nav.tab) {
                Tab.Home -> HomeScreen()
                Tab.Browser -> BrowserScreen()
                Tab.Cast -> CastScreen()
                Tab.Library -> LibraryScreen()
                Tab.Settings -> SettingsScreen()
            }
        }

        Column(Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(horizontal = 14.dp, vertical = 6.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)) {
            AnimatedVisibility(current != null, enter = slideInVertically { it }, exit = slideOutVertically { it }) {
                current?.let { MiniPlayer(it) { nav.push(Route.Player) } }
            }
            TabBar(nav.tab) { nav.tab = it; nav.stack.clear() }
        }

        // Pushed screens cover everything (full-screen pages like the iPhone app).
        nav.stack.lastOrNull()?.let { route ->
            Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                Box(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()) {
                    when (route) {
                        is Route.Category -> CategoryScreen(route.name)
                        Route.ManageSources -> ManageSourcesScreen()
                        is Route.SourceDetail -> SourceDetailScreen(route.playlist)
                        Route.AddSource -> AddSourceScreen()
                        Route.FindLinks -> FindLinksScreen()
                        is Route.Info -> InfoScreen(route.titleKey, route.bodyKey)
                        is Route.Web -> WebPageScreen(route.url, route.tab)
                        is Route.Picker -> PickerScreen(route.kind)
                        Route.Player -> PlayerScreen()
                    }
                }
            }
        }
    }
}

@Composable
private fun TabBar(selected: Tab, onSelect: (Tab) -> Unit) {
    Row(Modifier.fillMaxWidth().shadow(10.dp, CircleShape).clip(CircleShape)
        .background(MaterialTheme.colorScheme.surface.copy(alpha = 0.97f))
        .border(0.5.dp, Color(0x22000000), CircleShape).padding(5.dp)) {
        Tab.entries.forEach { t ->
            val on = t == selected
            Column(Modifier.weight(1f).clip(CircleShape).background(if (on) Fill else Color.Transparent)
                .clickable { onSelect(t) }.padding(vertical = 8.dp).testTag("tab-${t.ordinal}"),
                horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(t.icon, null, tint = if (on) BrandGreen else MaterialTheme.colorScheme.onSurface, modifier = Modifier.size(24.dp))
                Text(L10n.t(t.key), fontSize = 11.sp, fontWeight = FontWeight.Medium, maxLines = 1,
                    color = if (on) BrandGreen else MaterialTheme.colorScheme.onSurface)
            }
        }
    }
}

@Composable
fun MiniPlayer(c: Channel, onOpen: () -> Unit) {
    val app = App.get(LocalContext.current)
    val playing by app.player.isPlaying.collectAsState()
    val error by app.player.error.collectAsState()
    val favs by app.store.favorites.collectAsState()
    val fav = favs.contains(c.key)
    Row(Modifier.fillMaxWidth().shadow(12.dp, RoundedCornerShape(22.dp)).clip(RoundedCornerShape(22.dp))
        .background(MaterialTheme.colorScheme.surface).clickable(onClick = onOpen).testTag("miniPlayer")
        .padding(horizontal = 12.dp, vertical = 9.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(62.dp, 46.dp).clip(RoundedCornerShape(10.dp)).background(Color.Black), contentAlignment = Alignment.Center) {
            when {
                error != null -> Icon(Icons.Filled.Warning, null, tint = Color(0xFFE5483B))
                c.logo != null -> AsyncImage(c.logo, null, Modifier.padding(5.dp))
                else -> Icon(Icons.Filled.LiveTv, null, tint = Color.White)
            }
        }
        Spacer(Modifier.width(14.dp))
        Text(c.name, fontSize = 17.sp, fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f))
        IconButton({ app.store.toggleFavorite(c) }) {
            Icon(if (fav) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder, L10n.t("common.favorite"),
                tint = if (fav) Color.Red else MaterialTheme.colorScheme.onSurface)
        }
        IconButton({ app.player.toggle() }) {
            Icon(if (playing) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                L10n.t(if (playing) "player.pause" else "player.play"), modifier = Modifier.size(30.dp))
        }
        IconButton({ app.player.stop() }) { Icon(Icons.Filled.Close, L10n.t("player.close")) }
    }
}

object DemoData {
    const val SAMPLE = """#EXTM3U
#EXTINF:-1 group-title="News",Al Arabiya
https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8
#EXTINF:-1 group-title="News",Sky News Arabia
https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8
#EXTINF:-1 group-title="Movies;Entertainment",Top Gear (720p)
https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8
#EXTINF:-1 group-title="Movies",24 Hour Free Movies
https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8
#EXTINF:-1 group-title="Sports",Sports One
https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8
#EXTINF:-1 group-title="Kids",Kids TV
https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8
"""
}
