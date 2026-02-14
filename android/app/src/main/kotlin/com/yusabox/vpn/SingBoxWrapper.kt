package com.yusabox.vpn

import android.util.Log

object SingBoxWrapper {
    private val TAG = "SingBoxWrapper"
    var isLoaded = false
    private var loadError: String? = null

    init {
        try {
            System.loadLibrary("box")
            isLoaded = true
            Log.i(TAG, "SingBox library loaded successfully")
        } catch (e: UnsatisfiedLinkError) {
            loadError = e.message
            Log.e(TAG, "Failed to load SingBox library: ${e.message}", e)
            isLoaded = false
        } catch (e: Exception) {
            loadError = e.message
            Log.e(TAG, "Error loading SingBox library: ${e.message}", e)
            isLoaded = false
        }
    }

    fun getLoadError(): String? = loadError

    @JvmStatic
    fun setup(assetPath: String, tempPath: String, disableMemoryLimit: Boolean) {
        if (!isLoaded) {
            Log.e(TAG, "Cannot setup: library not loaded")
            throw IllegalStateException("SingBox library not loaded: $loadError")
        }
        try {
            nativeSetup(assetPath, tempPath, disableMemoryLimit)
        } catch (e: Exception) {
            Log.e(TAG, "Setup failed: ${e.message}", e)
            throw e
        }
    }

    @JvmStatic
    fun newService(config: String, fd: Long): Long {
        if (!isLoaded) {
            Log.e(TAG, "Cannot create service: library not loaded")
            return 0L
        }
        return try {
            nativeNewService(config, fd)
        } catch (e: Exception) {
            Log.e(TAG, "New service failed: ${e.message}", e)
            0L
        }
    }

    @JvmStatic
    fun startService(ptr: Long) {
        if (!isLoaded) {
            Log.e(TAG, "Cannot start service: library not loaded")
            return
        }
        if (ptr == 0L) {
            Log.e(TAG, "Cannot start service: invalid pointer")
            return
        }
        try {
            nativeStartService(ptr)
        } catch (e: Exception) {
            Log.e(TAG, "Start service failed: ${e.message}", e)
            throw e
        }
    }

    @JvmStatic
    fun closeService(ptr: Long) {
        if (!isLoaded) {
            Log.e(TAG, "Cannot close service: library not loaded")
            return
        }
        if (ptr == 0L) {
            Log.w(TAG, "Cannot close service: invalid pointer")
            return
        }
        try {
            nativeCloseService(ptr)
        } catch (e: Exception) {
            Log.e(TAG, "Close service failed: ${e.message}", e)
        }
    }

    @JvmStatic
    fun nativeProtect(socket: Int): Boolean {
        if (!isLoaded) {
            Log.e(TAG, "Cannot protect socket: library not loaded")
            return false
        }
        return try {
            nativeProtectSocket(socket)
        } catch (e: Exception) {
            Log.e(TAG, "Socket protection failed: ${e.message}", e)
            false
        }
    }

    @JvmStatic
    fun getTrafficStats(): Array<Long> {
        if (!isLoaded) {
            Log.e(TAG, "Cannot get traffic stats: library not loaded")
            return arrayOf(0L, 0L)
        }
        return try {
            nativeGetTrafficStats()
        } catch (e: Exception) {
            Log.e(TAG, "Get traffic stats failed: ${e.message}", e)
            arrayOf(0L, 0L)
        }
    }

    // Native fonksiyonlar - private
    private external fun nativeSetup(assetPath: String, tempPath: String, disableMemoryLimit: Boolean)
    private external fun nativeNewService(config: String, fd: Long): Long
    private external fun nativeStartService(ptr: Long)
    private external fun nativeCloseService(ptr: Long)
    private external fun nativeProtectSocket(socket: Int): Boolean
    private external fun nativeGetTrafficStats(): Array<Long>
    
    fun resetAllConnections(reset: Boolean) {
        if (isLoaded) {
            try {
                Libbox.resetAllConnections(reset)
            } catch (e: Exception) {
                Log.w("SingBoxWrapper", "Failed to reset connections: ${e.message}")
            }
        }
    }
}

object Libbox {
    external fun resetAllConnections(reset: Boolean)
}

object SagerNet {
    var underlyingNetwork: android.net.Network? = null
}
