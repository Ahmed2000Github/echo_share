package com.example.echo_share

import android.app.Activity
import android.content.Intent
import android.provider.Settings
import android.net.Uri
import android.os.Looper
import android.os.Handler
import android.app.PendingIntent
import android.app.PendingIntent.CanceledException
import android.media.projection.MediaProjectionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val RECORDCHANNEL = "screen_record"
    private val CONTROLCHANNEL = "control_channel"
    private lateinit var mediaProjectionManager: MediaProjectionManager
    private val REQUEST_CODE = 1001
    private val REQUEST_CODE_ACCESSIBILITY_SETTINGS = 1002
     private var width:Int = 1520
    private var height:Int = 2080
    private var pendingResultForRecord: MethodChannel.Result? = null
    private var pendingResultForAccessibilityCheck: MethodChannel.Result? = null
companion object {
        var flutterEngineInstance: FlutterEngine? = null
    } 
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngineInstance = flutterEngine
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RECORDCHANNEL).setMethodCallHandler { call, result ->
            pendingResultForRecord = result
            if (call.method == "startRecording") {
                val arguments = call.arguments as? Map<String, Any> 
                this.width = arguments?.get("width") as? Int ?: 1520 
                this.height = arguments?.get("height") as? Int ?: 2080
                startRecording()
                
            } else if (call.method == "stopRecording") {
                stopRecording()
                result.success("Stopped Recording")
            } else {
                result.notImplemented()
            }
        }
         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTROLCHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "moveToBackground" -> {
                    moveToBackground()
                    result.success(null)
                }
                "checkAccessibilityService"->{
                    val serviceName = "com.example.echo_share/com.example.echo_share.ControlService"
                    result.success(isAccessibilityServiceEnabled(serviceName))
                }
                "openAccessibilitySettings"->{
                     pendingResultForAccessibilityCheck = result
                     openAccessibilitySettings() 
                }
                "simulateTap" -> {
                    val x = call.argument<Double>("x")?.toFloat() ?: 0f
                    val y = call.argument<Double>("y")?.toFloat() ?: 0f
                    
                     val service = ControlService.getInstance()
                    if (service != null) {
                         service.simulateTap(x, y)
                        result.success(null)
                    } else {
                        result.success("ControlService is not running")
                    }
                }
                 "simulateSwipe" -> {
                    // Extract swipe data from the method call
                    val startX = call.argument<Double>("startX")?.toFloat() ?: 0f
                    val startY = call.argument<Double>("startY")?.toFloat() ?: 0f
                    val endX = call.argument<Double>("endX")?.toFloat() ?: 0f
                    val endY = call.argument<Double>("endY")?.toFloat() ?: 0f
                    val duration = call.argument<Int>("duration")?.toLong() ?: 500L

                    // Call the simulateSwipe method
                    val service = ControlService.getInstance()
                    if (service != null) {
                        service.simulateSwipe(startX, startY, endX, endY, duration)
                        result.success(null)
                    } else {
                        result.success("ControlService is not running")
                    }
                }
                else -> result.notImplemented()
            }
        }
    }


    fun moveToBackground() {
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_HOME)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }
    private fun bringAppToForeground() {
      val intent = Intent(this, MainActivity::class.java).apply {
    flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
    val pendingIntent = PendingIntent.getActivity(
    this@MainActivity, 
    0,
    intent,
    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
)
try {
        pendingIntent.send()  
    } catch (e: CanceledException) {
        e.printStackTrace()
    }   
}
}

     private fun isAccessibilityServiceEnabled(serviceName: String): Boolean {
     
            val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains(serviceName) ?: false
       
    }

    private fun openAccessibilitySettings() {
           try {
            bringAppToForeground()
             Handler(Looper.getMainLooper()).postDelayed({
                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivityForResult(intent, REQUEST_CODE_ACCESSIBILITY_SETTINGS)
        }, 100)

         }
        catch(e:Exception) {
            println("Failed to start activity ... ")
        }
        
    }
private fun checkAccessibilityServiceAndNotifyFlutter(result: MethodChannel.Result? = null) {
        val serviceName = "com.example.echo_share/com.example.echo_share.ControlService"
        if (isAccessibilityServiceEnabled(serviceName)) {
            println("AccessibilityService is enabled")
            result?.success(true) 
        } else {
            println("AccessibilityService is not enabled")
            result?.success(false) 
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
            pendingResultForRecord?.success("Started Recording")
            pendingResultForRecord = null
        }else if(requestCode == REQUEST_CODE && resultCode != Activity.RESULT_OK){
            pendingResultForRecord?.success("Canceled")
        }
        else if (requestCode == REQUEST_CODE_ACCESSIBILITY_SETTINGS) {
             checkAccessibilityServiceAndNotifyFlutter(pendingResultForAccessibilityCheck)
            pendingResultForAccessibilityCheck = null
        }
    }
}
