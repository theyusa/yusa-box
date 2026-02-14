package com.yusabox.vpn

import android.util.Log

object SingBoxWrapper {
    private val TAG = "SingBoxWrapper"
    var isLoaded = false

    init {
        try {
            System.loadLibrary("box")
            isLoaded = true
            Log.i(TAG, "SingBox library loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "Failed to load SingBox library: ${e.message}", e)
            isLoaded = false
        } catch (e: Exception) {
            Log.e(TAG, "Error loading SingBox library: ${e.message}", e)
            isLoaded = false
        }
    }

    external fun setup(assetPath: String, tempPath: String, disableMemoryLimit: Boolean)
    external fun newService(config: String, fd: Long): Long
    external fun startService(ptr: Long)
    external fun closeService(ptr: Long)
    external fun nativeProtect(socket: Int): Boolean
    external fun getTrafficStats(): Array<Long>
}
