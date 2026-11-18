package com.ra7al.cartv

import android.content.Intent
import android.graphics.Bitmap
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/** Opens every screen and saves a screenshot of each, in English/light and Arabic/dark. */
@RunWith(AndroidJUnit4::class)
class ScreenTourTest {
    @get:Rule val compose = createEmptyComposeRule()

    @Test fun tourEnglishLight() = tour("en", "light")
    @Test fun tourArabicDark() = tour("ar", "dark")

    private fun tour(lang: String, appearance: String) {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val intent = Intent(ctx, MainActivity::class.java)
            .putExtra("seedDemo", true).putExtra("uiLang", lang).putExtra("uiAppearance", appearance)
        ActivityScenario.launch<MainActivity>(intent).use {
            val p = "$lang-$appearance"
            compose.waitUntil(15_000) { compose.onAllNodesWithTag("channel-Top Gear (720p)", useUnmergedTree = true).fetchSemanticsNodes().isNotEmpty() }
            shot("$p-01-home")
            compose.onNodeWithTag("sourceMenu").performClick(); compose.waitForIdle(); shot("$p-02-source-menu")
            pressBack()

            compose.onNodeWithTag("search").performTextInput("Sports"); compose.waitForIdle()
            compose.onAllNodesWithTag("channel-Sports One", useUnmergedTree = true).onFirst().assertExists()
            shot("$p-03-search")
            compose.onNodeWithTag("search").performTextClearance()

            compose.onAllNodesWithTag("channel-Top Gear (720p)", useUnmergedTree = true).onFirst().performClick()
            Thread.sleep(4000); shot("$p-04-player")
            compose.onNodeWithTag("closePlayer").performClick(); compose.waitForIdle(); shot("$p-05-mini-player")

            for ((i, name) in listOf(1 to "06-browser", 2 to "07-cast", 3 to "08-library")) {
                compose.onNodeWithTag("tab-$i", useUnmergedTree = true).performClick(); compose.waitForIdle(); Thread.sleep(800)
                shot("$p-$name")
            }
            compose.onNodeWithTag("segment-1").performClick(); compose.waitForIdle(); shot("$p-09-library-favorites")

            compose.onNodeWithTag("tab-4", useUnmergedTree = true).performClick(); compose.waitForIdle(); shot("$p-10-settings")
            compose.onNodeWithTag("manageSources").performClick(); compose.waitForIdle(); shot("$p-11-manage-sources")
            compose.onNodeWithTag("source-demo").performClick(); compose.waitForIdle(); shot("$p-12-source-detail")
            compose.onNodeWithTag("back").performClick(); compose.waitForIdle()
            compose.onNodeWithTag("addSource").performClick(); compose.waitForIdle(); shot("$p-13-add-source")
            compose.onNodeWithTag("findLinks").performClick(); compose.waitForIdle(); Thread.sleep(800); shot("$p-14-find-links")
        }
    }

    private fun pressBack() {
        InstrumentationRegistry.getInstrumentation().uiAutomation.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_BACK)
        compose.waitForIdle()
    }

    private fun shot(name: String) {
        val ctx = InstrumentationRegistry.getInstrumentation().targetContext
        val dir = File(ctx.getExternalFilesDir(null), "shots").apply { mkdirs() }
        val bmp = InstrumentationRegistry.getInstrumentation().uiAutomation.takeScreenshot() ?: return
        File(dir, "$name.png").outputStream().use { bmp.compress(Bitmap.CompressFormat.PNG, 100, it) }
    }
}
