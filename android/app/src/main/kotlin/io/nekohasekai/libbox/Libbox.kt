package io.nekohasekai.libbox

import android.os.ParcelFileDescriptor

/**
 * Libbox is the main entry point for sing-box native library.
 * This class provides static methods to interact with the sing-box core.
 */
object Libbox {
    
    init {
        System.loadLibrary("box")
    }
    
    /**
     * Initialize the libbox library with setup options
     * @param options Setup options
     */
    @JvmStatic
    external fun setup(options: SetupOptions)
    
    /**
     * Create a new BoxService instance
     * @param config Config content as String
     * @param platformInterface Platform interface implementation
     * @return BoxService instance
     */
    @JvmStatic
    external fun newService(config: String, platformInterface: PlatformInterface): BoxService
    
    /**
     * Set memory limit
     * @param limit Whether to enable memory limit
     */
    @JvmStatic
    external fun setMemoryLimit(limit: Boolean)
    
    /**
     * Set locale
     * @param locale Locale string (e.g., "en_US")
     */
    @JvmStatic
    external fun setLocale(locale: String)
    
    /**
     * Redirect stderr to file
     * @param path File path
     */
    @JvmStatic
    external fun redirectStderr(path: String)
    
    /**
     * Check if a config is valid
     * @param config Config content
     * @return Error message if invalid, null if valid
     */
    @JvmStatic
    external fun checkConfig(config: String): String?
    
    /**
     * Format config to standard format
     * @param config Config content
     * @return Formatted config
     */
    @JvmStatic
    external fun formatConfig(config: String): String
    
    /**
     * Format bytes to human readable string
     * @param bytes Number of bytes
     * @return Human readable string (e.g., "1.5 MB")
     */
    @JvmStatic
    external fun formatBytes(bytes: Long): String
    
    /**
     * Protect a socket from VPN routing
     * @param fd Socket file descriptor
     * @return true if successful
     */
    @JvmStatic
    external fun protect(fd: Int): Boolean
    
    /**
     * Reset all connections
     * @param reset Whether to reset connections
     */
    @JvmStatic
    external fun resetAllConnections(reset: Boolean)
    
    // Interface types
    const val InterfaceTypeWIFI = 0
    const val InterfaceTypeCellular = 1
    const val InterfaceTypeEthernet = 2
    const val InterfaceTypeOther = 3
}
