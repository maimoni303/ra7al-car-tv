package com.ra7al.cartv.ui

import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import coil.decode.VideoFrameDecoder
import coil.request.ImageRequest
import coil.request.videoFrameMillis
import com.ra7al.cartv.App
import com.ra7al.cartv.data.LocalVideo
import kotlinx.coroutines.launch

const val SUPPORT_EMAIL = "ra7al.server@gmail.com"
const val WHATSAPP = "966555588921"

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun LibraryScreen() {
    val ctx = LocalContext.current
    val app = App.get(ctx)
    val nav = LocalNav.current
    val scope = rememberCoroutineScope()
    val videos by app.library.videos.collectAsState()
    val favKeys by app.store.favorites.collectAsState()
    var segment by remember { mutableIntStateOf(0) }
    var choose by remember { mutableStateOf(false) }
    var importing by remember { mutableStateOf(false) }
    var renaming by remember { mutableStateOf<LocalVideo?>(null) }
    var menuFor by remember { mutableStateOf<LocalVideo?>(null) }

    fun importAll(uris: List<Uri>) {
        if (uris.isEmpty()) return
        scope.launch { importing = true; uris.forEach { runCatching { app.library.import(it) } }; importing = false }
    }
    val pickMedia = rememberLauncherForActivityResult(ActivityResultContracts.PickMultipleVisualMedia()) { importAll(it) }
    val pickFiles = rememberLauncherForActivityResult(ActivityResultContracts.OpenMultipleDocuments()) { importAll(it) }

    Column(Modifier.fillMaxSize()) {
        LargeTitle(L10n.t("tab.library")) { CircleButton(Icons.Filled.Add, L10n.t("library.import"), "importButton") { choose = true } }
        SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
            listOf("library.videos", "library.favorites").forEachIndexed { i, k ->
                SegmentedButton(selected = segment == i, onClick = { segment = i },
                    shape = SegmentedButtonDefaults.itemShape(i, 2), modifier = Modifier.testTag("segment-$i"),
                    colors = SegmentedButtonDefaults.colors(activeContainerColor = BrandGreen.copy(alpha = 0.18f), activeContentColor = BrandGreen, activeBorderColor = BrandGreen.copy(alpha = 0.5f)),
                    icon = {}) { Text(L10n.t(k)) }
            }
        }
        if (importing) LinearProgressIndicator(Modifier.fillMaxWidth().padding(16.dp), color = BrandGreen)

        if (segment == 0) {
            if (videos.isEmpty()) {
                Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                    EmptyState(Icons.Outlined.MoveToInbox, L10n.t("library.emptyTitle"), L10n.t("library.emptyBody"),
                        L10n.t("library.importNow")) { choose = true }
                }
            } else {
                LazyVerticalGrid(GridCells.Fixed(2), contentPadding = PaddingValues(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(14.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                    items(videos, key = { it.id }) { v ->
                        Column(Modifier.combinedClickable(onClick = {
                            app.player.play(app.library.asChannel(v), videos.map { app.library.asChannel(it) }); nav.push(Route.Player)
                        }, onLongClick = { menuFor = v })) {
                            Box(Modifier.fillMaxWidth().aspectRatio(16f / 9f).clip(RoundedCornerShape(14.dp)).background(Color(0xFF1F1F1F))) {
                                AsyncImage(ImageRequest.Builder(ctx).data(app.library.file(v)).videoFrameMillis(1000)
                                    .decoderFactory(VideoFrameDecoder.Factory()).build(), null, Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
                                if (v.durationMs > 0) {
                                    val s = v.durationMs / 1000
                                    Text(if (s >= 3600) "%d:%02d:%02d".format(s / 3600, s % 3600 / 60, s % 60) else "%d:%02d".format(s / 60, s % 60),
                                        color = Color.White, fontSize = 11.sp, fontWeight = FontWeight.Bold,
                                        modifier = Modifier.align(Alignment.BottomEnd).padding(8.dp).clip(CircleShape)
                                            .background(Color.Black.copy(alpha = 0.7f)).padding(horizontal = 6.dp, vertical = 2.dp))
                                }
                            }
                            Spacer(Modifier.height(8.dp))
                            Text(v.title, maxLines = 1, overflow = TextOverflow.Ellipsis)
                            DropdownMenu(menuFor == v, { menuFor = null }) {
                                DropdownMenuItem(text = { Text(L10n.t("common.rename")) }, leadingIcon = { Icon(Icons.Filled.Edit, null) },
                                    onClick = { renaming = v; menuFor = null })
                                DropdownMenuItem(text = { Text(L10n.t("common.delete")) }, leadingIcon = { Icon(Icons.Filled.Delete, null) },
                                    onClick = { app.library.delete(v); menuFor = null })
                            }
                        }
                    }
                }
            }
        } else {
            val favs = remember(favKeys) { app.store.favoriteChannels() }
            if (favs.isEmpty()) {
                Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                    EmptyState(Icons.Outlined.FavoriteBorder, L10n.t("library.noFavorites"), L10n.t("library.noFavoritesBody"))
                }
            } else {
                LazyVerticalGrid(GridCells.Fixed(2), contentPadding = PaddingValues(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(14.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
                    items(favs, key = { it.id }) { c -> ChannelCard(c) { app.player.play(c, favs); nav.push(Route.Player) } }
                }
            }
        }
    }

    if (choose) {
        AlertDialog(onDismissRequest = { choose = false }, title = { Text(L10n.t("library.import")) },
            text = {
                Column {
                    SettingsRow(Icons.Outlined.PhotoLibrary, L10n.t("library.fromPhotos"), chevron = false) {
                        choose = false; pickMedia.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.VideoOnly))
                    }
                    SettingsRow(Icons.Outlined.Folder, L10n.t("library.fromFiles"), chevron = false) {
                        choose = false; pickFiles.launch(arrayOf("video/*"))
                    }
                }
            },
            confirmButton = {}, dismissButton = { TextButton({ choose = false }) { Text(L10n.t("common.cancel")) } })
    }
    renaming?.let { v ->
        var t by remember(v) { mutableStateOf(v.title) }
        AlertDialog(onDismissRequest = { renaming = null }, title = { Text(L10n.t("common.rename")) },
            text = { OutlinedTextField(t, { t = it }, singleLine = true) },
            confirmButton = { TextButton({ app.library.rename(v, t); renaming = null }) { Text(L10n.t("common.save")) } },
            dismissButton = { TextButton({ renaming = null }) { Text(L10n.t("common.cancel")) } })
    }
}

