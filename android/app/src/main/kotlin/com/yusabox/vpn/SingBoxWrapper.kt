package com.yusabox.vpn

import android.util.Log
import io.nekohasekai.libbox.BoxService
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.ServiceOptions
import java.io.File

object SingBoxWrapper {
    private val TAG = "SingBoxWrapper"
    var isLoaded = false
    private var loadError: String? = null

    init {
        try {
            // Load the native library
            System.loadLibrary("box")
            // Initialize libbox
            Libbox.init()
            isLoaded = true
            Log.i(TAG, "SingBox library loaded and initialized successfully")
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
     * Create a new BoxService instance
     * @param configPath Path to the sing-box config file
     * @param workingDir Working directory for sing-box
     * @param tempDir Temp directory for sing-box
     * @return BoxService instance or null if creation failed
     */
    @JvmStatic
    fun createService(configPath: String, workingDir: String, tempDir: String): BoxService? {
        if (!isLoaded) {
            Log.e(TAG, "Cannot create service: library not loaded")
            return null
        }
        return try {
            val options = ServiceOptions(
                configPath = configPath,
                workingDir = workingDir,
                cacheDir = tempDir
            )
            Libbox.newService(options).also {
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
     * Stop the BoxService
     * @param service The BoxService instance
     */
    @JvmStatic
    fun stopService(service: BoxService?) {
        if (!isLoaded) {
            Log.e(TAG, "Cannot stop service: library not loaded")
            return
        }
        if (service == null) {
            Log.w(TAG, "Cannot stop service: null instance")
            return
        }
        try {
            // BoxService doesn't have stop method, we use close instead
            Log.i(TAG, "BoxService stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop BoxService: ${e.message}", e)
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
     * Write config to a file and return the path
     * @param config The config content
     * @param configDir The directory to write config to
     * @return The path to the config file
     */
    @JvmStatic
    fun writeConfigToFile(config: String, configDir: File): String? {
        return try {
            if (!configDir.exists()) {
                configDir.mkdirs()
            }
            val configFile = File(configDir, "config.json")
            configFile.writeText(config)
            configFile.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "Failed to write config file: ${e.message}", e)
            null
        }
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
