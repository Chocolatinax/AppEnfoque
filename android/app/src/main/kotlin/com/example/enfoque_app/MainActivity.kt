package com.example.enfoque_app

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Bundle
import android.provider.AlarmClock
import android.provider.ContactsContract
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
 * - startBlocking(packages, windows): bloquea esas apps dentro del horario de enfoque.
 * - stopBlocking: deja de bloquear (descansos, pausas o fin de la sesión).
 * - getLaunchableApps: lista las apps instaladas que se pueden abrir desde el menú.
 * - consumePendingBlockedApp: aviso guardado si Floria estaba cerrada cuando se abrió una app bloqueada.
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

    /** Aviso que llegó con Floria cerrada (Flutter todavía no estaba listo para recibirlo). */
    private var pendingBlockedApp: Map<String, Any>? = null

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
                        // Horario de los bloques de enfoque: [inicio1, fin1, inicio2, fin2, ...]
                        val windows = call.argument<List<Number>>("windows")?.map { it.toLong() } ?: emptyList()
                        BlockerState.start(this@MainActivity, packages, windows)
                        result.success(null)
                    }
                    "stopBlocking" -> {
                        BlockerState.stop(this@MainActivity)
                        result.success(null)
                    }
                    "consumePendingBlockedApp" -> {
                        result.success(pendingBlockedApp)
                        pendingBlockedApp = null
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
        setIntent(intent) // que getIntent() devuelva el intent más reciente
        // Floria ya estaba abierta: avisar a Flutter de inmediato
        blockedAppFrom(intent)?.let { channel?.invokeMethod("blockedAppOpened", it) }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Floria estaba cerrada: Flutter todavía no escucha, así que el aviso se guarda
        // y la sesión lo pide al retomarse (consumePendingBlockedApp)
        pendingBlockedApp = blockedAppFrom(intent)
    }

    private fun blockedAppFrom(intent: Intent?): Map<String, Any>? {
        val pkg = intent?.getStringExtra(EXTRA_BLOCKED_PACKAGE) ?: return null
        val detectedAt = intent.getLongExtra(EXTRA_DETECTED_AT, System.currentTimeMillis())
        intent.removeExtra(EXTRA_BLOCKED_PACKAGE)
        return mapOf("package" to pkg, "detectedAt" to detectedAt)
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
        val protected = ProtectedApps.packages(this) // Ajustes y Teléfono: nunca se bloquean

        return pm.queryIntentActivities(launcherIntent, 0)
            .distinctBy { it.activityInfo.packageName }
            .filter { it.activityInfo.packageName != packageName } // nunca bloquear a Floria
            .filter { it.activityInfo.packageName !in protected }
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

    /**
     * Apps esenciales: el atajo "Todas" no las marca (teléfono, mensajes, ajustes, reloj, contactos).
     *
     * En vez de una lista fija de paquetes (que cambia según la marca: Samsung, Xiaomi...),
     * se le pregunta a Android qué app abre cada cosa en ESTE teléfono.
     */
    private fun essentialPackages(): Set<String> {
        val set = mutableSetOf(
            // Respaldo por si alguna consulta no responde
            "com.android.settings", "com.android.emergency",
            "com.google.android.dialer", "com.google.android.apps.messaging",
            "com.google.android.deskclock", "com.google.android.contacts"
        )
        (getSystemService(Context.TELECOM_SERVICE) as? TelecomManager)?.defaultDialerPackage?.let { set.add(it) }
        Telephony.Sms.getDefaultSmsPackage(this)?.let { set.add(it) }

        val intents = listOf(
            Intent(Settings.ACTION_SETTINGS),                 // Ajustes
            Intent(AlarmClock.ACTION_SHOW_ALARMS),            // Reloj
            Intent(Intent.ACTION_DIAL),                       // Teléfono
            Intent(Intent.ACTION_VIEW, ContactsContract.Contacts.CONTENT_URI) // Contactos
        )
        for (intent in intents) {
            packageManager.queryIntentActivities(intent, 0)
                .forEach { set.add(it.activityInfo.packageName) }
        }
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
