package sv.esen.floria

import android.content.Context

// Guardamos los horarios de enfoque (no solo una hora de fin) para que
// cada ronda bloquee aunque Floria esté cerrada.
object BlockerState {
    private const val PREFS = "floria_blocker"
    private const val KEY_ACTIVE = "active"
    private const val KEY_PACKAGES = "packages"
    private const val KEY_WINDOWS = "windows"

    fun start(context: Context, packages: List<String>, windows: List<Long>) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(KEY_ACTIVE, packages.isNotEmpty() && windows.size >= 2)
            .putStringSet(KEY_PACKAGES, packages.toSet())
            .putString(KEY_WINDOWS, windows.joinToString(","))
            .apply()
    }

    fun stop(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(KEY_ACTIVE, false)
            .remove(KEY_WINDOWS)
            .apply()
    }

    fun isActive(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ACTIVE, false)) return false
        val times = prefs.getString(KEY_WINDOWS, "")
            ?.split(',')
            ?.mapNotNull { it.toLongOrNull() }
            ?: return false
        val now = System.currentTimeMillis()
        for (i in 0 until times.size - 1 step 2) {
            if (now >= times[i] && now < times[i + 1]) return true
        }
        return false
    }

    fun blockedPackages(context: Context): Set<String> =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet()
}
