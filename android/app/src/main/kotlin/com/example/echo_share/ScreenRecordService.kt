package com.example.echo_share

import android.app.*
import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Environment
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.io.File
import io.flutter.plugin.common.MethodChannel
import android.view.Surface
import android.graphics.ImageFormat
import android.media.Image
import android.media.ImageReader
import android.graphics.PixelFormat
import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import java.nio.ByteBuffer
import java.io.ByteArrayOutputStream

class ScreenRecordService : Service() {

    private var mediaProjection: MediaProjection? = null
    private lateinit var mediaRecorder: MediaRecorder
    private lateinit var mediaProjectionManager: MediaProjectionManager
     private var imageReader: ImageReader? = null
    val flutterEngine = MainActivity.flutterEngineInstance

    override fun onCreate() {
        super.onCreate()
        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        createNotification()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val resultCode = intent?.getIntExtra("resultCode", Activity.RESULT_CANCELED) ?: Activity.RESULT_CANCELED
        val data = intent?.getParcelableExtra<Intent>("data")

        if (resultCode == Activity.RESULT_OK && data != null) {
            mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)
            startRecording()
        }

        return START_STICKY
    }

    private fun startRecording() {

        // if (flutterEngine != null) {
        //   println("QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ")

        //         val channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "test")
        //         channel.invokeMethod("yourMethod", "yourArguments")
        //     } else {
        //         println("EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE")
        //     }
      imageReader = ImageReader.newInstance(1280, 720,  PixelFormat.RGBA_8888, 2)
        val filePath = "${getExternalFilesDir(Environment.DIRECTORY_MOVIES)}/screen_record.mp4"
        
        mediaRecorder = MediaRecorder().apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setVideoSource(MediaRecorder.VideoSource.SURFACE)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setOutputFile(filePath)
            setVideoSize(1280, 720)
            setVideoEncoder(MediaRecorder.VideoEncoder.H264)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setVideoFrameRate(30)
            setVideoEncodingBitRate(8 * 1000 * 1000)
            prepare()
        }

        val virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenRecordService",
            1280, 720, resources.displayMetrics.densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            mediaRecorder.surface, null, null
        )
 val imageReaderSurface: Surface = imageReader!!.surface

        // Create another virtual display if needed to capture frames
        mediaProjection?.createVirtualDisplay(
            "FrameCaptureService",
            1280, 720,
            resources.displayMetrics.densityDpi,
            0,
            imageReaderSurface,
            null, null
        )
        mediaRecorder.start()
       imageReader?.setOnImageAvailableListener({ reader ->
    try {
        val image: Image? = reader.acquireLatestImage()
        if (image != null) {
           val bitmap = imageToBitmap(image) // Convert Image to Bitmap
            val imageBytes = bitmapToByteArray(bitmap) // Convert Bitmap to ByteArray
            
            Handler(Looper.getMainLooper()).post {
                if (flutterEngine != null) {
                    val channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "test")
                    channel.invokeMethod("yourMethod22", imageBytes) // Send ByteArray to Flutter
                } else {
                    println("EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE")
                }
            }

            // Clean up
            image.close()
        }
    } catch (e: Exception) {
        e.printStackTrace()
        println("Error in ImageReader: ${e.message}")
    }
}, null)

    }

    private fun imageToBitmap(image: Image): Bitmap {
    val planes = image.planes
    val buffer: ByteBuffer = planes[0].buffer
    val pixelStride = planes[0].pixelStride
    val rowStride = planes[0].rowStride
    val rowPadding = rowStride - pixelStride * image.width

    val bitmap = Bitmap.createBitmap(
        image.width + rowPadding / pixelStride, image.height, Bitmap.Config.ARGB_8888
    )
    bitmap.copyPixelsFromBuffer(buffer)
    return bitmap
}
private fun bitmapToByteArray(bitmap: Bitmap): ByteArray {
    val stream = ByteArrayOutputStream()
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream) // Convert to PNG
    return stream.toByteArray()
}

    private fun createNotification() {
        val notificationChannelId = "ScreenRecordChannel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(notificationChannelId, "Screen Recording", NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, notificationChannelId)
            .setContentTitle("Screen Recording")
            .setContentText("Recording in progress...")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setOngoing(true)
            .build()

        startForeground(1, notification)
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        mediaRecorder.stop()
        mediaRecorder.release()
        mediaProjection?.stop()
        stopForeground(true)
        imageReader?.close()
    }
}
