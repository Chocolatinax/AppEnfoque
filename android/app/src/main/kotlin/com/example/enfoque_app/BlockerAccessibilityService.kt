package com.example.enfoque_app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent

/**
 * Servicio de Accesibilidad que detecta cuándo se abre una app.
 *
 * Android le avisa cada vez que cambia la ventana en primer plano
 * (TYPE_WINDOW_STATE_CHANGED). Si hay una sesión de enfoque activa y la app
 * abierta está en la lista de bloqueadas, Floria vuelve al frente y muestra
 * la pantalla de recordatorio (requerimiento R1: en menos de 2 segundos).
 *
 * El servicio NO lee el contenido de las pantallas: solo el nombre del paquete
 * de la app que se abrió (canRetrieveWindowContent = false).
 */
class BlockerAccessibilityService : AccessibilityService() {

    private var lastLaunchAt = 0L

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return

        // Ignorar a Floria misma y cuando no hay sesión activa
        if (pkg == packageName || !BlockerState.isActive(this)) return
        if (pkg !in BlockerState.blockedPackages(this)) return

        // Evitar abrir Floria varias veces seguidas por eventos repetidos
        val now = SystemClock.elapsedRealtime()
        if (now - lastLaunchAt < 800) return
        lastLaunchAt = now

        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            )
            putExtra(MainActivity.EXTRA_BLOCKED_PACKAGE, pkg)
            putExtra(MainActivity.EXTRA_DETECTED_AT, System.currentTimeMillis())
        }
        startActivity(intent)
    }

    override fun onInterrupt() = Unit
}
