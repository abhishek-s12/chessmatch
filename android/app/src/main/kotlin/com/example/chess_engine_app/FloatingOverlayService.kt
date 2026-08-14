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
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

class FloatingOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var evalTextView: TextView? = null
    private var moveTextView: TextView? = null
    private var depthTextView: TextView? = null
    private var isExpanded = false
    private var currentEval = "+0.0"
    private var currentMove = "--"

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.example.chess_engine_app.UPDATE_EVAL") {
                val eval = intent.getStringExtra("eval") ?: "+0.0"
                val bestMove = intent.getStringExtra("bestMove") ?: "--"
                val depth = intent.getIntExtra("depth", 12)
                currentEval = eval
                currentMove = bestMove

                evalTextView?.text = eval
                moveTextView?.text = "Next: $bestMove"
                depthTextView?.text = "D$depth"

                if (eval.startsWith("+") || (!eval.startsWith("-") && eval != "0.0")) {
                    evalTextView?.setTextColor(Color.parseColor("#4ADE80"))
                } else if (eval.startsWith("-")) {
                    evalTextView?.setTextColor(Color.parseColor("#F87171"))
                } else {
                    evalTextView?.setTextColor(Color.WHITE)
                }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(101, createNotification())

        val filter = IntentFilter("com.example.chess_engine_app.UPDATE_EVAL")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(receiver, filter)
        }

        setupFloatingView()
    }

    private fun setupFloatingView() {
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
            setPadding(32, 20, 32, 20)
            
            val bg = GradientDrawable().apply {
                setColor(Color.parseColor("#F00B0F19")) // Dark luxury translucent
                cornerRadius = 40f
                setStroke(3, Color.parseColor("#00F0FF")) // Neon Cyan
            }
            background = bg
            elevation = 24f
        }

        evalTextView = TextView(this).apply {
            text = "+0.0"
            setTextColor(Color.parseColor("#4ADE80"))
            textSize = 16f
            paint.isFakeBoldText = true
            setPadding(0, 0, 16, 0)
        }

        moveTextView = TextView(this).apply {
            text = "Next: e2e4"
            setTextColor(Color.WHITE)
            textSize = 15f
            paint.isFakeBoldText = true
        }

        depthTextView = TextView(this).apply {
            text = "D12"
            setTextColor(Color.parseColor("#94A3B8"))
            textSize = 11f
            setPadding(16, 0, 0, 0)
        }

        container.addView(evalTextView)
        container.addView(moveTextView)
        container.addView(depthTextView)
        floatingView = container

        // Drag and click handling
        container.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var initialTouchX = 0f
            private var initialTouchY = 0f
            private var isClick = false

            override fun onTouch(v: View?, event: MotionEvent?): Boolean {
                when (event?.action) {
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
                        windowManager?.updateViewLayout(floatingView, params)
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
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "chess_overlay_channel",
                "Chess Engine Overlay Service",
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
            .setContentTitle("Chess Engine Overlay Active")
            .setContentText("Evaluating live positions on screen...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(receiver)
        if (floatingView != null) {
            windowManager?.removeView(floatingView)
        }
    }
}
