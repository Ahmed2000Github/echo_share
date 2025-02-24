package com.example.echo_share

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "screen_record"
    private lateinit var mediaProjectionManager: MediaProjectionManager
    private val REQUEST_CODE = 1001
companion object {
        var flutterEngineInstance: FlutterEngine? = null
    } 
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngineInstance = flutterEngine
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "startRecording") {
                startRecording()
                result.success("Started Recording")
            } else if (call.method == "stopRecording") {
                stopRecording()
                result.success("Stopped Recording")
            } else {
                result.notImplemented()
            }
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
            startService(intent)
        }
    }
}
