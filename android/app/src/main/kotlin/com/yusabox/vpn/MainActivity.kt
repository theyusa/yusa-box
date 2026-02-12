package com.yusabox.vpn

import android.app.Activity
import android.content.Intent
import android.net.VpnService
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
                    startVpnService(config, result)
                }
                "stopVpn" -> {
                    stopVpnService(result)
                }
                "getTrafficStats" -> {
                    getTrafficStats(result)
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
    }

    private fun requestVpnPermission(result: MethodChannel.Result) {
        val intent = VpnService.prepare(this)
        if (intent != null) {
            pendingResult = result
            startActivityForResult(intent, VPN_REQUEST_CODE)
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
        }
    }

    private fun startVpnService(config: String?, result: MethodChannel.Result) {
        if (config == null) {
            result.error("INVALID_CONFIG", "Config is null", null)
            return
        }

        val intent = Intent(this, SingBoxVpnService::class.java).apply {
            action = SingBoxVpnService.ACTION_START
            putExtra(SingBoxVpnService.EXTRA_CONFIG, config)
        }

        startService(intent)
        result.success(true)
    }

    private fun stopVpnService(result: MethodChannel.Result) {
        val intent = Intent(this, SingBoxVpnService::class.java).apply {
            action = SingBoxVpnService.ACTION_STOP
        }

        startService(intent)
        result.success(true)
    }

    private fun getTrafficStats(result: MethodChannel.Result) {
        val stats = VpnServiceManager.getTrafficStats()
        result.success(stats)
    }
}
