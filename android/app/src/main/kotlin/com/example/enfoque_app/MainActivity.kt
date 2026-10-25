package com.example.enfoque_app

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Bundle
import android.provider.Settings
import android.provider.Telephony
import android.telecom.TelecomManager
import java.io.ByteArrayOutputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Actividad principal de Floria.
 *
 * Expone el canal "floria/app_blocker" para que Flutter controle el bloqueo:
 * - isServiceEnabled: ¿el usuario activó el Servicio de Accesibilidad de Floria?
 * - openAccessibilitySettings: abre los ajustes de Accesibilidad de Android.
 * - startBlocking(packages): empieza a bloquear esa lista de apps.
 * - stopBlocking: deja de bloquear (descansos, pausas o fin de la sesión).
 * - getLaunchableApps: lista las apps instaladas que se pueden abrir desde el menú.
 *
 * Y avisa a Flutter con "blockedAppOpened" cuando el servicio detecta una app bloqueada.
 */
class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL = "floria/app_blocker"
        const val EXTRA_BLOCKED_PACKAGE = "floria.blocked_package"
        const val EXTRA_DETECTED_AT = "floria.detected_at"
    }

    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "isServiceEnabled" -> result.success(isBlockerServiceEnabled())
                    "openAccessibilitySettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }
                    "startBlocking" -> {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        BlockerState.start(this@MainActivity, packages)
                        result.success(null)
                    }
                    "stopBlocking" -> {
                        BlockerState.stop(this@MainActivity)
                        result.success(null)
                    }
                    "getLaunchableApps" -> {
                        // Leer íconos de muchas apps toma tiempo: se hace fuera del hilo principal
                        Thread {
                            val apps = loadLaunchableApps()
                            runOnUiThread { result.success(apps) }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        notifyBlockedApp(intent)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Si Floria estaba cerrada, el aviso llega cuando Flutter ya está listo
        notifyBlockedApp(intent)
    }

    private fun notifyBlockedApp(intent: Intent?) {
        val pkg = intent?.getStringExtra(EXTRA_BLOCKED_PACKAGE) ?: return
        val detectedAt = intent.getLongExtra(EXTRA_DETECTED_AT, System.currentTimeMillis())
        intent.removeExtra(EXTRA_BLOCKED_PACKAGE)
        channel?.invokeMethod(
            "blockedAppOpened",
            mapOf("package" to pkg, "detectedAt" to detectedAt)
        )
    }

    /**
     * Apps que aparecen en el menú de apps del teléfono (las únicas que tiene sentido bloquear).
     * La pantalla de inicio, el teclado y las partes internas del sistema no aparecen aquí,
     * así que nunca se pueden bloquear por accidente.
     */
    private fun loadLaunchableApps(): List<Map<String, Any>> {
        val pm = packageManager
        val launcherIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val essentials = essentialPackages()

        return pm.queryIntentActivities(launcherIntent, 0)
            .distinctBy { it.activityInfo.packageName }
            .filter { it.activityInfo.packageName != packageName } // nunca bloquear a Floria
            .map { info ->
                val pkg = info.activityInfo.packageName
                mapOf(
                    "name" to info.loadLabel(pm).toString(),
                    "package" to pkg,
                    "icon" to drawableToPng(info.loadIcon(pm)),
                    "essential" to (pkg in essentials)
                )
            }
            .sortedBy { (it["name"] as String).lowercase() }
    }

    /** Apps esenciales: el atajo "Todas" no las marca (teléfono, mensajes, ajustes, reloj...). */
    private fun essentialPackages(): Set<String> {
        val set = mutableSetOf(
            "com.android.settings",
            "com.google.android.dialer", "com.android.dialer",
            "com.google.android.contacts", "com.android.contacts",
            "com.google.android.apps.messaging", "com.android.mms",
            "com.google.android.deskclock", "com.android.deskclock",
            "com.android.emergency"
        )
        (getSystemService(Context.TELECOM_SERVICE) as? TelecomManager)?.defaultDialerPackage?.let { set.add(it) }
        Telephony.Sms.getDefaultSmsPackage(this)?.let { set.add(it) }
        return set
    }

    private fun drawableToPng(drawable: Drawable): ByteArray {
        val size = 96
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(canvas)
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        return out.toByteArray()
    }

    /** Revisa en los ajustes del sistema si el servicio de Floria está activado. */
    private fun isBlockerServiceEnabled(): Boolean {
        val expected = ComponentName(this, BlockerAccessibilityService::class.java)
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        return enabled.split(':').any {
            ComponentName.unflattenFromString(it) == expected
        }
    }
}
