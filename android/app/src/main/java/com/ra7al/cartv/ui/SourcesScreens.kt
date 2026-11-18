package com.ra7al.cartv.ui

import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.ra7al.cartv.App
import com.ra7al.cartv.data.Playlist
import kotlinx.coroutines.launch

@Composable
fun ManageSourcesScreen() {
    val app = App.get(LocalContext.current)
    val nav = LocalNav.current
    val scope = rememberCoroutineScope()
    val playlists by app.store.playlists.collectAsState()
    val channels by app.store.channels.collectAsState()
    var checking by remember { mutableStateOf(false) }

    Column {
        BackBar(L10n.t("sources.title"), nav::pop) {
            CircleButton(Icons.Filled.Add, L10n.t("home.addSource"), "addSource") { nav.push(Route.AddSource) }
        }
        LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            if (playlists.isEmpty()) item {
                EmptyState(Icons.Filled.SettingsInputAntenna, L10n.t("home.emptyTitle"), L10n.t("home.emptyBody"),
                    L10n.t("home.addSource")) { nav.push(Route.AddSource) }
            }
            items(playlists, key = { it.id }) { p ->
                val ok = p.lastError == null
                Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(Card)
                    .clickable { nav.push(Route.SourceDetail(p)) }.testTag("source-${p.name}")
                    .padding(horizontal = 22.dp, vertical = 20.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(if (ok) Icons.Filled.SettingsInputAntenna else Icons.Filled.PortableWifiOff, null,
                        tint = if (ok) BrandGreen else Color.Red, modifier = Modifier.size(30.dp))
                    Spacer(Modifier.width(18.dp))
                    Column(Modifier.weight(1f)) {
                        Text(p.name, fontSize = 22.sp, fontWeight = FontWeight.Medium)
                        Text("${(channels[p.id]?.size ?: 0).grouped()} ${L10n.t("home.channels")} · ${L10n.t("sources.refreshed")} ${relative(p.lastUpdated)}",
                            color = Muted, fontSize = 15.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        if (!ok) Text(L10n.t("sources.broken"), color = Color.Red, fontSize = 14.sp, maxLines = 1)
                    }
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Color(0xFFC7C7CC))
                }
            }
            if (playlists.any { it.sourceUrl != null }) item {
                TextButton({ scope.launch { checking = true; app.store.refreshDueSources(force = true); checking = false } },
                    enabled = !checking, modifier = Modifier.fillMaxWidth()) {
                    if (checking) CircularProgressIndicator(Modifier.size(18.dp), strokeWidth = 2.dp) else Icon(Icons.Filled.Refresh, null)
                    Spacer(Modifier.width(8.dp))
                    Text(L10n.t("sources.checkAll"), color = BrandGreen)
                }
            }
        }
    }
}

@Composable
fun SourceDetailScreen(initial: Playlist) {
    val ctx = LocalContext.current
    val app = App.get(ctx)
    val nav = LocalNav.current
    val scope = rememberCoroutineScope()
    val playlists by app.store.playlists.collectAsState()
    val p = playlists.firstOrNull { it.id == initial.id } ?: run { LaunchedEffect(Unit) { nav.pop() }; return }
    var name by remember { mutableStateOf(p.name) }
    var busy by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var confirm by remember { mutableStateOf(false) }
    DisposableEffect(Unit) { onDispose { app.store.rename(p, name) } }

    Column(Modifier.verticalScroll(rememberScrollState())) {
        BackBar(p.name, nav::pop)
        SectionHeader(L10n.t("sources.name"))
        GroupCard {
            OutlinedTextField(name, { name = it }, singleLine = true, modifier = Modifier.fillMaxWidth().padding(12.dp))
        }
        Spacer(Modifier.height(16.dp))
        GroupCard {
            InfoLine(L10n.t("home.channels"), app.store.count(p).grouped())
            RowDivider()
            InfoLine(L10n.t("sources.refreshed"), relative(p.lastUpdated))
            RowDivider()
            InfoLine(L10n.t("sources.status"), p.lastError ?: L10n.t("sources.ok"), if (p.lastError == null) BrandGreen else Color.Red)
            RowDivider()
            InfoLine(L10n.t("sources.link"), p.sourceUrl ?: L10n.t("sources.pasted"))
        }
        Spacer(Modifier.height(16.dp))
        if (p.sourceUrl != null) GroupCard {
            SettingsRow(Icons.Filled.Refresh, L10n.t("sources.refresh"), chevron = false, trailing = {
                if (busy) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp)
            }) {
                if (!busy) scope.launch {
                    busy = true
                    runCatching { app.store.refresh(p) }.onFailure { error = it.message }
                    busy = false
                }
            }
            RowDivider()
            SettingsRow(Icons.Filled.ContentCopy, L10n.t("common.copyLink"), chevron = false) { copy(ctx, p.sourceUrl) }
        }
        Spacer(Modifier.height(16.dp))
        GroupCard {
            Row(Modifier.fillMaxWidth().clickable { confirm = true }.padding(20.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Delete, null, tint = Color.Red)
                Spacer(Modifier.width(16.dp))
                Text(L10n.t("common.delete"), color = Color.Red, fontSize = 18.sp)
            }
        }
    }
    if (confirm) AlertDialog(onDismissRequest = { confirm = false }, title = { Text(L10n.t("sources.deleteConfirm")) },
        confirmButton = { TextButton({ confirm = false; app.store.delete(p); nav.pop() }) { Text(L10n.t("common.delete"), color = Color.Red) } },
        dismissButton = { TextButton({ confirm = false }) { Text(L10n.t("common.cancel")) } })
    error?.let { AlertDialog(onDismissRequest = { error = null }, title = { Text(L10n.t("common.error")) }, text = { Text(it) },
        confirmButton = { TextButton({ error = null }) { Text(L10n.t("common.ok")) } }) }
}

