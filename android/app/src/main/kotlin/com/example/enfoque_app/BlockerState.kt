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
    private const val KEY_UNTIL = "until"

    /**
     * Empieza a bloquear [packages] hasta [untilMillis] (fin del bloque de enfoque).
     * La hora de vencimiento evita que el bloqueo quede activo para siempre si
     * Floria se cierra y no se vuelve a abrir.
     */
    fun start(context: Context, packages: List<String>, untilMillis: Long) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(KEY_ACTIVE, packages.isNotEmpty())
            .putStringSet(KEY_PACKAGES, packages.toSet())
            .putLong(KEY_UNTIL, untilMillis)
            .apply()
    }

    fun stop(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(KEY_ACTIVE, false)
            .apply()
    }

    fun isActive(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_ACTIVE, false) &&
            System.currentTimeMillis() < prefs.getLong(KEY_UNTIL, Long.MAX_VALUE)
    }

    fun blockedPackages(context: Context): Set<String> =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet()
}
