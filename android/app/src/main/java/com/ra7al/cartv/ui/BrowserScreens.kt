package com.ra7al.cartv.ui

import android.annotation.SuppressLint
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.provider.Settings
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import coil.compose.SubcomposeAsyncImage
import com.ra7al.cartv.App
import com.ra7al.cartv.data.BrowserStore
import com.ra7al.cartv.data.Site
import java.io.ByteArrayInputStream

data class PopularSite(val name: String, val url: String)

val popularSites = listOf(
    PopularSite("Google", "https://www.google.com"), PopularSite("YouTube", "https://m.youtube.com"),
    PopularSite("Netflix", "https://www.netflix.com"), PopularSite("Prime Video", "https://www.primevideo.com"),
    PopularSite("Shahid", "https://shahid.mbc.net"), PopularSite("Disney+", "https://www.disneyplus.com"),
    PopularSite("HBO Max", "https://www.max.com"), PopularSite("TikTok", "https://www.tiktok.com"),
    PopularSite("Instagram", "https://www.instagram.com"), PopularSite("OSN+", "https://osnplus.com"),
    PopularSite("Paramount+", "https://www.paramountplus.com"), PopularSite("YouTube TV", "https://tv.youtube.com"),
    PopularSite("Apple TV", "https://tv.apple.com"), PopularSite("Twitch", "https://www.twitch.tv"),
    PopularSite("STARZPLAY", "https://starzplay.com"), PopularSite("Tubi", "https://tubitv.com"),
    PopularSite("Spotify", "https://open.spotify.com"), PopularSite("Anghami", "https://www.anghami.com"),
    PopularSite("Crunchyroll", "https://www.crunchyroll.com"), PopularSite("Pluto TV", "https://pluto.tv"),
)

@Composable
fun SiteIcon(url: String, name: String, size: Int = 76) {
    val host = Uri.parse(url).host.orEmpty()
    Box(Modifier.size(size.dp).clip(RoundedCornerShape(18.dp)).background(Card)
        .border(0.5.dp, Color(0x22000000), RoundedCornerShape(18.dp)), contentAlignment = Alignment.Center) {
        SubcomposeAsyncImage("https://www.google.com/s2/favicons?sz=128&domain=$host", name,
            Modifier.fillMaxSize().padding((size * 0.18).dp),
            error = { Text(name.take(1), color = BrandGreen, fontSize = (size * 0.42).sp, fontWeight = FontWeight.Bold) },
            loading = { Text(name.take(1), color = BrandGreen, fontSize = (size * 0.42).sp, fontWeight = FontWeight.Bold) })
    }
}

