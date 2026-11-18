package com.ra7al.cartv

import android.app.Application
import android.content.Context
import com.ra7al.cartv.data.BrowserStore
import com.ra7al.cartv.data.LibraryStore
import com.ra7al.cartv.data.PlaylistStore
import com.ra7al.cartv.data.SettingsStore
import com.ra7al.cartv.player.PlayerController

class App : Application() {
    lateinit var settings: SettingsStore
    lateinit var store: PlaylistStore
    lateinit var library: LibraryStore
    lateinit var browser: BrowserStore
    lateinit var player: PlayerController

    override fun onCreate() {
        super.onCreate()
        settings = SettingsStore(this)
        store = PlaylistStore(this)
        library = LibraryStore(this)
        browser = BrowserStore(this)
        player = PlayerController(this)
    }

    companion object {
        fun get(context: Context): App = context.applicationContext as App
    }
}
