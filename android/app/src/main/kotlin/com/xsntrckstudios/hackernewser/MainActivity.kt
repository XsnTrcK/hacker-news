package com.xsntrckstudios.hackernewser

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "app_icons"

    // Fully-qualified activity-alias names declared in AndroidManifest.xml —
    // exactly one is enabled at a time. Lazy: packageName isn't available
    // until the Activity is attached, which hasn't happened yet at
    // construction time.
    private val iconAliases by lazy {
        mapOf(
            "icon" to "$packageName.AppIconIcon",
            "crayons" to "$packageName.AppIconCrayons",
            "lines" to "$packageName.AppIconLines"
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "setIcon") {
                    val targetAlias = iconAliases[call.argument<String>("icon")]
                    if (targetAlias == null) {
                        result.error("invalid_icon", "Unknown icon", null)
                    } else {
                        setLauncherIcon(targetAlias)
                        result.success(null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    // Matches android:enabled="true" in AndroidManifest.xml — the alias that
    // COMPONENT_ENABLED_STATE_DEFAULT resolves to when a state was never
    // explicitly set (e.g. right after a fresh install).
    private val defaultAlias by lazy { iconAliases.getValue("icon") }

    private fun isEnabled(alias: String): Boolean {
        return when (packageManager.getComponentEnabledSetting(ComponentName(packageName, alias))) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED -> false
            else -> alias == defaultAlias
        }
    }

    private fun setLauncherIcon(targetAlias: String) {
        for (alias in iconAliases.values) {
            val shouldBeEnabled = alias == targetAlias
            // Skip aliases already in the desired state: setComponentEnabledSetting
            // kills the app process even when reasserting the current value, and
            // main.dart resyncs the icon on every cold start, which would otherwise
            // kill the app on every launch.
            if (isEnabled(alias) == shouldBeEnabled) continue
            val state = if (shouldBeEnabled) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }
            // No DONT_KILL_APP flag: the launcher only picks up the new icon
            // once the process restarts, which is the expected (accepted)
            // behavior for an actual icon change.
            packageManager.setComponentEnabledSetting(
                ComponentName(packageName, alias), state, 0
            )
        }
    }
}
