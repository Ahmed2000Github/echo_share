package com.example.echo_share

import android.app.*
import android.content.Context
import android.graphics.Color
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
import android.os.HandlerThread
import android.os.Looper
import java.nio.ByteBuffer
import java.io.ByteArrayOutputStream


class ScreenRecordService : Service() {

    private var width:Int = 1520
    private var height:Int = 2080
    private var mediaProjection: MediaProjection? = null
    private lateinit var mediaRecorder: MediaRecorder
    private lateinit var mediaProjectionManager: MediaProjectionManager
     private var imageReader: ImageReader? = null
    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null
    val flutterEngine = MainActivity.flutterEngineInstance

    override fun onCreate() {
        super.onCreate()
        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        createNotification()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
         intent?.let {
        if (it.action == "STOP_RECORDING") {
            stopRecording()
            val channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "control_channel")
            channel.invokeMethod("onStopRecording",null) 
        }
    }
        val resultCode = intent?.getIntExtra("resultCode", Activity.RESULT_CANCELED) ?: Activity.RESULT_CANCELED
        val data = intent?.getParcelableExtra<Intent>("data")
         width = intent?.getIntExtra("width", 1520) ?: 1520
        height = intent?.getIntExtra("height", 2080) ?: 2080

        if (resultCode == Activity.RESULT_OK && data != null) {
            mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)
            startRecording()
        }
       

        return START_STICKY
    }
    
    
    private fun startRecording() {
         backgroundThread = HandlerThread("ImageProcessingThread")
        backgroundThread?.start()
        backgroundHandler = Handler(backgroundThread!!.looper)
        val channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "screen_record")
      imageReader = ImageReader.newInstance(height, width,  PixelFormat.RGBA_8888, 2)
      val imageReaderSurface: Surface = imageReader!!.surface

        mediaProjection?.createVirtualDisplay(
            "FrameCaptureService",
            height, width,
            resources.displayMetrics.densityDpi,
            0,
            imageReaderSurface,
            null, null
        )
        imageReader?.setOnImageAvailableListener({ reader ->
            synchronized(lock) {
            backgroundHandler?.post {
                  var image: Image? = null
                try {
             image = reader.acquireLatestImage()
            if (image != null) {
               val bitmap = imageToBitmap(image) 
            val imageBytes = bitmapToByteArray(bitmap)
            Handler(Looper.getMainLooper()).post {
              channel.invokeMethod("onImageReady", imageBytes) 
            }
            image.close()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            println("Error processing Image: ${e.message}")
        }finally {
            image?.close() // Ensure the image is closed
        }
            }
        }
        }, backgroundHandler)
    }

 private fun imageToBitmap(image: Image): Bitmap {
    val planes = image.planes
    val buffer: ByteBuffer = planes[0].buffer
    val pixelStride = planes[0].pixelStride
    val rowStride = planes[0].rowStride
    val width = image.width
    val height = image.height

    // Create a Bitmap with the correct dimensions
    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)

    // Copy pixel data row by row, skipping the padding
    val rowData = ByteArray(rowStride)
    for (row in 0 until height) {
        buffer.position(row * rowStride)
        buffer.get(rowData, 0, rowStride)

        // Copy each row's pixel data into the Bitmap
        for (col in 0 until width) {
            val pixel = rowData[col * pixelStride].toInt() and 0xFF // Red
            val pixel1 = rowData[col * pixelStride + 1].toInt() and 0xFF // Green
            val pixel2 = rowData[col * pixelStride + 2].toInt() and 0xFF // Blue
            val pixel3 = rowData[col * pixelStride + 3].toInt() and 0xFF // Alpha

            // Set the pixel in the Bitmap
            bitmap.setPixel(col, row, Color.argb(pixel3, pixel, pixel1, pixel2))
        }
    }

    return bitmap
}
private fun bitmapToByteArray(bitmap: Bitmap): ByteArray {
    val stream = ByteArrayOutputStream()
    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, stream) // Convert to PNG
    return stream.toByteArray()
}

    private fun createNotification() {
        val notificationChannelId = "ScreenRecordChannel"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(notificationChannelId, "Screen Recording", NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }

        val stopIntent = Intent(this, ScreenRecordService::class.java).apply {
            action = "STOP_RECORDING"
        }
        val intent = Intent(this, MainActivity::class.java).apply {
    flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
}

val pendingIntent = PendingIntent.getActivity(
    this,
    0,
    intent,
    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
)
        
        val stopPendingIntent = PendingIntent.getService(this, 0, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, notificationChannelId)
            .setContentTitle("Screen Recording")
            .setContentText("Recording in progress...")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()

            

        startForeground(1, notification)
    }

    private fun stopRecording() {
    stopSelf()
    stopForeground(true)
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
private val lock = Any()
    override fun onDestroy() {
        super.onDestroy()
         synchronized(lock) {
         try {
        mediaProjection?.stop()
    } catch (e: Exception) {
        println("Error stopping media projection: ${e.message}")
    } finally {
        stopForeground(true)
        imageReader?.close()
        backgroundThread?.quitSafely()
        backgroundThread = null
        backgroundHandler = null
    }
    }
    }
}
