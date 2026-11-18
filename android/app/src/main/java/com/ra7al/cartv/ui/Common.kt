package com.ra7al.cartv.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.text.NumberFormat
import java.util.Locale

val BrandGreen = Color(0xFF58BB3D)

private val LightColors = lightColorScheme(
    primary = BrandGreen, onPrimary = Color.White,
    background = Color(0xFFF2F2F7), surface = Color.White, surfaceVariant = Color(0xFFE5E5EA),
    onBackground = Color.Black, onSurface = Color.Black, onSurfaceVariant = Color(0xFF8E8E93),
)
private val DarkColors = darkColorScheme(
    primary = BrandGreen, onPrimary = Color.White,
    background = Color.Black, surface = Color(0xFF1C1C1E), surfaceVariant = Color(0xFF2C2C2E),
    onBackground = Color.White, onSurface = Color.White, onSurfaceVariant = Color(0xFF98989F),
)

@Composable
fun CarTvTheme(appearance: String, content: @Composable () -> Unit) {
    val dark = when (appearance) { "dark" -> true; "light" -> false; else -> isSystemInDarkTheme() }
    MaterialTheme(colorScheme = if (dark) DarkColors else LightColors, content = content)
}

val Muted @Composable get() = MaterialTheme.colorScheme.onSurfaceVariant
val Card @Composable get() = MaterialTheme.colorScheme.surface
val Fill @Composable get() = MaterialTheme.colorScheme.surfaceVariant

fun Int.grouped(): String = NumberFormat.getIntegerInstance(Locale.US).format(this)

fun relative(ms: Long): String {
    val m = ((System.currentTimeMillis() - ms) / 60000).coerceAtLeast(0)
    val ar = L10n.current == "ar"
    return when {
        m < 1 -> if (ar) "الآن" else "just now"
        m < 60 -> if (ar) "قبل $m دقيقة" else "$m minutes ago"
        m < 1440 -> if (ar) "قبل ${m / 60} ساعة" else "${m / 60} hours ago"
        else -> if (ar) "قبل ${m / 1440} يوم" else "${m / 1440} days ago"
    }
}

@Composable
fun LargeTitle(text: String, trailing: @Composable RowScope.() -> Unit = {}) {
    Row(Modifier.fillMaxWidth().padding(start = 20.dp, end = 16.dp, top = 12.dp, bottom = 8.dp),
        verticalAlignment = Alignment.CenterVertically) {
        Text(text, fontSize = 34.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
        trailing()
    }
}

@Composable
fun SearchField(value: String, onChange: (String) -> Unit, placeholder: String, tag: String = "search",
                onSubmit: () -> Unit = {}) {
    Row(Modifier.fillMaxWidth().height(50.dp).clip(CircleShape).background(Fill).padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically) {
        Icon(Icons.Default.Search, null, tint = Muted)
        Spacer(Modifier.width(10.dp))
        Box(Modifier.weight(1f)) {
            if (value.isEmpty()) Text(placeholder, color = Muted, fontSize = 17.sp, maxLines = 1)
            BasicTextField(value, onChange, singleLine = true,
                textStyle = LocalTextStyle.current.copy(fontSize = 17.sp, color = MaterialTheme.colorScheme.onSurface),
                cursorBrush = SolidColor(BrandGreen),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(onSearch = { onSubmit() }),
                modifier = Modifier.fillMaxWidth().testTag(tag))
        }
        if (value.isNotEmpty()) {
            IconButton(onClick = { onChange("") }, modifier = Modifier.size(32.dp)) {
                Icon(Icons.Default.Cancel, L10n.t("common.clear"), tint = Muted)
            }
        }
    }
}

@Composable
fun CircleButton(icon: ImageVector, label: String, tag: String = label, onClick: () -> Unit) {
    Box(Modifier.size(46.dp).clip(CircleShape).background(Fill).clickable(onClick = onClick).testTag(tag),
        contentAlignment = Alignment.Center) {
        Icon(icon, label, tint = MaterialTheme.colorScheme.onSurface)
    }
}

@Composable
fun EmptyState(icon: ImageVector, title: String, message: String, action: String? = null, onAction: (() -> Unit)? = null) {
    Column(Modifier.fillMaxWidth().padding(32.dp), horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Icon(icon, null, tint = Color(0xFFC7C7CC), modifier = Modifier.size(72.dp))
        Text(title, fontSize = 22.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
        Text(message, color = Muted, textAlign = TextAlign.Center, fontSize = 16.sp)
        if (action != null && onAction != null) {
            Spacer(Modifier.height(6.dp))
            Button(onClick = onAction, shape = CircleShape, contentPadding = PaddingValues(horizontal = 44.dp, vertical = 16.dp),
                colors = ButtonDefaults.buttonColors(containerColor = BrandGreen)) {
                Text(action, fontSize = 18.sp, fontWeight = FontWeight.SemiBold)
            }
        }
    }
}

@Composable
fun SectionHeader(text: String) {
    Text(text.uppercase(), color = Muted, fontSize = 14.sp, fontWeight = FontWeight.Medium,
        modifier = Modifier.padding(start = 34.dp, top = 22.dp, bottom = 8.dp))
}

@Composable
fun GroupCard(content: @Composable ColumnScope.() -> Unit) {
    Column(Modifier.padding(horizontal = 16.dp).fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(Card),
        content = content)
}

@Composable
fun SettingsRow(icon: ImageVector, title: String, subtitle: String? = null, value: String? = null,
                chevron: Boolean = true, tag: String? = null, trailing: (@Composable () -> Unit)? = null,
                onClick: (() -> Unit)? = null) {
    Row(Modifier.fillMaxWidth()
        .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
        .then(if (tag != null) Modifier.testTag(tag) else Modifier)
        .padding(horizontal = 20.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = BrandGreen, modifier = Modifier.size(28.dp))
        Spacer(Modifier.width(18.dp))
        Column(Modifier.weight(1f)) {
            Text(title, fontSize = 19.sp)
            if (subtitle != null) Text(subtitle, color = Muted, fontSize = 15.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        if (value != null) Text(value, color = Muted, fontSize = 17.sp)
        if (trailing != null) trailing()
        if (chevron) Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Color(0xFFC7C7CC))
    }
}

@Composable
fun RowDivider() = HorizontalDivider(Modifier.padding(start = 66.dp), color = MaterialTheme.colorScheme.surfaceVariant)

@Composable
fun BackBar(title: String, onBack: () -> Unit, trailing: @Composable RowScope.() -> Unit = {}) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        CircleButton(Icons.AutoMirrored.Filled.ArrowBack, L10n.t("common.back"), "back", onBack)
        Text(title, fontSize = 18.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center,
            modifier = Modifier.weight(1f), maxLines = 1, overflow = TextOverflow.Ellipsis)
        Row(Modifier.widthIn(min = 46.dp), horizontalArrangement = Arrangement.End, content = trailing)
    }
}

fun Modifier.cardBorder() = this.border(0.5.dp, Color(0x22000000), RoundedCornerShape(18.dp))
