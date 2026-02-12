package com.yusabox.vpn

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.yusabox.vpn/singbox"
    private var pendingConfig: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val config = call.argument<String>("config")
                    if (config != null) {
                        startVpn(config)
                        result.success(null)
                    } else {
                        result.error("INVALID_CONFIG", "Config is null", null)
                    }
                }
                "stop" -> {
                    stopVpn()
                    result.success(null)
                }
                "getStats" -> {
                    // Placeholder for stats
                    result.success("Stats not available yet")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startVpn(config: String) {
        val intent = VpnService.prepare(this)
        if (intent != null) {
            pendingConfig = config
            startActivityForResult(intent, 0)
        } else {
            // Permission already granted
            startService(config)
        }
    }

    private fun startService(config: String) {
        val intent = Intent(this, SingBoxVpnService::class.java)
        intent.action = SingBoxVpnService.ACTION_START
        intent.putExtra(SingBoxVpnService.EXTRA_CONFIG, config)
        startService(intent)
    }

    private fun stopVpn() {
        val intent = Intent(this, SingBoxVpnService::class.java)
        intent.action = SingBoxVpnService.ACTION_STOP
        startService(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == 0 && resultCode == Activity.RESULT_OK) {
            pendingConfig?.let {
                startService(it)
                pendingConfig = null
            }
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
