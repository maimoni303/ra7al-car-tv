package com.ra7al.cartv

import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken
import com.ra7al.cartv.player.PlaybackService
import com.ra7al.cartv.ui.AppRoot

class MainActivity : ComponentActivity() {
    private var controller: com.google.common.util.concurrent.ListenableFuture<MediaController>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val shared = if (intent?.action == Intent.ACTION_SEND) intent.getStringExtra(Intent.EXTRA_TEXT) else null
        val demo = intent?.getBooleanExtra("seedDemo", false) == true
        intent?.getStringExtra("uiLang")?.let { App.get(this).settings.setLanguage(it) }
        intent?.getStringExtra("uiAppearance")?.let { App.get(this).settings.setAppearance(it) }
        setContent { AppRoot(sharedText = shared, seedDemo = demo) }
    }

    override fun onStart() {
        super.onStart()
        // Connecting a controller starts the media session service (background playback + notification).
        if (Build.VERSION.SDK_INT >= 26) {
            controller = MediaController.Builder(this, SessionToken(this, ComponentName(this, PlaybackService::class.java))).buildAsync()
        }
    }

    override fun onStop() {
        controller?.let { MediaController.releaseFuture(it) }
        controller = null
        super.onStop()
    }
}