@Composable
private fun InfoLine(label: String, value: String, color: Color = Muted) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 14.dp)) {
        Text(label, fontSize = 17.sp, modifier = Modifier.weight(1f))
        Text(value, color = color, fontSize = 15.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1.4f))
    }
}

@Composable
fun AddSourceScreen() {
    val ctx = LocalContext.current
    val app = App.get(ctx)
    val nav = LocalNav.current
    val scope = rememberCoroutineScope()
    var busy by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    val file = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) scope.launch {
            busy = true
            runCatching { app.store.importFile(uri) }.onSuccess { nav.pop() }.onFailure { error = it.message }
            busy = false
        }
    }
    fun open(u: String) = runCatching { ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(u))) }

    Column(Modifier.verticalScroll(rememberScrollState())) {
        BackBar(L10n.t("add.title"), nav::pop) {
            if (busy) CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.dp)
            else TextButton(enabled = nav.addSourceText.isNotBlank(), modifier = Modifier.testTag("addConfirm"), onClick = {
                scope.launch {
                    busy = true
                    runCatching { app.store.addSource(nav.addSourceText) }
                        .onSuccess { nav.addSourceText = ""; nav.pop() }
                        .onFailure { error = it.message }
                    busy = false
                }
            }) { Text(L10n.t("common.add"), fontSize = 18.sp, fontWeight = FontWeight.SemiBold,
                color = if (nav.addSourceText.isNotBlank()) BrandGreen else Muted) }
        }
        Text(L10n.t("add.hint"), color = Muted, modifier = Modifier.padding(horizontal = 22.dp, vertical = 10.dp))
        Box(Modifier.padding(horizontal = 16.dp).fillMaxWidth().height(200.dp).clip(RoundedCornerShape(24.dp)).background(Card).padding(16.dp)) {
            BasicTextField(nav.addSourceText, { nav.addSourceText = it }, Modifier.fillMaxSize().testTag("sourceInput"),
                textStyle = LocalTextStyle.current.copy(color = MaterialTheme.colorScheme.onSurface, fontSize = 16.sp),
                cursorBrush = SolidColor(BrandGreen))
            Button({
                val cm = ctx.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                cm.primaryClip?.getItemAt(0)?.coerceToText(ctx)?.toString()?.let { nav.addSourceText = it }
            }, Modifier.align(Alignment.BottomEnd), shape = CircleShape, colors = ButtonDefaults.buttonColors(containerColor = BrandGreen)) {
                Icon(Icons.Filled.ContentPaste, null, Modifier.size(18.dp))
                Spacer(Modifier.width(6.dp))
                Text(L10n.t("add.paste"))
            }
        }
        SectionHeader(L10n.t("add.findLink"))
        GroupCard {
            SettingsRow(Icons.Outlined.Explore, L10n.t("add.findLinks"), L10n.t("add.findLinksBody"), tag = "findLinks") { nav.push(Route.FindLinks) }
            RowDivider()
            SettingsRow(Icons.Outlined.Folder, L10n.t("add.importFile"), L10n.t("add.importFileBody")) { file.launch(arrayOf("*/*")) }
        }
        SectionHeader(L10n.t("add.help"))
        GroupCard {
            SettingsRow(Icons.Outlined.HelpOutline, L10n.t("add.whatIs"), L10n.t("add.whatIsBody")) { nav.push(Route.Info("add.whatIs", "add.whatIsText")) }
            RowDivider()
            SettingsRow(Icons.Outlined.Email, L10n.t("add.emailSupport"), SUPPORT_EMAIL) { open("mailto:$SUPPORT_EMAIL") }
            RowDivider()
            SettingsRow(Icons.AutoMirrored.Filled.Chat, L10n.t("settings.whatsapp"), L10n.t("settings.whatsappBody")) { open("https://wa.me/$WHATSAPP") }
        }
        Spacer(Modifier.height(24.dp))
    }
    error?.let { AlertDialog(onDismissRequest = { error = null }, title = { Text(L10n.t("common.error")) }, text = { Text(it) },
        confirmButton = { TextButton({ error = null }) { Text(L10n.t("common.ok")) } }) }
}

