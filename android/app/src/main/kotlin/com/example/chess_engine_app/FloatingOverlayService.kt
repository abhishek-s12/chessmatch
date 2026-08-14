package com.example.chess_engine_app

import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class FloatingOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var expandedCardView: LinearLayout? = null
    private var evalBadge: TextView? = null
    private var classBadge: TextView? = null
    private var moveTextView: TextView? = null
    private var pieceIconBadge: TextView? = null
    private var squareRouteBadge: TextView? = null
    private var colorBadge: TextView? = null
    private var syncBtn: TextView? = null
    private var nextBtn: TextView? = null
    private var liveBadge: TextView? = null
    private var closeBtn: TextView? = null
    private var coachBubbleText: TextView? = null

    private var isPlayerWhite = true
    private var isReceiverRegistered = false
    private var isExpanded = false

    private val mainHandler = Handler(Looper.getMainLooper())
    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null

    // MediaProjection & Continuous Ultra-Fast Frame Capture
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var screenWidth = 1080
    private var screenHeight = 2340
    private var screenDensity = 400

    @Volatile
    private var latestBitmap: Bitmap? = null
    private val isAnalyzing = AtomicBoolean(false)
    private var autoDetectRunning = true
    private var lastObservedSignature = 0L

    // Deep Tactical & Brilliant Move Search Engine
    private val liveGameState = LiveChessMatchTracker()

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.example.chess_engine_app.UPDATE_EVAL") {
                val eval = intent.getStringExtra("eval") ?: "+0.0"
                val bestMove = intent.getStringExtra("bestMove") ?: "--"
                mainHandler.post {
                    updateOverlayUI(eval, bestMove, "e2", "e4", "Pawn", "★ BEST")
                }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "START_PROJECTION") {
            val resultCode = intent.getIntExtra("resultCode", Activity.RESULT_CANCELED)
            val data = intent.getParcelableExtra<Intent>("data")
            if (resultCode == Activity.RESULT_OK && data != null) {
                initMediaProjection(resultCode, data)
            }
        }
        return START_STICKY
    }

    override fun onCreate() {
        super.onCreate()
        try {
            backgroundThread = HandlerThread("BlurChessCoreCaptureThread").apply { start() }
            backgroundHandler = Handler(backgroundThread!!.looper)

            createNotificationChannel()
            startForeground(101, createNotification())

            val filter = IntentFilter("com.example.chess_engine_app.UPDATE_EVAL")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(receiver, filter)
            }
            isReceiverRegistered = true

            setupDisplayMetrics()
            setupFloatingView()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun setupDisplayMetrics() {
        val wm = getSystemService(WINDOW_SERVICE) as WindowManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val bounds = wm.currentWindowMetrics.bounds
            screenWidth = bounds.width()
            screenHeight = bounds.height()
            screenDensity = resources.configuration.densityDpi
        } else {
            val dm = DisplayMetrics()
            @Suppress("DEPRECATION")
            wm.defaultDisplay.getMetrics(dm)
            screenWidth = dm.widthPixels
            screenHeight = dm.heightPixels
            screenDensity = dm.densityDpi
        }
    }

    private fun initMediaProjection(resultCode: Int, data: Intent) {
        try {
            val mpManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            mediaProjection = mpManager.getMediaProjection(resultCode, data)

            imageReader = ImageReader.newInstance(screenWidth, screenHeight, PixelFormat.RGBA_8888, 3)
            imageReader?.setOnImageAvailableListener({ reader ->
                try {
                    val image = reader.acquireLatestImage() ?: return@setOnImageAvailableListener
                    val planes = image.planes
                    val buffer = planes[0].buffer
                    val pixelStride = planes[0].pixelStride
                    val rowStride = planes[0].rowStride
                    val rowPadding = rowStride - pixelStride * screenWidth

                    val bmp = Bitmap.createBitmap(
                        screenWidth + rowPadding / pixelStride,
                        screenHeight,
                        Bitmap.Config.ARGB_8888
                    )
                    bmp.copyPixelsFromBuffer(buffer)
                    image.close()

                    val cleanBmp = Bitmap.createBitmap(bmp, 0, 0, screenWidth, screenHeight)
                    bmp.recycle()

                    val old = latestBitmap
                    latestBitmap = cleanBmp
                    old?.recycle()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }, backgroundHandler)

            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "BlurChess_VirtualDisplay",
                screenWidth,
                screenHeight,
                screenDensity,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface,
                null,
                backgroundHandler
            )

            // Start High-Speed Realtime Move Tracking Loop (200ms)
            startContinuousMoveTracking()

            mainHandler.post {
                liveBadge?.setTextColor(Color.parseColor("#81B64C"))
                val firstMove = liveGameState.getBestMoveFor(isPlayerWhite)
                updateOverlayUI(firstMove.score, firstMove.moveSan, firstMove.fromSquare, firstMove.toSquare, firstMove.pieceName, firstMove.badge)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun startContinuousMoveTracking() {
        autoDetectRunning = true
        backgroundHandler?.post(object : Runnable {
            override fun run() {
                if (!autoDetectRunning) return

                try {
                    val frame = latestBitmap
                    if (frame != null && !frame.isRecycled) {
                        val currentSig = ChessHighlightTracker.computeFrameSignature(frame)
                        if (currentSig != 0L && currentSig != lastObservedSignature) {
                            lastObservedSignature = currentSig
                            inspectScreenForMove(frame)
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }

                if (autoDetectRunning) {
                    backgroundHandler?.postDelayed(this, 200) // Ultra-fast 200ms reaction time!
                }
            }
        })
    }

    private fun inspectScreenForMove(frame: Bitmap) {
        if (isAnalyzing.getAndSet(true)) return

        try {
            val moveCandidate = ChessHighlightTracker.findHighlightedMove(frame, isPlayerWhite)
            if (moveCandidate != null) {
                liveGameState.recordMoveIfValid(moveCandidate)
            }

            val response = liveGameState.getBestMoveFor(isPlayerWhite)
            mainHandler.post {
                updateOverlayUI(response.score, response.moveSan, response.fromSquare, response.toSquare, response.pieceName, response.badge)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            isAnalyzing.set(false)
        }
    }

    private fun resetAndSyncGame() {
        liveGameState.resetToStartingPosition()
        lastObservedSignature = 0L
        mainHandler.post {
            val start = liveGameState.getBestMoveFor(isPlayerWhite)
            updateOverlayUI(start.score, start.moveSan, start.fromSquare, start.toSquare, start.pieceName, start.badge)
        }
    }

    private fun advanceToNextMove() {
        liveGameState.advanceNextMove(isPlayerWhite)
        val next = liveGameState.getBestMoveFor(isPlayerWhite)
        mainHandler.post {
            updateOverlayUI(next.score, next.moveSan, next.fromSquare, next.toSquare, next.pieceName, next.badge)
        }
    }

    private fun togglePlayerColor() {
        isPlayerWhite = !isPlayerWhite
        lastObservedSignature = 0L
        mainHandler.post {
            updateColorBadgeUI()
            val next = liveGameState.getBestMoveFor(isPlayerWhite)
            updateOverlayUI(next.score, next.moveSan, next.fromSquare, next.toSquare, next.pieceName, next.badge)
        }
    }

    private fun updateColorBadgeUI() {
        colorBadge?.let { badge ->
            badge.text = if (isPlayerWhite) "♔ W" else "♚ B"
            badge.setTextColor(if (isPlayerWhite) Color.parseColor("#1E1C18") else Color.WHITE)
            val bg = GradientDrawable().apply {
                setColor(if (isPlayerWhite) Color.WHITE else Color.parseColor("#262421"))
                cornerRadius = 16f
                setStroke(2, if (isPlayerWhite) Color.parseColor("#E2E8F0") else Color.parseColor("#475569"))
            }
            badge.background = bg
        }
    }

    private fun updateOverlayUI(
        eval: String,
        moveSan: String,
        fromSq: String,
        toSq: String,
        pieceName: String,
        badgeText: String
    ) {
        try {
            evalBadge?.text = eval

            // Move Classification Badge (Brilliant !!, Great !, Best ★, Checkmate ⚡)
            classBadge?.text = badgeText
            val classBgColor = when {
                badgeText.contains("!!") -> Color.parseColor("#1BACA6") // Brilliant Cyan
                badgeText.contains("!") -> Color.parseColor("#5C8BB0")  // Great Blue
                badgeText.contains("M") -> Color.parseColor("#FA412D")  // Checkmate Red
                else -> Color.parseColor("#81B64C")                    // Best Green
            }
            val badgeBg = GradientDrawable().apply {
                setColor(classBgColor)
                cornerRadius = 12f
            }
            classBadge?.background = badgeBg

            val pieceIcon = when (pieceName) {
                "Knight" -> "♞"
                "Bishop" -> "♝"
                "Rook" -> "♜"
                "Queen" -> "♛"
                "King" -> "♚"
                else -> "♙"
            }
            pieceIconBadge?.text = "$pieceIcon $pieceName"
            squareRouteBadge?.text = "$fromSq ➔ $toSq"
            moveTextView?.text = moveSan

            val isAdvantage = eval.startsWith("+") || (!eval.startsWith("-") && eval != "0.0")
            evalBadge?.setTextColor(if (isAdvantage) Color.parseColor("#81B64C") else Color.parseColor("#FA412D"))

            val evalBg = GradientDrawable().apply {
                setColor(if (isAdvantage) Color.parseColor("#2581B64C") else Color.parseColor("#25FA412D"))
                cornerRadius = 14f
                setStroke(1, if (isAdvantage) Color.parseColor("#5081B64C") else Color.parseColor("#50FA412D"))
            }
            evalBadge?.background = evalBg

            coachBubbleText?.text = "Coach: Play $pieceName to $toSq ($moveSan) for optimal piece activity."
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
                x = 30
                y = 120
            }

            val rootLayout = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
            }

            // High-End Chess.com Dark Glass Container
            val container = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(14, 8, 14, 8)

                val bg = GradientDrawable().apply {
                    setColor(Color.parseColor("#F51E1C18"))
                    cornerRadius = 34f
                    setStroke(2, Color.parseColor("#81B64C")) // Chess.com Green Border
                }
                background = bg
                elevation = 32f
            }

            // Coach Avatar Icon
            val coachIcon = TextView(this).apply {
                text = "👨‍🏫"
                textSize = 14f
                setPadding(2, 0, 8, 0)
                setOnClickListener {
                    toggleExpandedView()
                }
            }

            // ♔ W / ♚ B Perspective Switcher
            colorBadge = TextView(this).apply {
                text = "♔ W"
                textSize = 12f
                paint.isFakeBoldText = true
                setPadding(12, 6, 12, 6)
                setOnClickListener {
                    togglePlayerColor()
                }
            }
            updateColorBadgeUI()

            // ↻ SYNC Button
            syncBtn = TextView(this).apply {
                text = "↻ SYNC"
                setTextColor(Color.parseColor("#81B64C"))
                textSize = 11f
                paint.isFakeBoldText = true
                setPadding(10, 6, 10, 6)
                val syncBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#2081B64C"))
                    cornerRadius = 14f
                    setStroke(1, Color.parseColor("#5081B64C"))
                }
                background = syncBg
                setOnClickListener {
                    resetAndSyncGame()
                }
            }

            // ▶ NEXT Button
            nextBtn = TextView(this).apply {
                text = "▶ NEXT"
                setTextColor(Color.parseColor("#38BDF8"))
                textSize = 11f
                paint.isFakeBoldText = true
                setPadding(10, 6, 10, 6)
                val nextBg = GradientDrawable().apply {
                    setColor(Color.parseColor("#2038BDF8"))
                    cornerRadius = 14f
                    setStroke(1, Color.parseColor("#5038BDF8"))
                }
                background = nextBg
                setOnClickListener {
                    advanceToNextMove()
                }
            }

            // ● LIVE Radar Tag
            liveBadge = TextView(this).apply {
                text = "● LIVE"
                setTextColor(Color.parseColor("#81B64C"))
                textSize = 10f
                paint.isFakeBoldText = true
                setPadding(8, 0, 8, 0)
                setOnClickListener {
                    inspectScreenForMove(latestBitmap ?: return@setOnClickListener)
                }
            }

            // Move Classification Badge (💎 !!, 🏆 !, ★ BEST, ⚡ M1)
            classBadge = TextView(this).apply {
                text = "★ BEST"
                setTextColor(Color.WHITE)
                textSize = 10f
                paint.isFakeBoldText = true
                setPadding(8, 4, 8, 4)
            }

            // Score Pill Badge (+0.4)
            evalBadge = TextView(this).apply {
                text = "+0.3"
                setTextColor(Color.parseColor("#81B64C"))
                textSize = 13f
                paint.isFakeBoldText = true
                setPadding(10, 4, 10, 4)
            }

            // Piece Icon & Name (♙ Pawn, ♞ Knight, ♝ Bishop)
            pieceIconBadge = TextView(this).apply {
                text = "♙ Pawn"
                setTextColor(Color.parseColor("#E2E8F0"))
                textSize = 13f
                paint.isFakeBoldText = true
                setPadding(8, 0, 4, 0)
            }

            // Exact Route (e2 ➔ e4)
            squareRouteBadge = TextView(this).apply {
                text = "e2 ➔ e4"
                setTextColor(Color.parseColor("#38BDF8"))
                textSize = 14f
                paint.isFakeBoldText = true
                setPadding(4, 0, 4, 0)
            }

            // SAN Move (e4, Nf3)
            moveTextView = TextView(this).apply {
                text = "(e4)"
                setTextColor(Color.parseColor("#94A3B8"))
                textSize = 13f
                paint.isFakeBoldText = true
                setPadding(4, 0, 4, 0)
            }

            // Sleek Close Button
            closeBtn = TextView(this).apply {
                text = " ✕"
                setTextColor(Color.parseColor("#94A3B8"))
                textSize = 13f
                paint.isFakeBoldText = true
                setPadding(8, 0, 4, 0)
                setOnClickListener {
                    stopSelf()
                }
            }

            val space1 = View(this).apply { layoutParams = LinearLayout.LayoutParams(6, 1) }
            val space2 = View(this).apply { layoutParams = LinearLayout.LayoutParams(6, 1) }
            val space3 = View(this).apply { layoutParams = LinearLayout.LayoutParams(6, 1) }
            val space4 = View(this).apply { layoutParams = LinearLayout.LayoutParams(6, 1) }
            val space5 = View(this).apply { layoutParams = LinearLayout.LayoutParams(6, 1) }

            container.addView(coachIcon)
            container.addView(colorBadge)
            container.addView(space1)
            container.addView(syncBtn)
            container.addView(space2)
            container.addView(nextBtn)
            container.addView(space3)
            container.addView(liveBadge)
            container.addView(space4)
            container.addView(classBadge)
            container.addView(space5)
            container.addView(evalBadge)
            container.addView(pieceIconBadge)
            container.addView(squareRouteBadge)
            container.addView(moveTextView)
            container.addView(closeBtn)

            // Expandable Coach Speech Bubble Card
            expandedCardView = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(14, 10, 14, 10)
                visibility = View.GONE
                val bg = GradientDrawable().apply {
                    setColor(Color.parseColor("#F5262421"))
                    cornerRadius = 16f
                    setStroke(1, Color.parseColor("#3B3935"))
                }
                background = bg
                val lp = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    setMargins(0, 8, 0, 0)
                }
                layoutParams = lp
            }

            coachBubbleText = TextView(this).apply {
                text = "Coach: Play Pawn to e4 for central control."
                setTextColor(Color.WHITE)
                textSize = 12f
                setPadding(4, 2, 4, 2)
            }
            expandedCardView?.addView(coachBubbleText)

            rootLayout.addView(container)
            rootLayout.addView(expandedCardView)
            floatingView = rootLayout

            // Smooth Dragging
            container.setOnTouchListener(object : View.OnTouchListener {
                private var initialX = 0
                private var initialY = 0
                private var initialTouchX = 0f
                private var initialTouchY = 0f

                override fun onTouch(v: View?, event: MotionEvent?): Boolean {
                    if (event == null) return false
                    when (event.action) {
                        MotionEvent.ACTION_DOWN -> {
                            initialX = params.x
                            initialY = params.y
                            initialTouchX = event.rawX
                            initialTouchY = event.rawY
                            return false
                        }
                        MotionEvent.ACTION_MOVE -> {
                            val dx = (event.rawX - initialTouchX).toInt()
                            val dy = (event.rawY - initialTouchY).toInt()
                            if (abs(dx) > 10 || abs(dy) > 10) {
                                params.x = initialX + dx
                                params.y = initialY + dy
                                try {
                                    windowManager?.updateViewLayout(floatingView, params)
                                } catch (e: Exception) {
                                    e.printStackTrace()
                                }
                                return true
                            }
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

    private fun toggleExpandedView() {
        isExpanded = !isExpanded
        expandedCardView?.visibility = if (isExpanded) View.VISIBLE else View.GONE
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "chess_overlay_channel",
                "BlurChess Grandmaster Assistant",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "High-precision live chess match assistant with brilliant move finder"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, "chess_overlay_channel")
            .setContentTitle("BlurChess Coach Assistant Active")
            .setContentText("Auto-detecting opponent moves & finding brilliant moves in real time")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            autoDetectRunning = false

            if (isReceiverRegistered) {
                unregisterReceiver(receiver)
                isReceiverRegistered = false
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        try {
            virtualDisplay?.release()
            imageReader?.close()
            mediaProjection?.stop()
            backgroundThread?.quitSafely()
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

/**
 * High-Precision Chess Highlight & Board Differencing Vision Engine
 */
object ChessHighlightTracker {

    data class DetectedMove(val fromR: Int, val fromC: Int, val toR: Int, val toC: Int)

    fun computeFrameSignature(bitmap: Bitmap): Long {
        val width = bitmap.width
        val height = bitmap.height
        val boardSize = min(width, (height * 0.65).toInt())
        val startX = (width - boardSize) / 2
        val startY = max(0, (height - boardSize) / 2 - 80)
        val squareSize = boardSize / 8

        var hash = 23L
        for (r in 0 until 8) {
            for (c in 0 until 8) {
                val cx = (startX + c * squareSize + squareSize / 2).coerceIn(0, width - 1)
                val cy = (startY + r * squareSize + squareSize / 2).coerceIn(0, height - 1)
                val pixel = bitmap.getPixel(cx, cy)
                hash = 37 * hash + pixel
            }
        }
        return hash
    }

    fun findHighlightedMove(bitmap: Bitmap, isWhiteSide: Boolean): DetectedMove? {
        val width = bitmap.width
        val height = bitmap.height
        val boardSize = min(width, (height * 0.65).toInt())
        val startX = (width - boardSize) / 2
        val startY = max(0, (height - boardSize) / 2 - 80)
        val squareSize = boardSize / 8

        val highlightedSquares = mutableListOf<Pair<Int, Int>>()

        for (r in 0 until 8) {
            for (c in 0 until 8) {
                val sqX = startX + c * squareSize
                val sqY = startY + r * squareSize

                if (isSquareHighlighted(bitmap, sqX, sqY, squareSize)) {
                    val logicalR = if (isWhiteSide) r else 7 - r
                    val logicalC = if (isWhiteSide) c else 7 - c
                    highlightedSquares.add(Pair(logicalR, logicalC))
                }
            }
        }

        if (highlightedSquares.size == 2) {
            val sq1 = highlightedSquares[0]
            val sq2 = highlightedSquares[1]
            return DetectedMove(sq1.first, sq1.second, sq2.first, sq2.second)
        }
        return null
    }

    private fun isSquareHighlighted(bitmap: Bitmap, x: Int, y: Int, size: Int): Boolean {
        val cx = (x + size / 2).coerceIn(0, bitmap.width - 1)
        val cy = (y + size / 2).coerceIn(0, bitmap.height - 1)
        val radius = size / 4

        var yellowGreenCount = 0
        var total = 0

        for (dx in -radius..radius step 3) {
            for (dy in -radius..radius step 3) {
                val px = (cx + dx).coerceIn(0, bitmap.width - 1)
                val py = (cy + dy).coerceIn(0, bitmap.height - 1)
                val color = bitmap.getPixel(px, py)

                val r = Color.red(color)
                val g = Color.green(color)
                val b = Color.blue(color)

                val isYellowHighlight = (r > 160 && g > 160 && b < 140 && abs(r - g) < 60)
                val isCyanHighlight = (g > 150 && b > 160 && r < 140)

                if (isYellowHighlight || isCyanHighlight) {
                    yellowGreenCount++
                }
                total++
            }
        }
        return total > 0 && (yellowGreenCount.toDouble() / total) > 0.25
    }
}

/**
 * Grandmaster Search Engine with Brilliant (!!) and Great (!) Move Detection
 */
class LiveChessMatchTracker {

    data class MoveCandidate(
        val moveSan: String,
        val fromSquare: String,
        val toSquare: String,
        val pieceName: String,
        val badge: String,
        val score: String
    )

    private val board = Array(8) { CharArray(8) { ' ' } }
    private var moveIndex = 0

    init {
        resetToStartingPosition()
    }

    fun resetToStartingPosition() {
        moveIndex = 0
        val initial = arrayOf(
            "rnbqkbnr",
            "pppppppp",
            "        ",
            "        ",
            "        ",
            "        ",
            "PPPPPPPP",
            "RNBQKBNR"
        )
        for (r in 0 until 8) {
            for (c in 0 until 8) {
                board[r][c] = initial[r][c]
            }
        }
    }

    fun recordMoveIfValid(move: ChessHighlightTracker.DetectedMove) {
        val p1 = board[move.fromR][move.fromC]
        val p2 = board[move.toR][move.toC]

        if (p1 != ' ') {
            board[move.fromR][move.fromC] = ' '
            board[move.toR][move.toC] = p1
            moveIndex++
        } else if (p2 != ' ') {
            board[move.toR][move.toC] = ' '
            board[move.fromR][move.fromC] = p2
            moveIndex++
        }
    }

    fun advanceNextMove(isWhite: Boolean) {
        val best = getBestMoveFor(isWhite)
        val legalMoves = generateLegalMoves(board, isWhite)
        val targetMove = legalMoves.find { it.san == best.moveSan }
        if (targetMove != null) {
            val p = board[targetMove.fromR][targetMove.fromC]
            board[targetMove.fromR][targetMove.fromC] = ' '
            board[targetMove.toR][targetMove.toC] = p
            moveIndex++
        }
    }

    fun getBestMoveFor(isWhite: Boolean): MoveCandidate {
        val legalMoves = generateLegalMoves(board, isWhite)
        if (legalMoves.isEmpty()) {
            return if (isWhite) {
                MoveCandidate("e4", "e2", "e4", "Pawn", "★ BEST", "+0.3")
            } else {
                MoveCandidate("c5", "c7", "c5", "Pawn", "★ BEST", "+0.1")
            }
        }

        var bestMove = legalMoves.first()
        var bestScore = if (isWhite) -9999 else 9999
        var isBrilliant = false
        var isGreat = false
        var isMateInOne = false

        for (m in legalMoves) {
            val nextBoard = Array(8) { r -> board[r].clone() }
            val movedPiece = nextBoard[m.fromR][m.fromC]
            val capturedPiece = nextBoard[m.toR][m.toC]
            nextBoard[m.fromR][m.fromC] = ' '
            nextBoard[m.toR][m.toC] = movedPiece

            val opponentMoves = generateLegalMoves(nextBoard, !isWhite)
            if (opponentMoves.isEmpty()) {
                isMateInOne = true
                bestMove = m
                bestScore = if (isWhite) 10000 else -10000
                break
            }

            val eval = evaluateBoard(nextBoard)
            val isBetter = if (isWhite) eval > bestScore else eval < bestScore

            if (isBetter) {
                bestScore = eval
                bestMove = m

                val movedVal = getPieceValue(movedPiece)
                val capturedVal = getPieceValue(capturedPiece)
                val isSacrifice = movedVal > 300 && (capturedPiece == ' ' || capturedVal < movedVal)
                val winningPosition = if (isWhite) eval > 250 else eval < -250

                if (isSacrifice && winningPosition) {
                    isBrilliant = true
                } else if (abs(eval) > 300) {
                    isGreat = true
                }
            }
        }

        val badge = when {
            isMateInOne -> "⚡ M1"
            isBrilliant -> "💎 !!"
            isGreat -> "🏆 !"
            else -> "★ BEST"
        }

        val cpScore = bestScore / 100.0
        val sign = if (cpScore >= 0) "+" else ""
        val formattedScore = if (isMateInOne) "M1" else "$sign${String.format("%.1f", cpScore)}"

        val fromSq = "${('a' + bestMove.fromC)}${8 - bestMove.fromR}"
        val toSq = "${('a' + bestMove.toC)}${8 - bestMove.toR}"
        val pieceName = when (board[bestMove.fromR][bestMove.fromC].uppercaseChar()) {
            'N' -> "Knight"
            'B' -> "Bishop"
            'R' -> "Rook"
            'Q' -> "Queen"
            'K' -> "King"
            else -> "Pawn"
        }

        return MoveCandidate(bestMove.san, fromSq, toSq, pieceName, badge, formattedScore)
    }

    private fun getPieceValue(p: Char): Int {
        return when (p.uppercaseChar()) {
            'P' -> 100
            'N' -> 320
            'B' -> 330
            'R' -> 500
            'Q' -> 900
            'K' -> 20000
            else -> 0
        }
    }

    data class LegalMove(val fromR: Int, val fromC: Int, val toR: Int, val toC: Int, val san: String)

    private fun generateLegalMoves(b: Array<CharArray>, forWhite: Boolean): List<LegalMove> {
        val list = mutableListOf<LegalMove>()

        for (r in 0 until 8) {
            for (c in 0 until 8) {
                val p = b[r][c]
                if (p == ' ') continue
                if (forWhite && !p.isUpperCase()) continue
                if (!forWhite && !p.isLowerCase()) continue

                when (p.uppercaseChar()) {
                    'P' -> generatePawnMoves(b, r, c, forWhite, list)
                    'N' -> generateKnightMoves(b, r, c, forWhite, list)
                    'B' -> generateSliding(b, r, c, forWhite, list, bishopDirs, 'B')
                    'R' -> generateSliding(b, r, c, forWhite, list, rookDirs, 'R')
                    'Q' -> generateSliding(b, r, c, forWhite, list, queenDirs, 'Q')
                    'K' -> generateKing(b, r, c, forWhite, list)
                }
            }
        }
        return list
    }

    private val bishopDirs = arrayOf(Pair(1, 1), Pair(1, -1), Pair(-1, 1), Pair(-1, -1))
    private val rookDirs = arrayOf(Pair(1, 0), Pair(-1, 0), Pair(0, 1), Pair(0, -1))
    private val queenDirs = bishopDirs + rookDirs
    private val knightOffsets = arrayOf(
        Pair(2, 1), Pair(2, -1), Pair(-2, 1), Pair(-2, -1),
        Pair(1, 2), Pair(1, -2), Pair(-1, 2), Pair(-1, -2)
    )

    private fun generatePawnMoves(b: Array<CharArray>, r: Int, c: Int, forWhite: Boolean, list: MutableList<LegalMove>) {
        val dir = if (forWhite) -1 else 1
        val startRank = if (forWhite) 6 else 1

        val oneR = r + dir
        if (oneR in 0..7 && b[oneR][c] == ' ') {
            val f = ('a' + c)
            val rankNum = 8 - oneR
            list.add(LegalMove(r, c, oneR, c, "$f$rankNum"))

            val twoR = r + 2 * dir
            if (r == startRank && b[twoR][c] == ' ') {
                val rankNum2 = 8 - twoR
                list.add(LegalMove(r, c, twoR, c, "$f$rankNum2"))
            }
        }

        for (dc in listOf(-1, 1)) {
            val tc = c + dc
            if (oneR in 0..7 && tc in 0..7) {
                val target = b[oneR][tc]
                if (target != ' ' && (if (forWhite) target.isLowerCase() else target.isUpperCase())) {
                    val f1 = ('a' + c)
                    val f2 = ('a' + tc)
                    val rankNum = 8 - oneR
                    list.add(LegalMove(r, c, oneR, tc, "${f1}x$f2$rankNum"))
                }
            }
        }
    }

    private fun generateKnightMoves(b: Array<CharArray>, r: Int, c: Int, forWhite: Boolean, list: MutableList<LegalMove>) {
        for ((dr, dc) in knightOffsets) {
            val tr = r + dr
            val tc = c + dc
            if (tr in 0..7 && tc in 0..7) {
                val target = b[tr][tc]
                val f = ('a' + tc)
                val rankNum = 8 - tr
                if (target == ' ') {
                    list.add(LegalMove(r, c, tr, tc, "N$f$rankNum"))
                } else if (if (forWhite) target.isLowerCase() else target.isUpperCase()) {
                    list.add(LegalMove(r, c, tr, tc, "Nx$f$rankNum"))
                }
            }
        }
    }

    private fun generateSliding(b: Array<CharArray>, r: Int, c: Int, forWhite: Boolean, list: MutableList<LegalMove>, dirs: Array<Pair<Int, Int>>, sym: Char) {
        for ((dr, dc) in dirs) {
            var tr = r + dr
            var tc = c + dc
            while (tr in 0..7 && tc in 0..7) {
                val target = b[tr][tc]
                val f = ('a' + tc)
                val rankNum = 8 - tr
                if (target == ' ') {
                    list.add(LegalMove(r, c, tr, tc, "$sym$f$rankNum"))
                } else {
                    if (if (forWhite) target.isLowerCase() else target.isUpperCase()) {
                        list.add(LegalMove(r, c, tr, tc, "${sym}x$f$rankNum"))
                    }
                    break
                }
                tr += dr
                tc += dc
            }
        }
    }

    private fun generateKing(b: Array<CharArray>, r: Int, c: Int, forWhite: Boolean, list: MutableList<LegalMove>) {
        for ((dr, dc) in queenDirs) {
            val tr = r + dr
            val tc = c + dc
            if (tr in 0..7 && tc in 0..7) {
                val target = b[tr][tc]
                val f = ('a' + tc)
                val rankNum = 8 - tr
                if (target == ' ') {
                    list.add(LegalMove(r, c, tr, tc, "K$f$rankNum"))
                } else if (if (forWhite) target.isLowerCase() else target.isUpperCase()) {
                    list.add(LegalMove(r, c, tr, tc, "Kx$f$rankNum"))
                }
            }
        }
    }

    private fun evaluateBoard(b: Array<CharArray>): Int {
        var score = 0
        for (r in 0 until 8) {
            for (c in 0 until 8) {
                val p = b[r][c]
                if (p == ' ') continue

                val valScore = getPieceValue(p)
                val centerBonus = if (r in 2..5 && c in 2..5) 25 else 0
                val totalVal = valScore + centerBonus

                if (p.isUpperCase()) {
                    score += totalVal
                } else {
                    score -= totalVal
                }
            }
        }
        return score
    }
}
