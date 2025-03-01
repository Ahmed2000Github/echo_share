package com.example.echo_share

import android.app.Activity
import android.content.Intent
import android.provider.Settings
import android.net.Uri
import android.media.projection.MediaProjectionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val RECORDCHANNEL = "screen_record"
    private val CONTROLCHANNEL = "control_channel"
    private lateinit var mediaProjectionManager: MediaProjectionManager
    private val REQUEST_CODE = 1001
     private var width:Int = 1520
    private var height:Int = 2080
companion object {
        var flutterEngineInstance: FlutterEngine? = null
    } 
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngineInstance = flutterEngine
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RECORDCHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startRecording") {
                val arguments = call.arguments as? Map<String, Any> 
                this.width = arguments?.get("width") as? Int ?: 1520 
                this.height = arguments?.get("height") as? Int ?: 2080
                startRecording()
                result.success("Started Recording")
            } else if (call.method == "stopRecording") {
                stopRecording()
                result.success("Stopped Recording")
            } else {
                result.notImplemented()
            }
        }
         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTROLCHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "simulateTap" -> {
                    val x = call.argument<Double>("x")?.toFloat() ?: 0f
                    val y = call.argument<Double>("y")?.toFloat() ?: 0f
                    val serviceName = "com.example.echo_share/com.example.echo_share.ControlService"
                     if (isAccessibilityServiceEnabled(serviceName)) {
                        println("AccessibilityService is enabled")
                        simulateTap(x, y)
                        result.success("Perform tap")
                    } else {
                        println("AccessibilityService is not enabled")
                        openAccessibilitySettings() 
                        result.success( "AccessibilityService is not enabled")
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun simulateTap(x: Float, y: Float) {
        val service = ControlService.getInstance()
        if (service != null) {
            service.simulateTap(x, y)
        } else {
            println("ControlService is not running")
        }
    }
    

     private fun isAccessibilityServiceEnabled(serviceName: String): Boolean {
     
            val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
         println("Enabled AccessibilityServices: $enabledServices")
        return enabledServices?.contains(serviceName) ?: false
       
    }

    private fun openAccessibilitySettings() {
           try {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
         }
        catch(e:Exception) {
            println("Failed to start activity ... ")
        }
        
    }



    private fun startRecording() {
        mediaProjectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(mediaProjectionManager.createScreenCaptureIntent(), REQUEST_CODE)
    }

    private fun stopRecording() {
        val stopIntent = Intent(this, ScreenRecordService::class.java)
        stopService(stopIntent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            val intent = Intent(this, ScreenRecordService::class.java)
            intent.putExtra("resultCode", resultCode)
            intent.putExtra("data", data)
            intent.putExtra("width", width) 
            intent.putExtra("height", height)
            startService(intent)
        }
    }
}