// ---------- Find IPTV Links (iptv-org directory) ----------

data class DirEntry(val name: String, val code: String, val url: String, val flag: String? = null)

object IptvDirectory {
    private const val BASE = "https://iptv-org.github.io/iptv"
    data class Country(val code: String, val en: String, val ar: String, val langs: List<String>)

    val countries = listOf(
        Country("sa", "Saudi Arabia", "السعودية", listOf("ara", "eng")), Country("ae", "United Arab Emirates", "الإمارات", listOf("ara", "eng")),
        Country("kw", "Kuwait", "الكويت", listOf("ara", "eng")), Country("qa", "Qatar", "قطر", listOf("ara", "eng")),
        Country("bh", "Bahrain", "البحرين", listOf("ara", "eng")), Country("om", "Oman", "عُمان", listOf("ara", "eng")),
        Country("ye", "Yemen", "اليمن", listOf("ara")), Country("iq", "Iraq", "العراق", listOf("ara", "kur")),
        Country("jo", "Jordan", "الأردن", listOf("ara")), Country("sy", "Syria", "سوريا", listOf("ara")),
        Country("lb", "Lebanon", "لبنان", listOf("ara", "fra")), Country("ps", "Palestine", "فلسطين", listOf("ara")),
        Country("eg", "Egypt", "مصر", listOf("ara")), Country("sd", "Sudan", "السودان", listOf("ara")),
        Country("ly", "Libya", "ليبيا", listOf("ara")), Country("tn", "Tunisia", "تونس", listOf("ara", "fra")),
        Country("dz", "Algeria", "الجزائر", listOf("ara", "fra")), Country("ma", "Morocco", "المغرب", listOf("ara", "fra")),
        Country("tr", "Turkey", "تركيا", listOf("tur")), Country("pk", "Pakistan", "باكستان", listOf("urd", "eng")),
        Country("in", "India", "الهند", listOf("hin", "eng")), Country("id", "Indonesia", "إندونيسيا", listOf("ind")),
        Country("ph", "Philippines", "الفلبين", listOf("fil", "eng")), Country("us", "United States", "الولايات المتحدة", listOf("eng", "spa")),
        Country("gb", "United Kingdom", "المملكة المتحدة", listOf("eng")), Country("ca", "Canada", "كندا", listOf("eng", "fra")),
        Country("fr", "France", "فرنسا", listOf("fra")), Country("de", "Germany", "ألمانيا", listOf("deu")),
        Country("es", "Spain", "إسبانيا", listOf("spa")), Country("it", "Italy", "إيطاليا", listOf("ita")),
        Country("br", "Brazil", "البرازيل", listOf("por")), Country("jp", "Japan", "اليابان", listOf("jpn")),
    )
    private val languages = mapOf(
        "ara" to ("Arabic" to "العربية"), "eng" to ("English" to "الإنجليزية"), "fra" to ("French" to "الفرنسية"),
        "spa" to ("Spanish" to "الإسبانية"), "tur" to ("Turkish" to "التركية"), "urd" to ("Urdu" to "الأردية"),
        "hin" to ("Hindi" to "الهندية"), "kur" to ("Kurdish" to "الكردية"), "deu" to ("German" to "الألمانية"),
        "ita" to ("Italian" to "الإيطالية"), "por" to ("Portuguese" to "البرتغالية"), "ind" to ("Indonesian" to "الإندونيسية"),
        "fil" to ("Filipino" to "الفلبينية"), "jpn" to ("Japanese" to "اليابانية"), "rus" to ("Russian" to "الروسية"),
    )
    private val categories = listOf(
        "news" to ("News" to "أخبار"), "sports" to ("Sports" to "رياضة"), "movies" to ("Movies" to "أفلام"),
        "series" to ("Series" to "مسلسلات"), "entertainment" to ("Entertainment" to "ترفيه"), "kids" to ("Kids" to "أطفال"),
        "animation" to ("Animation" to "رسوم متحركة"), "documentary" to ("Documentary" to "وثائقي"), "religious" to ("Religious" to "ديني"),
        "music" to ("Music" to "موسيقى"), "education" to ("Education" to "تعليم"), "cooking" to ("Cooking" to "طبخ"),
        "travel" to ("Travel" to "سفر"), "outdoor" to ("Outdoor" to "برّية"), "auto" to ("Auto" to "سيارات"),
        "business" to ("Business" to "أعمال"), "science" to ("Science" to "علوم"), "weather" to ("Weather" to "طقس"),
        "general" to ("General" to "عام"), "family" to ("Family" to "عائلي"), "comedy" to ("Comedy" to "كوميديا"),
    )
    private fun n(p: Pair<String, String>) = if (L10n.current == "ar") p.second else p.first
    fun flag(code: String) = code.uppercase().map { String(Character.toChars(127397 + it.code)) }.joinToString("")
    fun country(c: Country) = DirEntry(n(c.en to c.ar), c.code.uppercase(), "$BASE/countries/${c.code}.m3u", flag(c.code))
    fun language(code: String) = languages[code]?.let { DirEntry(n(it), code.uppercase(), "$BASE/languages/$code.m3u") }
    fun allLanguages() = languages.keys.mapNotNull { language(it) }
    fun allCategories() = categories.map { DirEntry(n(it.second), it.first.uppercase(), "$BASE/categories/${it.first}.m3u") }
    fun name(c: Country) = n(c.en to c.ar)
}