@Composable
fun SettingsScreen() {
    val ctx = LocalContext.current
    val app = App.get(ctx)
    val nav = LocalNav.current
    val playlists by app.store.playlists.collectAsState()
    val lang by app.settings.language.collectAsState()
    val appearance by app.settings.appearance.collectAsState()
    val blockAds by app.settings.blockAds.collectAsState()

    fun open(uri: String) = runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(uri))) }

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(bottom = 24.dp)) {
        LargeTitle(L10n.t("tab.settings"))
        SectionHeader(L10n.t("settings.media"))
        GroupCard {
            SettingsRow(Icons.Filled.SettingsInputAntenna, L10n.t("sources.title"),
                subtitle = if (playlists.isEmpty()) L10n.t("sources.none") else playlists.joinToString(" · ") { it.name },
                tag = "manageSources") { nav.push(Route.ManageSources) }
        }
        SectionHeader(L10n.t("settings.preferences"))
        GroupCard {
            SettingsRow(Icons.Outlined.PhoneAndroid, L10n.t("settings.appearance"), value = appearanceLabel(appearance)) {
                nav.push(Route.Picker("appearance"))
            }
            RowDivider()
            SettingsRow(Icons.Outlined.Language, L10n.t("settings.language"), value = languageLabel(lang)) {
                nav.push(Route.Picker("language"))
            }
            RowDivider()
            SettingsRow(Icons.Outlined.PanTool, L10n.t("settings.blockAds"), chevron = false, trailing = {
                Switch(blockAds, { app.settings.setBlockAds(it) }, colors = SwitchDefaults.colors(checkedTrackColor = BrandGreen))
            })
        }
        SectionHeader(L10n.t("settings.about"))
        GroupCard {
            SettingsRow(Icons.Outlined.IosShare, L10n.t("settings.share")) {
                ctx.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain")
                    .putExtra(Intent.EXTRA_TEXT, L10n.t("settings.shareText")), null))
            }
            RowDivider()
            SettingsRow(Icons.Outlined.StarOutline, L10n.t("settings.review")) { open("mailto:$SUPPORT_EMAIL?subject=RA7AL%20Car%20TV%20Review") }
            RowDivider()
            SettingsRow(Icons.Outlined.Email, L10n.t("settings.contact"), subtitle = SUPPORT_EMAIL) { open("mailto:$SUPPORT_EMAIL") }
            RowDivider()
            SettingsRow(Icons.AutoMirrored.Filled.Chat, L10n.t("settings.whatsapp"), subtitle = L10n.t("settings.whatsappBody")) {
                open("https://wa.me/$WHATSAPP")
            }
        }
        SectionHeader(L10n.t("settings.legal"))
        GroupCard {
            SettingsRow(Icons.Outlined.PanTool, L10n.t("settings.privacy")) { nav.push(Route.Info("settings.privacy", "legal.privacy")) }
            RowDivider()
            SettingsRow(Icons.Outlined.Description, L10n.t("settings.terms")) { nav.push(Route.Info("settings.terms", "legal.terms")) }
        }
        val version = runCatching { ctx.packageManager.getPackageInfo(ctx.packageName, 0).versionName }.getOrNull() ?: "1.0"
        Text("RA7AL Car TV · ${L10n.t("settings.version")} $version", color = Muted, fontSize = 13.sp,
            modifier = Modifier.fillMaxWidth().padding(20.dp), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
    }
}

