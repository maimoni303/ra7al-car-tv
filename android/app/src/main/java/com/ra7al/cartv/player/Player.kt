package com.ra7al.cartv.player

import android.app.Application
import android.content.Context
import android.hardware.display.DisplayManager
import android.view.Display
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import com.ra7al.cartv.App
import com.ra7al.cartv.data.Channel
import com.ra7al.cartv.ui.L10n
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/** One shared player for the phone screen, the mini player and an external display. */
class PlayerController(private val app: Application) {
    val player: ExoPlayer = ExoPlayer.Builder(app)
        .setAudioAttributes(AudioAttributes.Builder().setUsage(C.USAGE_MEDIA)
            .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE).build(), true)
        .setHandleAudioBecomingNoisy(true)
        .build()

    private val _current = MutableStateFlow<Channel?>(null)
    val current: StateFlow<Channel?> = _current
    private val _isPlaying = MutableStateFlow(false)
    val isPlaying: StateFlow<Boolean> = _isPlaying
    private val _buffering = MutableStateFlow(false)
    val buffering: StateFlow<Boolean> = _buffering
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error
    private var queue: List<Channel> = emptyList()

    init {
        player.addListener(object : Player.Listener {
            override fun onIsPlayingChanged(isPlaying: Boolean) { _isPlaying.value = isPlaying }
            override fun onPlaybackStateChanged(state: Int) { _buffering.value = state == Player.STATE_BUFFERING }
            override fun onPlayerError(error: PlaybackException) {
                _error.value = L10n.t("player.failed") + "\n" + (error.message ?: "")
            }
        })
    }

    fun play(c: Channel, list: List<Channel>? = null) {
        if (list != null) queue = list
        if (queue.none { it.id == c.id }) queue = listOf(c) + queue
        _current.value = c
        _error.value = null
        val item = MediaItem.Builder()
            .setUri(c.url)
            .setMediaId(c.id)
            .setMediaMetadata(MediaMetadata.Builder().setTitle(c.name).setArtist(c.group).build())
            .build()
        player.setMediaItem(item)
        player.prepare()
        player.play()
        App.get(app).store.markWatched(c)
    }

    fun toggle() { if (player.isPlaying) player.pause() else { if (_error.value != null) retry() else player.play() } }
    fun retry() { _current.value?.let { play(it) } }
    fun next() = step(1)
    fun previous() = step(-1)
    fun stop() { player.stop(); player.clearMediaItems(); _current.value = null; _error.value = null }

    private fun step(d: Int) {
        if (queue.isEmpty()) return
        val i = queue.indexOfFirst { it.id == _current.value?.id }.coerceAtLeast(0)
        play(queue[(i + d + queue.size) % queue.size])
    }

    /** A connected external screen (wireless projection / HDMI) that can show video on its own. */
    fun presentationDisplay(context: Context): Display? {
        val dm = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        return dm.getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION).firstOrNull()
    }
}

/** Keeps playback alive in the background and shows media controls in the notification. */
class PlaybackService : MediaSessionService() {
    private var session: MediaSession? = null

    override fun onCreate() {
        super.onCreate()
        session = MediaSession.Builder(this, App.get(this).player.player).build()
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? = session

    override fun onDestroy() {
        session?.release()
        session = null
        super.onDestroy()
    }
}
