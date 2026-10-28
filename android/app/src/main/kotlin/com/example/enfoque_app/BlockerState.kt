package com.example.enfoque_app

import android.content.Context

/**
 * Estado del bloqueo guardado en SharedPreferences.
 *
 * Se guarda fuera de Flutter para que el Servicio de Accesibilidad lo pueda leer
 * aunque Floria esté cerrada.
 *
 * En vez de "bloquear hasta las HH:MM", se guarda el HORARIO de los bloques de
 * enfoque que faltan (por ejemplo 10:00–10:25 y 10:30–10:55). Así, en Pomodoro,
 * cada ronda bloquea a su hora y los descansos quedan libres aunque nadie abra
 * Floria. Al pasar el último bloque, el bloqueo se libera solo.
 */
object BlockerState {
    private const val PREFS = "floria_blocker"
    private const val KEY_ACTIVE = "active"
    private const val KEY_PACKAGES = "packages"
    private const val KEY_WINDOWS = "windows"

    /**
     * Bloquea [packages] dentro de los horarios [windows]:
     * pares inicio/fin en milisegundos, [inicio1, fin1, inicio2, fin2, ...].
     */
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

    /** ¿Ahora mismo estamos dentro de un bloque de enfoque? */
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
