package com.example.chess_engine_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

class FloatingOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var evalTextView: TextView? = null
    private var moveTextView: TextView? = null
    private var depthTextView: TextView? = null
    private var closeBtn: TextView? = null
    private var isExpanded = false
    private var isReceiverRegistered = false
    private val mainHandler = Handler(Looper.getMainLooper())

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.example.chess_engine_app.UPDATE_EVAL") {
                val eval = intent.getStringExtra("eval") ?: "+0.0"
                val bestMove = intent.getStringExtra("bestMove") ?: "--"
                val depth = intent.getIntExtra("depth", 12)

                mainHandler.post {
                    try {
                        evalTextView?.text = eval
                        moveTextView?.text = "Next: $bestMove"
                        depthTextView?.text = "D$depth"

                        if (eval.startsWith("+") || (!eval.startsWith("-") && eval != "0.0")) {
                            evalTextView?.setTextColor(Color.parseColor("#22C55E")) // Green
                        } else if (eval.startsWith("-")) {
                            evalTextView?.setTextColor(Color.parseColor("#EF4444")) // Red
                        } else {
                            evalTextView?.setTextColor(Color.WHITE)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        try {
            createNotificationChannel()
            startForeground(101, createNotification())

            val filter = IntentFilter("com.example.chess_engine_app.UPDATE_EVAL")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(receiver, filter)
            }
            isReceiverRegistered = true

            setupFloatingView()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun setupFloatingView() {
        try {
            windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

            val layoutParamsType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                layoutParamsType,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = 100
                y = 200
            }

            val container = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(28, 16, 28, 16)

                val bg = GradientDrawable().apply {
                    setColor(Color.parseColor("#EE0B0F19")) // Dark luxury translucent
                    cornerRadius = 32f
                    setStroke(2, Color.parseColor("#38BDF8")) // Sky Blue
                }
                background = bg
                elevation = 20f
            }

            evalTextView = TextView(this).apply {
                text = "+0.0"
                setTextColor(Color.parseColor("#22C55E"))
                textSize = 15f
                paint.isFakeBoldText = true
                setPadding(0, 0, 14, 0)
            }

            moveTextView = TextView(this).apply {
                text = "Next: e2e4"
                setTextColor(Color.WHITE)
                textSize = 14f
                paint.isFakeBoldText = true
            }

            depthTextView = TextView(this).apply {
                text = "D12"
                setTextColor(Color.parseColor("#94A3B8"))
                textSize = 11f
                visibility = View.GONE
                setPadding(12, 0, 0, 0)
            }

            closeBtn = TextView(this).apply {
                text = " ✕"
                setTextColor(Color.parseColor("#64748B"))
                textSize = 13f
                paint.isFakeBoldText = true
                setPadding(12, 0, 0, 0)
                setOnClickListener {
                    stopSelf()
                }
            }

            container.addView(evalTextView)
            container.addView(moveTextView)
            container.addView(depthTextView)
            container.addView(closeBtn)
            floatingView = container

            // Touch dragging & click expansion
            container.setOnTouchListener(object : View.OnTouchListener {
                private var initialX = 0
                private var initialY = 0
                private var initialTouchX = 0f
                private var initialTouchY = 0f
                private var isClick = false

                override fun onTouch(v: View?, event: MotionEvent?): Boolean {
                    if (event == null) return false
                    when (event.action) {
                        MotionEvent.ACTION_DOWN -> {
                            initialX = params.x
                            initialY = params.y
                            initialTouchX = event.rawX
                            initialTouchY = event.rawY
                            isClick = true
                            return true
                        }
                        MotionEvent.ACTION_MOVE -> {
                            val dx = (event.rawX - initialTouchX).toInt()
                            val dy = (event.rawY - initialTouchY).toInt()
                            if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
                                isClick = false
                            }
                            params.x = initialX + dx
                            params.y = initialY + dy
                            try {
                                windowManager?.updateViewLayout(floatingView, params)
                            } catch (e: Exception) {
                                e.printStackTrace()
                            }
                            return true
                        }
                        MotionEvent.ACTION_UP -> {
                            if (isClick) {
                                isExpanded = !isExpanded
                                depthTextView?.visibility = if (isExpanded) View.VISIBLE else View.GONE
                            }
                            return true
                        }
                    }
                    return false
                }
            })

            windowManager?.addView(floatingView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "chess_overlay_channel",
                "BlurChess Floating Assistant",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows live evaluation and best move suggestions in floating overlay"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, "chess_overlay_channel")
            .setContentTitle("BlurChess Floating Assistant")
            .setContentText("Stockfish engine calculating live evaluations")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            if (isReceiverRegistered) {
                unregisterReceiver(receiver)
                isReceiverRegistered = false
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        try {
            if (floatingView != null && windowManager != null) {
                windowManager?.removeView(floatingView)
                floatingView = null
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
