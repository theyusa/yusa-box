package com.yusabox.vpn

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.util.Timer
import java.util.TimerTask
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object VpnServiceManager {
    var service: SingBoxVpnService? = null
    private var eventSink: EventChannel.EventSink? = null
    private var trafficMonitorTimer: Timer? = null

    private var lastUploadBytes: Long = 0
    private var lastDownloadBytes: Long = 0
    private var connectionStartTime: Long = 0
    
    private val TAG = "VpnServiceManager"
    private val logList = mutableListOf<String>()
    private val maxLogSize = 100
    private var currentServerName: String? = null
    private var currentProtocol: String? = null

    object StatusStreamHandler : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            eventSink = events
        }

        override fun onCancel(arguments: Any?) {
            eventSink = null
        }
    }

    fun updateStatus(state: Int, message: String? = null) {
        Handler(Looper.getMainLooper()).post {
            val statusMap = hashMapOf<String, Any>(
                "state" to state,
            )
            message?.let { statusMap["message"] = it }

            if (state == 2) {
                connectionStartTime = System.currentTimeMillis()
            } else if (state == 0 || state == 3) {
                connectionStartTime = 0
            }

            eventSink?.success(statusMap)
        }
    }
    
    fun updateConnectionInfo(serverName: String) {
        currentServerName = serverName
        sendLog("[INFO] Server: $serverName")
    }
    
    fun isConnected(): Boolean {
        return connectionStartTime > 0
    }

    fun startTrafficMonitoring() {
        stopTrafficMonitoring()
        sendLog("[INFO] Starting traffic monitoring")

        trafficMonitorTimer = Timer()
        trafficMonitorTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                try {
                    val stats = getRealTrafficStats()
                    val uploadSpeed = (stats["uploadSpeed"] as? Long) ?: 0L
                    val downloadSpeed = (stats["downloadSpeed"] as? Long) ?: 0L
                    val connectedSeconds = ((System.currentTimeMillis() - connectionStartTime) / 1000).toInt()

                    lastUploadBytes = (stats["upload"] as? Long) ?: lastUploadBytes
                    lastDownloadBytes = (stats["download"] as? Long) ?: lastDownloadBytes

                    Handler(Looper.getMainLooper()).post {
                        eventSink?.success(hashMapOf(
                            "state" to 2,
                            "upload" to lastUploadBytes.toInt(),
                            "download" to lastDownloadBytes.toInt(),
                            "uploadSpeed" to uploadSpeed.toInt(),
                            "downloadSpeed" to downloadSpeed.toInt(),
                            "connectedTime" to connectedSeconds
                        ))
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Traffic monitoring error: ${e.message}")
                    e.printStackTrace()
                }
            }
        }, 0, 1000)
    }

    fun stopTrafficMonitoring() {
        trafficMonitorTimer?.cancel()
        trafficMonitorTimer = null
        sendLog("[INFO] Traffic monitoring stopped")
    }

    fun getTrafficStats(): Map<String, Int> {
        return hashMapOf(
            "upload" to lastUploadBytes.toInt(),
            "download" to lastDownloadBytes.toInt()
        )
    }
    
    private fun getRealTrafficStats(): Map<String, Long> {
        if (!SingBoxWrapper.isLoaded) {
            return hashMapOf(
                "upload" to lastUploadBytes,
                "download" to lastDownloadBytes,
                "uploadSpeed" to 0L,
                "downloadSpeed" to 0L
            )
        }

        return try {
            val stats = SingBoxWrapper.getTrafficStats()
            val uploadSpeed = stats[0] - lastUploadBytes
            val downloadSpeed = stats[1] - lastDownloadBytes

            hashMapOf(
                "upload" to stats[0],
                "download" to stats[1],
                "uploadSpeed" to uploadSpeed,
                "downloadSpeed" to downloadSpeed
            )
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get traffic stats: ${e.message}")
            hashMapOf(
                "upload" to lastUploadBytes,
                "download" to lastDownloadBytes,
                "uploadSpeed" to 0L,
                "downloadSpeed" to 0L
            )
        }
    }

    fun sendLog(message: String) {
        val timestamp = SimpleDateFormat("HH:mm:ss", Locale.US).format(Date())
        val logMessage = "[$timestamp] $message"
        
        logList.add(0, logMessage)
        if (logList.size > maxLogSize) {
            logList.removeAt(logList.size - 1)
        }
        
        Log.i(TAG, logMessage)
        
        eventSink?.success(hashMapOf(
            "log" to logMessage
        ))
    }
    
    fun getAllLogs(): List<String> {
        return logList.toList()
    }
    
    fun clearLogs() {
        logList.clear()
        sendLog("[INFO] Logs cleared")
    }
}
