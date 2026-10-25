package com.example.enfoque_app

import android.content.Context

/**
 * Estado del bloqueo guardado en SharedPreferences.
 *
 * Se guarda fuera de Flutter para que el Servicio de Accesibilidad lo pueda leer
 * aunque la parte de Flutter no esté corriendo en ese momento.
 */
object BlockerState {
    private const val PREFS = "floria_blocker"
    private const val KEY_ACTIVE = "active"
    private const val KEY_PACKAGES = "packages"

    fun start(context: Context, packages: List<String>) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(KEY_ACTIVE, packages.isNotEmpty())
            .putStringSet(KEY_PACKAGES, packages.toSet())
            .apply()
    }

    fun stop(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(KEY_ACTIVE, false)
            .apply()
    }

    fun isActive(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY_ACTIVE, false)

    fun blockedPackages(context: Context): Set<String> =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet()
}
