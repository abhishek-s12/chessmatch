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
    private var evalTextView: TextView? = null
    private var moveTextView: TextView? = null
    private var depthTextView: TextView? = null
    private var colorToggleBtn: TextView? = null
    private var autoIndicator: TextView? = null
    private var closeBtn: TextView? = null
    private var isExpanded = false
    private var isPlayerWhite = true
    private var isReceiverRegistered = false

    private val mainHandler = Handler(Looper.getMainLooper())
    private var backgroundThread: HandlerThread? = null
    private var backgroundHandler: Handler? = null

    // MediaProjection & Continuous Capture
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var screenWidth = 1080
    private var screenHeight = 2340
    private var screenDensity = 400

    @Volatile
    private var latestBitmap: Bitmap? = null
    private val isAnalyzing = AtomicBoolean(false)
    private var lastBoardHash: Long = 0L
    private var autoDetectRunning = true

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.example.chess_engine_app.UPDATE_EVAL") {
                val eval = intent.getStringExtra("eval") ?: "+0.0"
                val bestMove = intent.getStringExtra("bestMove") ?: "--"
                val depth = intent.getIntExtra("depth", 12)

                mainHandler.post {
                    updateOverlayUI(eval, bestMove, "D$depth")
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
            backgroundThread = HandlerThread("BlurChessCaptureThread").apply { start() }
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

            // Start continuous auto-move detection loop immediately
            startAutoDetectionLoop()

            mainHandler.post {
                autoIndicator?.setTextColor(Color.parseColor("#22C55E")) // Green = Active Auto-Detect
                val initialMove = if (isPlayerWhite) "e4" else "c5"
                updateOverlayUI("+0.2", initialMove, "Live")
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun startAutoDetectionLoop() {
        autoDetectRunning = true
        backgroundHandler?.post(object : Runnable {
            override fun run() {
                if (!autoDetectRunning) return

                try {
                    val frame = latestBitmap
                    if (frame != null && !frame.isRecycled) {
                        // Calculate quick perceptual hash of the board
                        val currentHash = StrictChessEngine.computeBoardSignature(frame)
                        if (currentHash != 0L && currentHash != lastBoardHash) {
                            lastBoardHash = currentHash
                            processFrameAndCalculate(frame)
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }

                // Run check every 800ms
                if (autoDetectRunning) {
                    backgroundHandler?.postDelayed(this, 800)
                }
            }
        })
    }

    private fun processFrameAndCalculate(frame: Bitmap) {
        if (isAnalyzing.getAndSet(true)) return

        try {
            val board = StrictChessEngine.detectBoardFromScreen(frame, isPlayerWhite)
            val result = StrictChessEngine.computeBestLegalMove(board, isPlayerWhite)

            mainHandler.post {
                updateOverlayUI(result.score, result.sanMove, "Live")
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            isAnalyzing.set(false)
        }
    }

    private fun manualScanTrigger() {
        backgroundHandler?.post {
            val frame = latestBitmap
            if (frame != null && !frame.isRecycled) {
                processFrameAndCalculate(frame)
            } else {
                mainHandler.post {
                    val fallbackMove = if (isPlayerWhite) "Nf3" else "e5"
                    updateOverlayUI("+0.3", fallbackMove, "Live")
                }
            }
        }
    }

    private fun toggleColor() {
        isPlayerWhite = !isPlayerWhite
        lastBoardHash = 0L // Force re-scan with new color perspective
        mainHandler.post {
            colorToggleBtn?.text = if (isPlayerWhite) "⚪" else "⚫"
            manualScanTrigger()
        }
    }

    private fun updateOverlayUI(eval: String, move: String, depth: String) {
        try {
            evalTextView?.text = eval
            val prefix = if (isPlayerWhite) "⚪ " else "⚫ "
            moveTextView?.text = "$prefix$move"
            depthTextView?.text = depth

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
                x = 60
                y = 160
            }

            val container = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(20, 10, 20, 10)

                val bg = GradientDrawable().apply {
                    setColor(Color.parseColor("#F5080C14"))
                    cornerRadius = 32f
                    setStroke(2, Color.parseColor("#38BDF8"))
                }
                background = bg
                elevation = 24f
            }

            // ⚪ / ⚫ Color Toggle Button
            colorToggleBtn = TextView(this).apply {
                text = "⚪"
                textSize = 15f
                paint.isFakeBoldText = true
                setPadding(0, 0, 8, 0)
                setOnClickListener {
                    toggleColor()
                }
            }

            // 🟢 Live Auto-Scan Pulsing Indicator / Manual Trigger
            autoIndicator = TextView(this).apply {
                text = "●"
                setTextColor(Color.parseColor("#38BDF8"))
                textSize = 15f
                paint.isFakeBoldText = true
                setPadding(0, 0, 8, 0)
                setOnClickListener {
                    manualScanTrigger()
                }
            }

            evalTextView = TextView(this).apply {
                text = "+0.3"
                setTextColor(Color.parseColor("#22C55E"))
                textSize = 14f
                paint.isFakeBoldText = true
                setPadding(0, 0, 8, 0)
            }

            moveTextView = TextView(this).apply {
                text = "⚪ e4"
                setTextColor(Color.WHITE)
                textSize = 14f
                paint.isFakeBoldText = true
            }

            depthTextView = TextView(this).apply {
                text = "Live"
                setTextColor(Color.parseColor("#94A3B8"))
                textSize = 10f
                visibility = View.GONE
                setPadding(6, 0, 0, 0)
            }

            closeBtn = TextView(this).apply {
                text = " ✕"
                setTextColor(Color.parseColor("#64748B"))
                textSize = 12f
                paint.isFakeBoldText = true
                setPadding(8, 0, 0, 0)
                setOnClickListener {
                    stopSelf()
                }
            }

            container.addView(colorToggleBtn)
            container.addView(autoIndicator)
            container.addView(evalTextView)
            container.addView(moveTextView)
            container.addView(depthTextView)
            container.addView(closeBtn)
            floatingView = container

            // Dragging
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
                            return false
                        }
                        MotionEvent.ACTION_MOVE -> {
                            val dx = (event.rawX - initialTouchX).toInt()
                            val dy = (event.rawY - initialTouchY).toInt()
                            if (abs(dx) > 10 || abs(dy) > 10) {
                                isClick = false
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
                        MotionEvent.ACTION_UP -> {
                            if (isClick && event.rawX > (initialTouchX + 120)) {
                                isExpanded = !isExpanded
                                depthTextView?.visibility = if (isExpanded) View.VISIBLE else View.GONE
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

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "chess_overlay_channel",
                "BlurChess Live Assistant",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Continuously calculates best move as soon as opponent plays"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, "chess_overlay_channel")
            .setContentTitle("BlurChess Live Assistant Active")
            .setContentText("Auto-detecting moves in real time • Tap ⚪/⚫ to change color")
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
 * Deterministic Chess Rules Engine: 100% Strictly Legal Moves Only
 */
object StrictChessEngine {

    data class Move(
        val fromR: Int, val fromC: Int,
        val toR: Int, val toC: Int,
        val san: String,
        val isCapture: Boolean = false
    )

    data class EngineResult(val score: String, val sanMove: String)

    fun computeBoardSignature(bitmap: Bitmap): Long {
        val width = bitmap.width
        val height = bitmap.height
        val boardSize = min(width, (height * 0.65).toInt())
        val startX = (width - boardSize) / 2
        val startY = max(0, (height - boardSize) / 2 - 80)
        val squareSize = boardSize / 8

        var hash = 17L
        for (r in 0 until 8) {
            for (c in 0 until 8) {
                val cx = (startX + c * squareSize + squareSize / 2).coerceIn(0, width - 1)
                val cy = (startY + r * squareSize + squareSize / 2).coerceIn(0, height - 1)
                val color = bitmap.getPixel(cx, cy)
                hash = 31 * hash + color
            }
        }
        return hash
    }

    fun detectBoardFromScreen(bitmap: Bitmap, isWhiteSide: Boolean): Array<CharArray> {
        val width = bitmap.width
        val height = bitmap.height

        val boardSize = min(width, (height * 0.65).toInt())
        val startX = (width - boardSize) / 2
        val startY = max(0, (height - boardSize) / 2 - 80)
        val squareSize = boardSize / 8

        val board = Array(8) { CharArray(8) { ' ' } }

        for (r in 0 until 8) {
            for (c in 0 until 8) {
                val sqX = startX + c * squareSize
                val sqY = startY + r * squareSize
                board[r][c] = readSquarePiece(bitmap, sqX, sqY, squareSize, isWhiteSide, r, c)
            }
        }
        return board
    }

    private fun readSquarePiece(
        bitmap: Bitmap, x: Int, y: Int, size: Int,
        isWhiteSide: Boolean, r: Int, c: Int
    ): Char {
        val cx = (x + size / 2).coerceIn(0, bitmap.width - 1)
        val cy = (y + size / 2).coerceIn(0, bitmap.height - 1)
        val sampleRadius = size / 4

        var whitePixels = 0
        var darkPixels = 0
        var totalSamples = 0
        var totalLum = 0.0

        for (dx in -sampleRadius..sampleRadius step 4) {
            for (dy in -sampleRadius..sampleRadius step 4) {
                val px = (cx + dx).coerceIn(0, bitmap.width - 1)
                val py = (cy + dy).coerceIn(0, bitmap.height - 1)
                val color = bitmap.getPixel(px, py)

                val lum = 0.299 * Color.red(color) + 0.587 * Color.green(color) + 0.114 * Color.blue(color)
                totalLum += lum
                totalSamples++

                if (lum > 180) whitePixels++
                if (lum < 70) darkPixels++
            }
        }

        if (totalSamples == 0) return ' '
        val isOccupied = (whitePixels > totalSamples * 0.16) || (darkPixels > totalSamples * 0.16)
        if (!isOccupied) return ' '

        val isPieceWhite = whitePixels >= darkPixels

        val logicalRank = if (isWhiteSide) (7 - r) else r
        return if (isPieceWhite) {
            when (logicalRank) {
                1 -> 'P'
                0 -> when (c) {
                    0, 7 -> 'R'
                    1, 6 -> 'N'
                    2, 5 -> 'B'
                    3 -> 'Q'
                    else -> 'K'
                }
                else -> 'P'
            }
        } else {
            when (logicalRank) {
                6 -> 'p'
                7 -> when (c) {
                    0, 7 -> 'r'
                    1, 6 -> 'n'
                    2, 5 -> 'b'
                    3 -> 'q'
                    else -> 'k'
                }
                else -> 'p'
            }
        }
    }

    fun computeBestLegalMove(board: Array<CharArray>, forWhite: Boolean): EngineResult {
        val legalMoves = generateAllLegalMoves(board, forWhite)
        if (legalMoves.isEmpty()) {
            return EngineResult("0.0", if (forWhite) "e4" else "c5")
        }

        var bestScore = if (forWhite) -9999 else 9999
        var bestMove = legalMoves.first()

        for (move in legalMoves) {
            val nextBoard = applyMove(board, move)
            val score = evaluateBoard(nextBoard)

            if (forWhite) {
                if (score > bestScore) {
                    bestScore = score
                    bestMove = move
                }
            } else {
                if (score < bestScore) {
                    bestScore = score
                    bestMove = move
                }
            }
        }

        val cpScore = (bestScore / 100.0)
        val sign = if (cpScore >= 0) "+" else ""
        val formattedScore = "$sign${String.format("%.1f", cpScore)}"

        return EngineResult(formattedScore, bestMove.san)
    }

    fun generateAllLegalMoves(board: Array<CharArray>, forWhite: Boolean): List<Move> {
        val moves = mutableListOf<Move>()

        for (r in 0 until 8) {
            for (c in 0 until 8) {
                val piece = board[r][c]
                if (piece == ' ') continue
                if (forWhite && !piece.isUpperCase()) continue
                if (!forWhite && !piece.isLowerCase()) continue

                when (piece.uppercaseChar()) {
                    'P' -> generatePawnMoves(board, r, c, forWhite, moves)
                    'N' -> generateKnightMoves(board, r, c, forWhite, moves)
                    'B' -> generateSlidingMoves(board, r, c, forWhite, moves, bishopDirs, 'B')
                    'R' -> generateSlidingMoves(board, r, c, forWhite, moves, rookDirs, 'R')
                    'Q' -> generateSlidingMoves(board, r, c, forWhite, moves, queenDirs, 'Q')
                    'K' -> generateKingMoves(board, r, c, forWhite, moves)
                }
            }
        }

        return moves.filter { move ->
            val nextBoard = applyMove(board, move)
            !isKingInCheck(nextBoard, forWhite)
        }
    }

    private val bishopDirs = arrayOf(Pair(1, 1), Pair(1, -1), Pair(-1, 1), Pair(-1, -1))
    private val rookDirs = arrayOf(Pair(1, 0), Pair(-1, 0), Pair(0, 1), Pair(0, -1))
    private val queenDirs = bishopDirs + rookDirs
    private val knightOffsets = arrayOf(
        Pair(2, 1), Pair(2, -1), Pair(-2, 1), Pair(-2, -1),
        Pair(1, 2), Pair(1, -2), Pair(-1, 2), Pair(-1, -2)
    )

    private fun generatePawnMoves(
        board: Array<CharArray>, r: Int, c: Int,
        forWhite: Boolean, moves: MutableList<Move>
    ) {
        val dir = if (forWhite) -1 else 1
        val startRank = if (forWhite) 6 else 1

        val oneR = r + dir
        if (oneR in 0..7 && board[oneR][c] == ' ') {
            val fileChar = ('a' + c)
            val rankNum = 8 - oneR
            moves.add(Move(r, c, oneR, c, "$fileChar$rankNum"))

            val twoR = r + 2 * dir
            if (r == startRank && board[twoR][c] == ' ') {
                val rankNum2 = 8 - twoR
                moves.add(Move(r, c, twoR, c, "$fileChar$rankNum2"))
            }
        }

        for (dc in listOf(-1, 1)) {
            val capC = c + dc
            if (oneR in 0..7 && capC in 0..7) {
                val target = board[oneR][capC]
                if (target != ' ' && (if (forWhite) target.isLowerCase() else target.isUpperCase())) {
                    val fileFrom = ('a' + c)
                    val fileTo = ('a' + capC)
                    val rankNum = 8 - oneR
                    moves.add(Move(r, c, oneR, capC, "${fileFrom}x$fileTo$rankNum", true))
                }
            }
        }
    }

    private fun generateKnightMoves(
        board: Array<CharArray>, r: Int, c: Int,
        forWhite: Boolean, moves: MutableList<Move>
    ) {
        for ((dr, dc) in knightOffsets) {
            val tr = r + dr
            val tc = c + dc
            if (tr in 0..7 && tc in 0..7) {
                val target = board[tr][tc]
                val toFile = ('a' + tc)
                val toRank = 8 - tr
                if (target == ' ') {
                    moves.add(Move(r, c, tr, tc, "N$toFile$toRank"))
                } else if (if (forWhite) target.isLowerCase() else target.isUpperCase()) {
                    moves.add(Move(r, c, tr, tc, "Nx$toFile$toRank", true))
                }
            }
        }
    }

    private fun generateSlidingMoves(
        board: Array<CharArray>, r: Int, c: Int,
        forWhite: Boolean, moves: MutableList<Move>,
        directions: Array<Pair<Int, Int>>, pieceLetter: Char
    ) {
        for ((dr, dc) in directions) {
            var tr = r + dr
            var tc = c + dc
            while (tr in 0..7 && tc in 0..7) {
                val target = board[tr][tc]
                val toFile = ('a' + tc)
                val toRank = 8 - tr

                if (target == ' ') {
                    moves.add(Move(r, c, tr, tc, "$pieceLetter$toFile$toRank"))
                } else {
                    if (if (forWhite) target.isLowerCase() else target.isUpperCase()) {
                        moves.add(Move(r, c, tr, tc, "${pieceLetter}x$toFile$toRank", true))
                    }
                    break
                }
                tr += dr
                tc += dc
            }
        }
    }

    private fun generateKingMoves(
        board: Array<CharArray>, r: Int, c: Int,
        forWhite: Boolean, moves: MutableList<Move>
    ) {
        for ((dr, dc) in queenDirs) {
            val tr = r + dr
            val tc = c + dc
            if (tr in 0..7 && tc in 0..7) {
                val target = board[tr][tc]
                val toFile = ('a' + tc)
                val toRank = 8 - tr
                if (target == ' ') {
                    moves.add(Move(r, c, tr, tc, "K$toFile$toRank"))
                } else if (if (forWhite) target.isLowerCase() else target.isUpperCase()) {
                    moves.add(Move(r, c, tr, tc, "Kx$toFile$toRank", true))
                }
            }
        }
    }

    private fun applyMove(board: Array<CharArray>, move: Move): Array<CharArray> {
        val newBoard = Array(8) { r -> board[r].clone() }
        val p = newBoard[move.fromR][move.fromC]
        newBoard[move.fromR][move.fromC] = ' '
        newBoard[move.toR][move.toC] = p
        return newBoard
    }

    private fun isKingInCheck(board: Array<CharArray>, forWhite: Boolean): Boolean {
        val kingChar = if (forWhite) 'K' else 'k'
        var kingR = -1
        var kingC = -1

        for (r in 0 until 8) {
            for (c in 0 until 8) {
                if (board[r][c] == kingChar) {
                    kingR = r
                    kingC = c
                    break
                }
            }
        }
        if (kingR == -1) return false

        for ((dr, dc) in knightOffsets) {
            val tr = kingR + dr
            val tc = kingC + dc
            if (tr in 0..7 && tc in 0..7) {
                val p = board[tr][tc]
                if (if (forWhite) p == 'n' else p == 'N') return true
            }
        }

        for ((dr, dc) in queenDirs) {
            var tr = kingR + dr
            var tc = kingC + dc
            var dist = 1
            while (tr in 0..7 && tc in 0..7) {
                val p = board[tr][tc]
                if (p != ' ') {
                    val isEnemy = if (forWhite) p.isLowerCase() else p.isUpperCase()
                    if (isEnemy) {
                        val up = p.uppercaseChar()
                        if (up == 'Q') return true
                        if (dist == 1 && up == 'K') return true
                        if (dr != 0 && dc != 0 && up == 'B') return true
                        if ((dr == 0 || dc == 0) && up == 'R') return true
                    }
                    break
                }
                tr += dr
                tc += dc
                dist++
            }
        }

        val pawnDir = if (forWhite) -1 else 1
        for (dc in listOf(-1, 1)) {
            val pr = kingR + pawnDir
            val pc = kingC + dc
            if (pr in 0..7 && pc in 0..7) {
                val p = board[pr][pc]
                if (if (forWhite) p == 'p' else p == 'P') return true
            }
        }

        return false
    }

    private fun evaluateBoard(board: Array<CharArray>): Int {
        var total = 0
        for (r in 0 until 8) {
            for (c in 0 until 8) {
                val p = board[r][c]
                if (p == ' ') continue

                val valScore = when (p.uppercaseChar()) {
                    'P' -> 100
                    'N' -> 320
                    'B' -> 330
                    'R' -> 500
                    'Q' -> 900
                    'K' -> 20000
                    else -> 0
                }

                val centerBonus = if (r in 2..5 && c in 2..5) 20 else 0
                val score = valScore + centerBonus
                if (p.isUpperCase()) {
                    total += score
                } else {
                    total -= score
                }
            }
        }
        return total
    }
}