@Composable
fun FindLinksScreen() {
    val ctx = LocalContext.current
    val app = App.get(ctx)
    val nav = LocalNav.current
    val scope = rememberCoroutineScope()
    val region = remember { java.util.Locale.getDefault().country.lowercase() }
    var country by remember { mutableStateOf(IptvDirectory.countries.firstOrNull { it.code == region } ?: IptvDirectory.countries.first()) }
    var tab by remember { mutableIntStateOf(0) }
    var query by remember { mutableStateOf("") }
    var menu by remember { mutableStateOf(false) }
    var copied by remember { mutableStateOf<String?>(null) }
    var adding by remember { mutableStateOf<String?>(null) }
    val added = remember { mutableStateListOf<String>() }
    var error by remember { mutableStateOf<String?>(null) }

    val list = remember(tab, country, query, L10n.current) {
        val all = when (tab) {
            0 -> listOf(IptvDirectory.country(country)) + country.langs.mapNotNull { IptvDirectory.language(it) } + IptvDirectory.allCategories().take(8)
            1 -> IptvDirectory.countries.map { IptvDirectory.country(it) }
            2 -> IptvDirectory.allLanguages()
            else -> IptvDirectory.allCategories()
        }
        val q = query.trim()
        if (q.isEmpty()) all else all.filter { it.name.contains(q, true) || it.code.contains(q, true) }
    }

    @Composable
    fun Entry(e: DirEntry, highlighted: Boolean = false) {
        Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(Card)
            .border(if (highlighted) 1.5.dp else 0.dp, if (highlighted) BrandGreen else Color.Transparent, RoundedCornerShape(18.dp))
            .padding(14.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (e.flag != null) Text(e.flag, fontSize = 28.sp) else Icon(Icons.Outlined.LiveTv, null, tint = BrandGreen, modifier = Modifier.size(30.dp))
                Spacer(Modifier.width(12.dp))
                Column {
                    Text(e.name, fontWeight = FontWeight.SemiBold, fontSize = 17.sp)
                    Text(e.code, color = BrandGreen, fontSize = 12.sp, fontWeight = FontWeight.Bold,
                        modifier = Modifier.clip(RoundedCornerShape(5.dp)).background(BrandGreen.copy(alpha = 0.14f)).padding(horizontal = 6.dp, vertical = 2.dp))
                }
            }
            Text(e.url, fontFamily = FontFamily.Monospace, fontSize = 13.sp, maxLines = 1, overflow = TextOverflow.Ellipsis,
                modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(Fill).padding(10.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedButton({ copy(ctx, e.url); nav.addSourceText = e.url; copied = e.url }, Modifier.weight(1f), shape = RoundedCornerShape(12.dp)) {
                    Icon(if (copied == e.url) Icons.Filled.Check else Icons.Filled.ContentCopy, null, Modifier.size(18.dp))
                    Spacer(Modifier.width(6.dp))
                    Text(L10n.t(if (copied == e.url) "find.copied" else "find.copy"))
                }
                Button({
                    adding = e.url
                    scope.launch {
                        runCatching { app.store.addFromUrl(e.name, e.url) }.onSuccess { added += e.url }.onFailure { error = it.message }
                        adding = null
                    }
                }, Modifier.weight(1f), enabled = adding == null && e.url !in added, shape = RoundedCornerShape(12.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = BrandGreen)) {
                    if (adding == e.url) CircularProgressIndicator(Modifier.size(18.dp), color = Color.White, strokeWidth = 2.dp)
                    else {
                        Icon(if (e.url in added) Icons.Filled.Check else Icons.Filled.Add, null, Modifier.size(18.dp))
                        Spacer(Modifier.width(6.dp))
                        Text(L10n.t(if (e.url in added) "find.added" else "common.add"))
                    }
                }
            }
        }
    }

    Column {
        BackBar(L10n.t("add.findLinks"), nav::pop)
        LazyColumn(contentPadding = PaddingValues(16.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
            item {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.DirectionsCar, null, tint = BrandGreen)
                    Spacer(Modifier.width(8.dp))
                    Text("RA7AL Playlists", fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                    Box {
                        Row(Modifier.clip(CircleShape).background(Card).clickable { menu = true }.padding(horizontal = 12.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically) {
                            Box(Modifier.size(8.dp).clip(CircleShape).background(BrandGreen))
                            Spacer(Modifier.width(6.dp))
                            Text("${IptvDirectory.flag(country.code)} ${IptvDirectory.name(country)}")
                            Icon(Icons.Filled.ArrowDropDown, null)
                        }
                        DropdownMenu(menu, { menu = false }) {
                            IptvDirectory.countries.forEach { c ->
                                DropdownMenuItem(text = { Text("${IptvDirectory.flag(c.code)} ${IptvDirectory.name(c)}") },
                                    onClick = { country = c; menu = false })
                            }
                        }
                    }
                }
            }
            item {
                Text("${L10n.t("find.recommended")} ${IptvDirectory.name(country)}", fontSize = 24.sp, fontWeight = FontWeight.Bold)
                Text(L10n.t("find.recommendedBody"), color = Muted)
            }
            item { Entry(IptvDirectory.country(country), highlighted = true) }
            items(country.langs.mapNotNull { IptvDirectory.language(it) }) { Entry(it) }
            item { SearchField(query, { query = it }, L10n.t("find.search")) }
            item {
                LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    items(listOf("find.forYou", "find.countries", "find.languages", "find.categories").withIndex().toList()) { (i, k) ->
                        FilterChip(tab == i, { tab = i }, { Text(L10n.t(k)) },
                            colors = FilterChipDefaults.filterChipColors(selectedContainerColor = BrandGreen.copy(alpha = 0.18f), selectedLabelColor = BrandGreen))
                    }
                }
            }
            items(list, key = { "list-" + it.url }) { Entry(it) }
            item { Text(L10n.t("find.credit"), color = Muted, fontSize = 13.sp) }
        }
    }
    error?.let { AlertDialog(onDismissRequest = { error = null }, title = { Text(L10n.t("common.error")) }, text = { Text(it) },
        confirmButton = { TextButton({ error = null }) { Text(L10n.t("common.ok")) } }) }
}
