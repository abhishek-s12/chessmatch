package com.example.chess_engine_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.chess_engine_app/overlay"
    private val REQUEST_OVERLAY_PERMISSION = 1001
    private val REQUEST_MEDIA_PROJECTION = 2002

    private var pendingMethodResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "requestPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        if (!Settings.canDrawOverlays(this)) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivityForResult(intent, REQUEST_OVERLAY_PERMISSION)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "startOverlay" -> {
                    val intent = Intent(this, FloatingOverlayService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "stopOverlay" -> {
                    val intent = Intent(this, FloatingOverlayService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                "startScreenCapture" -> {
                    val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    pendingMethodResult = result
                    startActivityForResult(projectionManager.createScreenCaptureIntent(), REQUEST_MEDIA_PROJECTION)
                }
                "updateOverlay" -> {
                    val eval = call.argument<String>("eval") ?: "0.0"
                    val bestMove = call.argument<String>("bestMove") ?: "--"
                    val isWhite = call.argument<Boolean>("isWhite") ?: true
                    val depth = call.argument<Int>("depth") ?: 12

                    val intent = Intent("com.example.chess_engine_app.UPDATE_EVAL").apply {
                        putExtra("eval", eval)
                        putExtra("bestMove", bestMove)
                        putExtra("isWhite", isWhite)
                        putExtra("depth", depth)
                        setPackage(packageName)
                    }
                    sendBroadcast(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_MEDIA_PROJECTION) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                // Pass projection data to FloatingOverlayService
                val serviceIntent = Intent(this, FloatingOverlayService::class.java).apply {
                    action = "START_PROJECTION"
                    putExtra("resultCode", resultCode)
                    putExtra("data", data)
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }
                pendingMethodResult?.success(true)
            } else {
                pendingMethodResult?.success(false)
            }
            pendingMethodResult = null
        }
    }
}
