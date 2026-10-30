package sv.esen.floria

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.telecom.TelecomManager

// Ajustes y Teléfono nunca se bloquean: para poder apagar el servicio
// y por llamadas de emergencia.
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
