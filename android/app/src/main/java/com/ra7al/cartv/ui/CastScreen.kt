package com.ra7al.cartv.ui

import android.app.Presentation
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Bundle
import android.view.Display
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.media3.ui.PlayerView
import com.ra7al.cartv.App

/** Shows the player full screen on a connected external display (car screen / TV). */
class CarPresentation(context: Context, display: Display) : Presentation(context, display) {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(PlayerView(context).apply {
            player = App.get(context).player.player
            useController = false
            setBackgroundColor(android.graphics.Color.BLACK)
        })
    }
}

@Composable
fun rememberExternalDisplay(): Display? {
    val ctx = LocalContext.current
    val dm = remember { ctx.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager }
    var display by remember { mutableStateOf(dm.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION).firstOrNull()) }
    DisposableEffect(dm) {
        val l = object : DisplayManager.DisplayListener {
            fun update() { display = dm.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION).firstOrNull() }
            override fun onDisplayAdded(id: Int) = update()
            override fun onDisplayRemoved(id: Int) = update()
            override fun onDisplayChanged(id: Int) = update()
        }
        dm.registerDisplayListener(l, null)
        onDispose { dm.unregisterDisplayListener(l) }
    }
    return display
}

/** Keeps a presentation on the external display while one is connected (whole app, not only this tab). */
@Composable
fun ExternalDisplayHost() {
    val ctx = LocalContext.current
    val display = rememberExternalDisplay()
    DisposableEffect(display) {
        val p = display?.let { runCatching { CarPresentation(ctx, it).also { pr -> pr.show() } }.getOrNull() }
        onDispose { runCatching { p?.dismiss() } }
    }
}

@Composable
fun CastScreen() {
    val ctx = LocalContext.current
    val app = App.get(ctx)
    val display = rememberExternalDisplay()
    val current by app.player.current.collectAsState()
    val connected = display != null
    val step = when { !connected -> 1; current == null -> 3; else -> 4 }

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState())) {
        LargeTitle(L10n.t("tab.cast"))
        Column(Modifier.padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(24.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(30.dp)) {
                DeviceTile(Icons.Filled.PhoneAndroid, "Huawei", true)
                Icon(Icons.AutoMirrored.Filled.ArrowForward, null, tint = if (connected) BrandGreen else Muted, modifier = Modifier.size(30.dp))
                DeviceTile(Icons.Filled.DirectionsCar, L10n.t("cast.androidCar"), connected)
            }
            Text(L10n.t(if (connected) "cast.screenConnected" else "cast.androidTitle"), fontSize = 28.sp,
                fontWeight = FontWeight.Bold, textAlign = TextAlign.Center)
            Text(if (connected && current != null) L10n.t("cast.externalPlaying") else L10n.t("cast.androidBody"),
                color = Muted, fontSize = 17.sp, textAlign = TextAlign.Center)
            Row(Modifier.clip(CircleShape).background(if (connected) BrandGreen.copy(alpha = 0.14f) else Fill)
                .padding(horizontal = 18.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(12.dp).clip(CircleShape).background(if (connected) BrandGreen else Color.Gray))
                Spacer(Modifier.width(10.dp))
                Text(L10n.t(if (connected) "cast.connected" else "cast.notConnected"),
                    color = if (connected) BrandGreen else Muted, fontWeight = FontWeight.Medium)
            }
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(Card)) {
                StepRow(1, step, Icons.Filled.Tv, "cast.androidStep1", "cast.androidStep1Body")
                RowDivider()
                StepRow(2, step, Icons.Filled.CastConnected, "cast.androidStep2", "cast.androidStep2Body")
                RowDivider()
                StepRow(3, step, Icons.Filled.PlayArrow, "cast.androidStep3", "cast.androidStep3Body")
            }
            Button({ openCastSettings(ctx) }, Modifier.fillMaxWidth().height(62.dp).testTag("startProjection"),
                shape = CircleShape, colors = ButtonDefaults.buttonColors(containerColor = BrandGreen)) {
                Icon(Icons.Filled.CastConnected, null)
                Spacer(Modifier.width(10.dp))
                Text(L10n.t("cast.startProjection"), fontSize = 20.sp, fontWeight = FontWeight.SemiBold)
            }
            Text(L10n.t("cast.parked"), color = Muted, fontSize = 13.sp, textAlign = TextAlign.Center)
        }
    }
}

@Composable
private fun DeviceTile(icon: ImageVector, label: String, active: Boolean) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(Modifier.size(112.dp).shadow(4.dp, RoundedCornerShape(30.dp)).clip(RoundedCornerShape(30.dp)).background(Card),
            contentAlignment = Alignment.Center) {
            Icon(icon, null, tint = if (active) BrandGreen else Color(0xFFC7C7CC), modifier = Modifier.size(54.dp))
        }
        Spacer(Modifier.height(10.dp))
        Text(label, color = Muted)
    }
}

@Composable
private fun StepRow(n: Int, current: Int, icon: ImageVector, title: String, body: String) {
    val isCurrent = n == current
    val done = n < current
    Row(Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 16.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(56.dp), contentAlignment = Alignment.Center) {
            when {
                isCurrent -> Box(Modifier.size(46.dp).border(3.dp, BrandGreen, CircleShape), contentAlignment = Alignment.Center) {
                    Icon(icon, null, tint = BrandGreen)
                }
                done -> Box(Modifier.size(44.dp).clip(CircleShape).background(BrandGreen), contentAlignment = Alignment.Center) {
                    Icon(Icons.Filled.Check, null, tint = Color.White)
                }
                else -> Box(Modifier.size(44.dp).clip(CircleShape).background(Fill), contentAlignment = Alignment.Center) {
                    Text("$n", color = Muted, fontWeight = FontWeight.SemiBold)
                }
            }
        }
        Spacer(Modifier.width(14.dp))
        Column {
            Text(L10n.t(title), fontSize = 19.sp, fontWeight = if (isCurrent) FontWeight.SemiBold else FontWeight.Normal,
                color = if (isCurrent || done) MaterialTheme.colorScheme.onSurface else Muted)
            Text(L10n.t(body), color = Muted, fontSize = 15.sp)
        }
    }
}
