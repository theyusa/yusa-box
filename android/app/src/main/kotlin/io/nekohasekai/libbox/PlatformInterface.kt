package io.nekohasekai.libbox

import android.os.ParcelFileDescriptor

/**
 * PlatformInterface is the interface that must be implemented by the platform
 * to provide platform-specific functionality to sing-box.
 */
interface PlatformInterface {
    
    /**
     * Open a TUN interface
     * @param options TUN options
     * @return File descriptor for the TUN interface
     */
    fun openTun(options: TunOptions): Int
    
    /**
     * Close the default interface monitor
     * @param listener Interface update listener
     */
    fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener)
    
    /**
     * Start the default interface monitor
     * @param listener Interface update listener
     */
    fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener)
    
    /**
     * Clear DNS cache
     */
    fun clearDNSCache()
    
    /**
     * Find the connection owner UID
     * @param ipProtocol IP protocol (e.g., IPPROTO_TCP = 6, IPPROTO_UDP = 17)
     * @param sourceAddress Source IP address
     * @param sourcePort Source port
     * @param destinationAddress Destination IP address
     * @param destinationPort Destination port
     * @return UID of the connection owner
     */
    fun findConnectionOwner(
        ipProtocol: Int,
        sourceAddress: String,
        sourcePort: Int,
        destinationAddress: String,
        destinationPort: Int
    ): Int
    
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
     * @param fd File descriptor
     */
    fun autoDetectInterfaceControl(fd: Int)
    
    /**
     * Use /proc filesystem
     * @return true if /proc should be used
     */
    fun useProcFS(): Boolean
    
    /**
     * Get local DNS transport
     * @return Local DNS transport
     */
    fun localDNSTransport(): LocalDNSTransport?
    
    /**
     * Check if running under network extension (iOS specific, always false on Android)
     * @return false on Android
     */
    fun underNetworkExtension(): Boolean
    
    /**
     * Get system certificates
     * @return Iterator of system certificates
     */
    fun systemCertificates(): StringIterator
}

/**
 * TUN options for opening TUN interface
 */
class TunOptions {
    var mtu: Int = 0
    var gso: Boolean = false
    var inet4Address: Inet4AddressIterator? = null
    var inet6Address: Inet6AddressIterator? = null
    var dnsServerAddress: DNSServerAddress? = null
    var autoRoute: Boolean = false
    var inet4RouteAddress: Inet4RouteAddressIterator? = null
    var inet6RouteAddress: Inet6RouteAddressIterator? = null
    var inet4RouteExcludeAddress: Inet4RouteAddressIterator? = null
    var inet6RouteExcludeAddress: Inet6RouteAddressIterator? = null
    var inet4RouteRange: Inet4RouteRangeIterator? = null
    var inet6RouteRange: Inet6RouteRangeIterator? = null
    var includePackage: StringIterator? = null
    var excludePackage: StringIterator? = null
    var isHTTPProxyEnabled: Boolean = false
    var httpProxyServer: String = ""
    var httpProxyServerPort: Int = 0
    var httpProxyBypassDomain: StringIterator? = null
}

/**
 * DNS Server Address
 */
class DNSServerAddress {
    var address: String = ""
}

/**
 * Interface update listener
 */
interface InterfaceUpdateListener {
    fun updateDefaultInterface(interfaceName: String)
}

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
class NetworkInterface {
    var name: String = ""
    var addresses: StringIterator? = null
    var dnsServer: StringIterator? = null
    var type: Int = 0
    var index: Int = 0
    var mtu: Int = 0
    var flags: Int = 0
    var metered: Boolean = false
}

/**
 * WiFi state information
 */
class WIFIState {
    var ssid: String = ""
    var bssid: String = ""
}

/**
 * Local DNS Transport
 */
interface LocalDNSTransport {
    fun lookup(network: String): String
}

/**
 * String iterator
 */
interface StringIterator {
    fun len(): Int
    fun hasNext(): Boolean
    fun next(): String
}

/**
 * Inet4 address iterator
 */
interface Inet4AddressIterator {
    fun hasNext(): Boolean
    fun next(): Inet4Address
}

/**
 * Inet4 address
 */
class Inet4Address {
    fun address(): String = ""
    fun prefix(): Int = 0
}

/**
 * Inet6 address iterator
 */
interface Inet6AddressIterator {
    fun hasNext(): Boolean
    fun next(): Inet6Address
}

/**
 * Inet6 address
 */
class Inet6Address {
    fun address(): String = ""
    fun prefix(): Int = 0
}

/**
 * Inet4 route address iterator
 */
interface Inet4RouteAddressIterator {
    fun hasNext(): Boolean
    fun next(): Inet4RouteAddress
}

/**
 * Inet4 route address
 */
class Inet4RouteAddress {
    fun address(): String = ""
    fun prefix(): Int = 0
}

/**
 * Inet6 route address iterator
 */
interface Inet6RouteAddressIterator {
    fun hasNext(): Boolean
    fun next(): Inet6RouteAddress
}

/**
 * Inet6 route address
 */
class Inet6RouteAddress {
    fun address(): String = ""
    fun prefix(): Int = 0
}

/**
 * Inet4 route range iterator
 */
interface Inet4RouteRangeIterator {
    fun hasNext(): Boolean
    fun next(): Inet4RouteRange
}

/**
 * Inet4 route range
 */
class Inet4RouteRange {
    fun address(): String = ""
    fun prefix(): Int = 0
}

/**
 * Inet6 route range iterator
 */
interface Inet6RouteRangeIterator {
    fun hasNext(): Boolean
    fun next(): Inet6RouteRange
}

/**
 * Inet6 route range
 */
class Inet6RouteRange {
    fun address(): String = ""
    fun prefix(): Int = 0
}
