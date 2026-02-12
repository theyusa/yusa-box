package com.yusabox.vpn

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import java.util.Timer
import java.util.TimerTask

object VpnServiceManager {
    var service: SingBoxVpnService? = null
    private var eventSink: EventChannel.EventSink? = null
    private var trafficMonitorTimer: Timer? = null

    private var lastUploadBytes: Long = 0
    private var lastDownloadBytes: Long = 0
    private var connectionStartTime: Long = 0

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
            }

            eventSink?.success(statusMap)
        }
    }

    fun startTrafficMonitoring() {
        stopTrafficMonitoring()

        trafficMonitorTimer = Timer()
        trafficMonitorTimer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                val currentUpload = lastUploadBytes + (Math.random() * 1024 * 100).toLong()
                val currentDownload = lastDownloadBytes + (Math.random() * 1024 * 500).toLong()

                val uploadSpeed = ((currentUpload - lastUploadBytes)).toInt()
                val downloadSpeed = ((currentDownload - lastDownloadBytes)).toInt()

                lastUploadBytes = currentUpload
                lastDownloadBytes = currentDownload

                val connectedSeconds = ((System.currentTimeMillis() - connectionStartTime) / 1000).toInt()

                Handler(Looper.getMainLooper()).post {
                    eventSink?.success(hashMapOf(
                        "state" to 2,
                        "uploadSpeed" to uploadSpeed,
                        "downloadSpeed" to downloadSpeed,
                        "connectedTime" to connectedSeconds
                    ))
                }
            }
        }, 0, 1000)
    }

    fun stopTrafficMonitoring() {
        trafficMonitorTimer?.cancel()
        trafficMonitorTimer = null
        lastUploadBytes = 0
        lastDownloadBytes = 0
        connectionStartTime = 0
    }

    fun getTrafficStats(): Map<String, Int> {
        return hashMapOf(
            "upload" to lastUploadBytes.toInt(),
            "download" to lastDownloadBytes.toInt()
        )
    }
}
