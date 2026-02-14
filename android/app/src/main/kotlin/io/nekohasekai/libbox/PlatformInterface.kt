package io.nekohasekai.libbox

import android.net.Network
import android.os.ParcelFileDescriptor

/**
 * PlatformInterface is the interface that must be implemented by the platform
 * to provide platform-specific functionality to sing-box.
 */
interface PlatformInterface {
    
    /**
     * Open a TUN interface
     * @param options TUN options
     * @return ParcelFileDescriptor for the TUN interface
     */
    fun openTun(options: TunOptions): ParcelFileDescriptor
    
    /**
     * Close the default interface monitor
     */
    fun closeDefaultInterfaceMonitor()
    
    /**
     * Start the default interface monitor
     */
    fun startDefaultInterfaceMonitor()
    
    /**
     * Clear DNS cache
     */
    fun clearDNSCache()
    
    /**
     * Find the connection owner UID
     * @param protocol Protocol (tcp/udp)
     * @param sourceIp Source IP address
     * @param sourcePort Source port
     * @return UID of the connection owner
     */
    fun findConnectionOwner(protocol: Int, sourceIp: String, sourcePort: Int): Int
    
    /**
     * Get network interfaces
     * @return Network interface iterator
     */
    fun getInterfaces(): NetworkInterfaceIterator
    
    /**
     * Get package name by UID
     * @param uid User ID
     * @return Package name
     */
    fun packageNameByUid(uid: Int): String
    
    /**
     * Get UID by package name
     * @param packageName Package name
     * @return User ID
     */
    fun uidByPackageName(packageName: String): Int
    
    /**
     * Read WiFi state
     * @return WiFi state
     */
    fun readWIFIState(): WIFIState?
    
    /**
     * Include all networks
     * @return true if all networks should be included
     */
    fun includeAllNetworks(): Boolean
    
    /**
     * Use platform auto-detect interface control
     * @return true if platform auto-detect should be used
     */
    fun usePlatformAutoDetectInterfaceControl(): Boolean
    
    /**
     * Auto-detect interface control
     * @return true if successful
     */
    fun autoDetectInterfaceControl(): Boolean
    
    /**
     * Get local DNS transport
     * @return Local DNS transport address
     */
    fun localDNSTransport(): String?
    
    /**
     * Send a notification
     * @param notification Notification data
     */
    fun sendNotification(notification: NotificationData)
    
    /**
     * Check if running under network extension (iOS specific, always false on Android)
     * @return false on Android
     */
    fun underNetworkExtension(): Boolean
    
    /**
     * Get system certificates
     * @return System certificates
     */
    fun systemCertificates(): String
}

/**
 * TUN options for opening TUN interface
 */
data class TunOptions(
    val mtu: Int,
    val gso: Boolean,
    val inet4Address: String?,
    val inet6Address: String?,
    val dnsServers: List<String>
)

/**
 * Network interface iterator
 */
interface NetworkInterfaceIterator {
    fun hasNext(): Boolean
    fun next(): NetworkInterface
}

/**
 * Network interface information
 */
data class NetworkInterface(
    val name: String,
    val addresses: List<String>
)

/**
 * WiFi state information
 */
data class WIFIState(
    val ssid: String,
    val bssid: String
)

/**
 * Notification data
 */
data class NotificationData(
    val title: String,
    val content: String
)

/**
 * Interface update listener
 */
interface InterfaceUpdateListener {
    fun updateDefaultInterface(interfaceName: String)
}
