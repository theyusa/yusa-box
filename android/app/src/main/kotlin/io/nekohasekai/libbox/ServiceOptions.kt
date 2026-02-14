package io.nekohasekai.libbox

/**
 * Service options for creating a new BoxService
 */
data class ServiceOptions(
    /**
     * Configuration file path
     */
    val configPath: String,
    
    /**
     * Working directory
     */
    val workingDir: String,
    
    /**
     * Cache directory
     */
    val cacheDir: String,
    
    /**
     * Log level (trace, debug, info, warn, error, fatal, panic)
     */
    val logLevel: String = "info",
    
    /**
     * Whether to disable memory limit
     */
    val disableMemoryLimit: Boolean = false
)
