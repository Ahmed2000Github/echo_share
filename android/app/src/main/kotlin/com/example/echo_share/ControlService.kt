// SimulateTapService.kt
package com.example.echo_share

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.view.accessibility.AccessibilityEvent

class ControlService : AccessibilityService() {
      companion object {
        private var instance: ControlService? = null

        fun getInstance(): ControlService? {
            return instance
        }
    }

    override fun onServiceConnected() {
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Handle accessibility events if needed
    }
    
     override fun onInterrupt() {
        // Handle service interruption
    }

    fun simulateTap(x: Float, y: Float) {
        val builder = GestureDescription.Builder()
        val path = Path()
        path.moveTo(x, y)
        builder.addStroke(GestureDescription.StrokeDescription(path, 0, 50))
        dispatchGesture(builder.build(), null, null)
    }
        fun simulateSwipe(startX: Float, startY: Float, endX: Float, endY: Float, duration: Long) {
        val builder = GestureDescription.Builder()
        val path = Path()

        // Define the swipe path
        path.moveTo(startX, startY)
        path.lineTo(endX, endY)

        // Add the swipe gesture to the builder
        builder.addStroke(GestureDescription.StrokeDescription(path, 0, duration))

        // Dispatch the gesture
        dispatchGesture(builder.build(), null, null)
    }
}