@Composable
fun BrowserScreen() {
    val app = App.get(LocalContext.current)
    val nav = LocalNav.current
    val recents by app.browser.recents.collectAsState()
    val last by app.browser.last.collectAsState()
    val tabs by app.browser.tabs.collectAsState()
    val blockAds by app.settings.blockAds.collectAsState()
    var text by remember { mutableStateOf("") }
    var menu by remember { mutableStateOf(false) }
    var showTabs by remember { mutableStateOf(false) }

    fun open(url: String) = nav.push(Route.Web(url, null))

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        LargeTitle(L10n.t("tab.browser")) {
            Row(Modifier.clip(CircleShape).background(Fill).padding(horizontal = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                Box {
                    IconButton({ menu = true }) { Icon(Icons.Filled.Menu, null) }
                    DropdownMenu(menu, { menu = false }) {
                        DropdownMenuItem(text = { Text(L10n.t("browser.clearHistory")) }, leadingIcon = { Icon(Icons.Filled.Delete, null) },
                            onClick = { app.browser.clearHistory(); menu = false })
                        DropdownMenuItem(text = { Text(L10n.t("settings.blockAds")) },
                            leadingIcon = { Checkbox(blockAds, null) }, onClick = { app.settings.setBlockAds(!blockAds) })
                    }
                }
                IconButton({ showTabs = true }, Modifier.testTag("tabsButton")) {
                    Box(Modifier.size(24.dp).border(2.dp, MaterialTheme.colorScheme.onSurface, RoundedCornerShape(6.dp)),
                        contentAlignment = Alignment.Center) { Text("${maxOf(tabs.size, 1)}", fontSize = 13.sp, fontWeight = FontWeight.Bold) }
                }
            }
        }
        Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(24.dp)) {
            SearchField(text, { text = it }, L10n.t("browser.search"), "browserSearch") {
                BrowserStore.resolve(text)?.let { text = ""; open(it) }
            }
            last?.let { s ->
                Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(Fill).clickable { open(s.url) }.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically) {
                    SiteIcon(s.url, s.title, 54)
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f)) {
                        Text(L10n.t("browser.continue"), color = BrandGreen, fontWeight = FontWeight.SemiBold)
                        Text(s.title, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        Text(Uri.parse(s.url).host.orEmpty(), color = Muted)
                    }
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Muted)
                }
            }
            if (recents.isNotEmpty()) {
                Text(L10n.t("browser.recent"), fontSize = 24.sp, fontWeight = FontWeight.Bold)
                LazyRow(horizontalArrangement = Arrangement.spacedBy(18.dp)) {
                    items(recents) { s -> SiteTile(s.title, s.url) { open(s.url) } }
                }
            }
            Text(L10n.t("browser.popular"), fontSize = 24.sp, fontWeight = FontWeight.Bold)
            popularSites.chunked(4).forEach { row ->
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    row.forEach { s -> SiteTile(s.name, s.url) { open(s.url) } }
                }
            }
            Spacer(Modifier.height(12.dp))
        }
    }

    if (showTabs) {
        AlertDialog(onDismissRequest = { showTabs = false },
            title = { Text(L10n.t("browser.tabs")) },
            text = {
                Column {
                    if (tabs.isEmpty()) Text(L10n.t("browser.noTabs"), color = Muted)
                    tabs.forEachIndexed { i, s ->
                        Row(Modifier.fillMaxWidth().clickable { showTabs = false; nav.push(Route.Web(s.url, i)) }.padding(vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically) {
                            SiteIcon(s.url, s.title, 36)
                            Spacer(Modifier.width(10.dp))
                            Text(s.title, Modifier.weight(1f), maxLines = 1, overflow = TextOverflow.Ellipsis)
                            IconButton({ app.browser.closeTab(i) }) { Icon(Icons.Filled.Close, L10n.t("player.close")) }
                        }
                    }
                }
            },
            confirmButton = { TextButton({ showTabs = false; open("https://www.google.com") }) { Text(L10n.t("browser.newTab")) } },
            dismissButton = { TextButton({ showTabs = false }) { Text(L10n.t("common.ok")) } })
    }
}