fun languageLabel(v: String) = when (v) { "ar" -> "العربية"; "en" -> "English"; else -> L10n.t("common.system") }
fun appearanceLabel(v: String) = when (v) { "light" -> L10n.t("settings.light"); "dark" -> L10n.t("settings.dark"); else -> L10n.t("common.system") }

@Composable
fun PickerScreen(kind: String) {
    val app = App.get(LocalContext.current)
    val nav = LocalNav.current
    val lang by app.settings.language.collectAsState()
    val appearance by app.settings.appearance.collectAsState()
    val options = if (kind == "language") listOf("system", "ar", "en") else listOf("system", "light", "dark")
    val selected = if (kind == "language") lang else appearance
    Column {
        BackBar(L10n.t(if (kind == "language") "settings.language" else "settings.appearance"), nav::pop)
        Spacer(Modifier.height(12.dp))
        GroupCard {
            options.forEachIndexed { i, o ->
                Row(Modifier.fillMaxWidth().clickable {
                    if (kind == "language") app.settings.setLanguage(o) else app.settings.setAppearance(o)
                }.padding(20.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(if (kind == "language") languageLabel(o) else appearanceLabel(o), Modifier.weight(1f), fontSize = 18.sp)
                    if (o == selected) Icon(Icons.Filled.Check, null, tint = BrandGreen)
                }
                if (i < options.lastIndex) RowDivider()
            }
        }
    }
}

@Composable
fun InfoScreen(titleKey: String, bodyKey: String) {
    val nav = LocalNav.current
    Column {
        BackBar(L10n.t(titleKey), nav::pop)
        Text(L10n.t(bodyKey), Modifier.verticalScroll(rememberScrollState()).padding(20.dp), fontSize = 17.sp, lineHeight = 26.sp)
    }
}
