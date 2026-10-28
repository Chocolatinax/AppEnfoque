package com.example.enfoque_app

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.telecom.TelecomManager

/**
 * Apps que Floria NUNCA bloquea: Ajustes y Teléfono.
 *
 * - Ajustes: si se bloqueara, el usuario no podría entrar a Accesibilidad para
 *   apagar el servicio durante la sesión.
 * - Teléfono: tiene que estar disponible para llamadas de emergencia.
 *
 * No aparecen en la lista para elegir, y el servicio las ignora aunque una tarea
 * vieja las tenga guardadas. Se le pregunta a Android cuáles son en ESTE teléfono,
 * porque el paquete cambia según la marca (Samsung, Xiaomi, Motorola...).
 */
object ProtectedApps {
    fun packages(context: Context): Set<String> {
        val set = mutableSetOf(
            "com.android.settings", "com.android.emergency",
            "com.android.dialer", "com.google.android.dialer"
        )
        (context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager)
            ?.defaultDialerPackage?.let { set.add(it) }
        val pm = context.packageManager
        for (intent in listOf(Intent(Settings.ACTION_SETTINGS), Intent(Intent.ACTION_DIAL))) {
            pm.queryIntentActivities(intent, 0).forEach { set.add(it.activityInfo.packageName) }
        }
        return set
    }
}
