package com.yusabox.vpn

import android.util.Log
import io.nekohasekai.libbox.BoxService
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.SetupOptions

object SingBoxWrapper {
    private val TAG = "SingBoxWrapper"
    var isLoaded = false
    private var loadError: String? = null

    init {
        try {
            // Load the native library
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

    /**
     * Initialize libbox with setup options
     * @param basePath Base path for libbox
     * @param workingPath Working directory path
     * @param tempPath Temp directory path
     */
    @JvmStatic
    fun setup(basePath: String, workingPath: String, tempPath: String) {
        if (!isLoaded) {
            Log.e(TAG, "Cannot setup: library not loaded")
            throw IllegalStateException("SingBox library not loaded: $loadError")
        }
        try {
            val options = SetupOptions().apply {
                this.basePath = basePath
                this.workingPath = workingPath
                this.tempPath = tempPath
            }
            Libbox.setup(options)
            Log.i(TAG, "Libbox setup completed")
        } catch (e: Exception) {
            Log.e(TAG, "Setup failed: ${e.message}", e)
            throw e
        }
    }

    /**
     * Create a new BoxService instance
     * @param config Config content as String (JSON)
     * @param platformInterface Platform interface implementation
     * @return BoxService instance or null if creation failed
     */
    @JvmStatic
    fun createService(config: String, platformInterface: io.nekohasekai.libbox.PlatformInterface): BoxService? {
        if (!isLoaded) {
            Log.e(TAG, "Cannot create service: library not loaded")
            return null
        }
        return try {
            Libbox.newService(config, platformInterface).also {
                Log.i(TAG, "BoxService created successfully")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to create BoxService: ${e.message}", e)
            null
        }
    }

    /**
     * Start the BoxService
     * @param service The BoxService instance
     */
    @JvmStatic
    fun startService(service: BoxService?) {
        if (!isLoaded) {
            Log.e(TAG, "Cannot start service: library not loaded")
            return
        }
        if (service == null) {
            Log.e(TAG, "Cannot start service: null instance")
            return
        }
        try {
            service.start()
            Log.i(TAG, "BoxService started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start BoxService: ${e.message}", e)
            throw e
        }
    }

    /**
     * Close and cleanup the BoxService
     * @param service The BoxService instance
     */
    @JvmStatic
    fun closeService(service: BoxService?) {
        if (!isLoaded) {
            Log.e(TAG, "Cannot close service: library not loaded")
            return
        }
        if (service == null) {
            Log.w(TAG, "Cannot close service: null instance")
            return
        }
        try {
            service.close()
            Log.i(TAG, "BoxService closed successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to close BoxService: ${e.message}", e)
        }
    }

    /**
     * Protect a socket from VPN routing
     * @param socket The socket file descriptor
     * @return true if successful
     */
    @JvmStatic
    fun nativeProtect(socket: Int): Boolean {
        if (!isLoaded) {
            Log.e(TAG, "Cannot protect socket: library not loaded")
            return false
        }
        if (socket < 0) {
            Log.e(TAG, "Cannot protect socket: invalid fd")
            return false
        }
        return try {
            Libbox.protect(socket)
        } catch (e: Exception) {
            Log.e(TAG, "Socket protection failed: ${e.message}", e)
            false
        }
    }

    /**
     * Get traffic statistics
     * @return Pair of (upload bytes, download bytes)
     */
    @JvmStatic
    fun getTrafficStats(): Pair<Long, Long> {
        if (!isLoaded) {
            Log.e(TAG, "Cannot get traffic stats: library not loaded")
            return Pair(0L, 0L)
        }
        // Traffic stats not directly available in this API version
        // Return dummy values
        return Pair(0L, 0L)
    }

    /**
     * Reset all connections
     * @param reset Whether to reset connections
     */
    fun resetAllConnections(reset: Boolean) {
        if (isLoaded) {
            try {
                Libbox.resetAllConnections(reset)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to reset connections: ${e.message}")
            }
        }
    }
}

object SagerNet {
    var underlyingNetwork: android.net.Network? = null
}