@Composable
private fun SiteTile(name: String, url: String, onClick: () -> Unit) {
    Column(Modifier.width(84.dp).clickable(onClick = onClick), horizontalAlignment = Alignment.CenterHorizontally) {
        SiteIcon(url, name)
        Spacer(Modifier.height(8.dp))
        Text(name, fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

private val adHosts = listOf(
    "doubleclick.net", "googlesyndication.com", "googleadservices.com", "adservice.google.com", "google-analytics.com",
    "googletagservices.com", "adnxs.com", "adsrvr.org", "taboola.com", "outbrain.com", "criteo.com", "criteo.net",
    "pubmatic.com", "rubiconproject.com", "openx.net", "amazon-adsystem.com", "moatads.com", "scorecardresearch.com",
    "popads.net", "popcash.net", "propellerads.com", "adsterra.com", "exoclick.com", "juicyads.com", "mgid.com",
    "revcontent.com", "smartadserver.com", "teads.tv", "media.net", "quantserve.com", "hotjar.com",
)

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun WebPageScreen(startUrl: String, tabIndex: Int?) {
    val ctx = LocalContext.current
    val app = App.get(ctx)
    val nav = LocalNav.current
    val blockAds by app.settings.blockAds.collectAsState()
    var address by remember { mutableStateOf(startUrl) }
    var progress by remember { mutableIntStateOf(0) }
    var canBack by remember { mutableStateOf(false) }
    var canForward by remember { mutableStateOf(false) }
    var tab by remember { mutableStateOf(tabIndex) }
    var webView by remember { mutableStateOf<WebView?>(null) }

    LaunchedEffect(Unit) { if (tab == null) tab = app.browser.openTab(Site(Uri.parse(startUrl).host.orEmpty(), startUrl)) }

    Column(Modifier.fillMaxSize()) {
        Row(Modifier.padding(horizontal = 12.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(nav::pop) { Icon(Icons.Filled.Close, L10n.t("player.close")) }
            BasicTextField(address, { address = it }, singleLine = true,
                textStyle = LocalTextStyle.current.copy(color = MaterialTheme.colorScheme.onSurface, fontSize = 16.sp),
                cursorBrush = SolidColor(BrandGreen),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Go),
                keyboardActions = KeyboardActions(onGo = { BrowserStore.resolve(address)?.let { webView?.loadUrl(it) } }),
                modifier = Modifier.weight(1f).clip(CircleShape).background(Fill).padding(horizontal = 14.dp, vertical = 10.dp))
            IconButton({ webView?.reload() }) { Icon(Icons.Filled.Refresh, L10n.t("browser.reload")) }
        }
        if (progress in 1..99) LinearProgressIndicator({ progress / 100f }, Modifier.fillMaxWidth(), color = BrandGreen)
        AndroidView(factory = { c ->
            WebView(c).apply {
                settings.javaScriptEnabled = true
                settings.domStorageEnabled = true
                settings.mediaPlaybackRequiresUserGesture = false
                settings.loadWithOverviewMode = true
                settings.useWideViewPort = true
                webChromeClient = object : WebChromeClient() {
                    override fun onProgressChanged(view: WebView, newProgress: Int) { progress = newProgress }
                }
                webViewClient = object : WebViewClient() {
                    override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? {
                        if (blockAds) {
                            val host = request.url.host.orEmpty()
                            if (adHosts.any { host == it || host.endsWith(".$it") }) {
                                return WebResourceResponse("text/plain", "utf-8", ByteArrayInputStream(ByteArray(0)))
                            }
                        }
                        return null
                    }
                    override fun onPageStarted(view: WebView, url: String, favicon: Bitmap?) { address = url }
                    override fun onPageFinished(view: WebView, url: String) {
                        canBack = view.canGoBack(); canForward = view.canGoForward()
                        val site = Site(view.title?.takeIf { it.isNotBlank() } ?: Uri.parse(url).host.orEmpty(), url)
                        app.browser.visited(site)
                        tab?.let { app.browser.updateTab(it, site) }
                    }
                }
                loadUrl(startUrl)
                webView = this
            }
        }, modifier = Modifier.weight(1f).fillMaxWidth())
        Row(Modifier.fillMaxWidth().background(Card).padding(horizontal = 24.dp, vertical = 6.dp),
            horizontalArrangement = Arrangement.SpaceBetween) {
            IconButton({ webView?.goBack() }, enabled = canBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, L10n.t("browser.back")) }
            IconButton({ webView?.goForward() }, enabled = canForward) { Icon(Icons.AutoMirrored.Filled.ArrowForward, L10n.t("browser.forward")) }
            IconButton({
                ctx.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain")
                    .putExtra(Intent.EXTRA_TEXT, address), null))
            }) { Icon(Icons.Filled.Share, L10n.t("settings.share")) }
            IconButton({ openCastSettings(ctx) }) { Icon(Icons.Filled.CastConnected, L10n.t("cast.startProjection")) }
        }
    }
    DisposableEffect(Unit) { onDispose { webView?.destroy() } }
}

fun openCastSettings(ctx: android.content.Context) {
    val intents = listOf(Intent(Settings.ACTION_CAST_SETTINGS), Intent("android.settings.WIFI_DISPLAY_SETTINGS"),
        Intent(Settings.ACTION_DISPLAY_SETTINGS))
    for (i in intents) {
        try { ctx.startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)); return } catch (_: Exception) { }
    }
}
