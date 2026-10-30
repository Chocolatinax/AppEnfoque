package sv.esen.floria

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent

// Detecta qué app se abre. No lee el contenido de la pantalla
// (canRetrieveWindowContent = false).
class BlockerAccessibilityService : AccessibilityService() {
    private val lastLaunchAt = mutableMapOf<String, Long>()

    private var protectedPackages: Set<String> = emptySet()

    override fun onServiceConnected() {
        super.onServiceConnected()
        protectedPackages = ProtectedApps.packages(this)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return

        if (pkg == packageName || !BlockerState.isActive(this)) return
        if (pkg in protectedPackages || pkg !in BlockerState.blockedPackages(this)) return

        val now = SystemClock.elapsedRealtime()
        // eventTime viene en uptimeMillis, lo pasamos a hora normal para medir R1
        val delayMs = (SystemClock.uptimeMillis() - event.eventTime).coerceAtLeast(0L)
        val openedAt = System.currentTimeMillis() - delayMs
        // YouTube manda dos eventos por apertura
        if (now - (lastLaunchAt[pkg] ?: 0L) < 1500) return
        lastLaunchAt[pkg] = now

        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            )
            putExtra(MainActivity.EXTRA_BLOCKED_PACKAGE, pkg)
            putExtra(MainActivity.EXTRA_DETECTED_AT, openedAt)
        }
        startActivity(intent)
    }

    override fun onInterrupt() = Unit
}
