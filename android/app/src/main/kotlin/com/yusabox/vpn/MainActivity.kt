package com.yusabox.vpn

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.yusabox.vpn/service"
    private val EVENT_CHANNEL = "com.yusabox.vpn/status"
    private val VPN_REQUEST_CODE = 100

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var pendingResult: MethodChannel.Result? = null

    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    requestVpnPermission(result)
                }
                "startVpn" -> {
                    val config = call.argument<String>("config")
                    val serverName = call.argument<String>("serverName")
                    startVpnService(config, serverName, result)
                }
                "stopVpn" -> {
                    stopVpnService(result)
                }
                "reconnect" -> {
                    reconnectVpn(result)
                }
                "getTrafficStats" -> {
                    getTrafficStats(result)
                }
                "getStats" -> {
                    getTrafficStats(result)
                }
                "getLogs" -> {
                    getLogs(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        )

        eventChannel?.setStreamHandler(VpnServiceManager.StatusStreamHandler)
        
        Log.i(TAG, "Method channel configured: $METHOD_CHANNEL")
        Log.i(TAG, "Event channel configured: $EVENT_CHANNEL")
    }

    private fun requestVpnPermission(result: MethodChannel.Result) {
        val intent = VpnService.prepare(this)
        if (intent != null) {
            pendingResult = result
            startActivityForResult(intent, VPN_REQUEST_CODE)
            Log.i(TAG, "Requesting VPN permission...")
        } else {
            result.success(true)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == VPN_REQUEST_CODE) {
            val granted = resultCode == Activity.RESULT_OK
            pendingResult?.success(granted)
            pendingResult = null
            
            Log.i(TAG, "VPN permission result: $granted")
            
            if (granted) {
                VpnServiceManager.sendLog("[INFO] VPN permission granted")
            } else {
                VpnServiceManager.sendLog("[ERROR] VPN permission denied")
            }
        }
    }

    private fun startVpnService(config: String?, serverName: String?, result: MethodChannel.Result) {
        if (config == null) {
            result.error("INVALID_CONFIG", "Config is null", null)
            return
        }

        val intent = Intent(this, SingBoxVpnService::class.java).apply {
            action = SingBoxVpnService.ACTION_START
            putExtra(SingBoxVpnService.EXTRA_CONFIG, config)
            putExtra(SingBoxVpnService.EXTRA_SERVER_NAME, serverName ?: "Unknown")
        }

        startService(intent)
        result.success(true)
        
        Log.i(TAG, "Starting VPN service: $serverName")
    }

    private fun stopVpnService(result: MethodChannel.Result) {
        val intent = Intent(this, SingBoxVpnService::class.java).apply {
            action = SingBoxVpnService.ACTION_STOP
        }

        startService(intent)
        result.success(true)
        
        Log.i(TAG, "Stopping VPN service")
    }
    
    private fun reconnectVpn(result: MethodChannel.Result) {
        val intent = Intent(this, SingBoxVpnService::class.java).apply {
            action = SingBoxVpnService.ACTION_RECONNECT
        }

        startService(intent)
        result.success(true)
        
        Log.i(TAG, "Requesting VPN reconnect")
    }

    private fun getTrafficStats(result: MethodChannel.Result) {
        val stats = VpnServiceManager.getTrafficStats()
        result.success(stats)
    }
    
    private fun getLogs(result: MethodChannel.Result) {
        val logs = VpnServiceManager.getAllLogs()
        result.success(logs)
        Log.i(TAG, "Returning ${logs.size} log entries")
    }
}
