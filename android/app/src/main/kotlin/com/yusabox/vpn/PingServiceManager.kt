package com.yusabox.vpn

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import java.net.InetSocketAddress
import java.net.Socket
import kotlin.math.min
import kotlin.math.max

object PingServiceManager {
    private var eventSink: EventChannel.EventSink? = null
    private val pingScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    private val TAG = "PingService"
    private val pingResults = mutableMapOf<String, PingResult>()
    
    data class PingResult(
        val serverId: String,
        val latencyMs: Int,
        val success: Boolean
    )
    
    object StatusStreamHandler : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            eventSink = events
        }

        override fun onCancel(arguments: Any?) {
            eventSink = null
        }
    }
    
    fun pingServer(serverId: String, address: String, port: Int) {
        if (pingResults[serverId]?.isLoading == true) {
            Log.w(TAG, "Ping already in progress for $serverId")
            return
        }
        
        Log.i(TAG, "Starting ping for $serverId ($address:$port)")
        
        sendPingUpdate(serverId, latencyMs = null, success = null, isLoading = true)
        
        pingScope.launch {
            try {
                val latency = measureTcpLatency(address, port, timeoutMs = 3000)
                
                if (latency != null) {
                    pingResults[serverId] = PingResult(serverId, latency, true)
                    sendPingUpdate(serverId, latencyMs = latency, success = true, isLoading = false)
                    Log.i(TAG, "Ping success for $serverId: ${latency}ms")
                } else {
                    pingResults[serverId] = PingResult(serverId, -1, false)
                    sendPingUpdate(serverId, latencyMs = -1, success = false, isLoading = false)
                    Log.w(TAG, "Ping timeout for $serverId")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Ping error for $serverId: ${e.message}", e)
                pingResults[serverId] = PingResult(serverId, -1, false)
                sendPingUpdate(serverId, latencyMs = -1, success = false, isLoading = false)
            }
        }
    }
    
    fun pingServers(servers: List<Map<String, Any>>) {
        Log.i(TAG, "Pinging ${servers.size} servers")
        
        servers.forEach { serverMap ->
            try {
                val serverId = serverMap["id"] as? String ?: ""
                val address = serverMap["address"] as? String ?: ""
                val port = (serverMap["port"] as? Number)?.toInt() ?: 443
                
                if (serverId.isNotEmpty() && address.isNotEmpty()) {
                    pingScope.launch {
                        val latency = measureTcpLatency(address, port, timeoutMs = 3000)
                        
                        if (latency != null) {
                            pingResults[serverId] = PingResult(serverId, latency, true)
                            sendPingUpdate(serverId, latencyMs = latency, success = true, isLoading = false)
                        } else {
                            pingResults[serverId] = PingResult(serverId, -1, false)
                            sendPingUpdate(serverId, latencyMs = -1, success = false, isLoading = false)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error pinging server: ${e.message}")
            }
        }
    }
    
    private fun measureTcpLatency(address: String, port: Int, timeoutMs: Int): Int? {
        return try {
            val startTime = System.currentTimeMillis()
            val socket = Socket()
            socket.soTimeout = timeoutMs
            socket.connect(InetSocketAddress(address, port), timeoutMs.toLong())
            val latency = (System.currentTimeMillis() - startTime).toInt()
            socket.close()
            latency
        } catch (e: Exception) {
            when (e) {
                is java.net.SocketTimeoutException -> null
                is java.net.UnknownHostException -> null
                is java.net.ConnectException -> null
                else -> {
                    Log.e(TAG, "TCP ping error: ${e.message}")
                    null
                }
            }
        }
    }
    
    private fun sendPingUpdate(serverId: String, latencyMs: Int?, success: Boolean?, isLoading: Boolean) {
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(hashMapOf(
                "serverId" to serverId,
                "latencyMs" to latencyMs,
                "success" to success,
                "isLoading" to isLoading
            ))
        }
    }
    
    fun getPingResult(serverId: String): PingResult? {
        return pingResults[serverId]
    }
    
    fun clearPingResults() {
        pingResults.clear()
        Log.i(TAG, "Ping results cleared")
    }
    
    fun cleanup() {
        pingScope.cancel()
    }
}
