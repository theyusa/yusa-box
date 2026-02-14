package com.yusabox.vpn

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Process
import android.system.OsConstants
import android.util.Log
import io.nekohasekai.libbox.DNSServerAddress
import io.nekohasekai.libbox.Inet4Address
import io.nekohasekai.libbox.Inet4AddressIterator
import io.nekohasekai.libbox.Inet4RouteAddress
import io.nekohasekai.libbox.Inet4RouteAddressIterator
import io.nekohasekai.libbox.Inet4RouteRange
import io.nekohasekai.libbox.Inet4RouteRangeIterator
import io.nekohasekai.libbox.Inet6Address
import io.nekohasekai.libbox.Inet6AddressIterator
import io.nekohasekai.libbox.Inet6RouteAddress
import io.nekohasekai.libbox.Inet6RouteAddressIterator
import io.nekohasekai.libbox.Inet6RouteRange
import io.nekohasekai.libbox.Inet6RouteRangeIterator
import io.nekohasekai.libbox.InterfaceUpdateListener
import io.nekohasekai.libbox.LocalDNSTransport
import io.nekohasekai.libbox.NetworkInterface
import io.nekohasekai.libbox.NetworkInterfaceIterator
import io.nekohasekai.libbox.PlatformInterface
import io.nekohasekai.libbox.StringIterator
import io.nekohasekai.libbox.TunOptions
import io.nekohasekai.libbox.WIFIState
import java.net.Inet6Address as JavaInet6Address
import java.net.InetSocketAddress
import java.net.NetworkInterface as JavaNetworkInterface

class PlatformInterfaceImpl(private val service: SingBoxVpnService) : PlatformInterface {

    companion object {
        private const val TAG = "PlatformInterface"
    }

    override fun openTun(options: TunOptions): Int {
        return service.openTunInterface(options)
    }

    override fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        // Not implemented for now
    }

    override fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener) {
        // Not implemented for now
    }

    override fun clearDNSCache() {
        // Not implemented for now
    }

    override fun findConnectionOwner(
        ipProtocol: Int,
        sourceAddress: String,
        sourcePort: Int,
        destinationAddress: String,
        destinationPort: Int
    ): Int {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val connectivityManager = service.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                connectivityManager.getConnectionOwnerUid(
                    ipProtocol,
                    InetSocketAddress(sourceAddress, sourcePort),
                    InetSocketAddress(destinationAddress, destinationPort)
                )
            } else {
                Process.INVALID_UID
            }
        } catch (e: Exception) {
            Log.e(TAG, "findConnectionOwner failed", e)
            Process.INVALID_UID
        }
    }

    override fun getInterfaces(): NetworkInterfaceIterator {
        val interfaces = mutableListOf<NetworkInterface>()
        try {
            val connectivityManager = service.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val networks = connectivityManager.allNetworks
            val networkInterfaces = JavaNetworkInterface.getNetworkInterfaces().toList()
            
            for (network in networks) {
                val boxInterface = NetworkInterface()
                val linkProperties = connectivityManager.getLinkProperties(network) ?: continue
                val networkCapabilities = connectivityManager.getNetworkCapabilities(network) ?: continue
                
                boxInterface.name = linkProperties.interfaceName ?: continue
                val networkInterface = networkInterfaces.find { it.name == boxInterface.name } ?: continue
                
                boxInterface.dnsServer = StringArray(linkProperties.dnsServers.mapNotNull { it.hostAddress }.iterator())
                boxInterface.type = when {
                    networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> 
                        io.nekohasekai.libbox.Libbox.InterfaceTypeWIFI
                    networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> 
                        io.nekohasekai.libbox.Libbox.InterfaceTypeCellular
                    networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> 
                        io.nekohasekai.libbox.Libbox.InterfaceTypeEthernet
                    else -> io.nekohasekai.libbox.Libbox.InterfaceTypeOther
                }
                boxInterface.index = networkInterface.index
                
                try {
                    boxInterface.mtu = networkInterface.mtu
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to get mtu for interface ${boxInterface.name}", e)
                }
                
                boxInterface.addresses = StringArray(
                    networkInterface.interfaceAddresses.map { 
                        "${it.address.hostAddress}/${it.networkPrefixLength}"
                    }.iterator()
                )
                
                var dumpFlags = 0
                if (networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
                    dumpFlags = OsConstants.IFF_UP or OsConstants.IFF_RUNNING
                }
                if (networkInterface.isLoopback) {
                    dumpFlags = dumpFlags or OsConstants.IFF_LOOPBACK
                }
                if (networkInterface.isPointToPoint) {
                    dumpFlags = dumpFlags or OsConstants.IFF_POINTOPOINT
                }
                if (networkInterface.supportsMulticast()) {
                    dumpFlags = dumpFlags or OsConstants.IFF_MULTICAST
                }
                boxInterface.flags = dumpFlags
                boxInterface.metered = !networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
                
                interfaces.add(boxInterface)
            }
        } catch (e: Exception) {
            Log.e(TAG, "getInterfaces failed", e)
        }
        
        return NetworkInterfaceArray(interfaces.iterator())
    }

    override fun packageNameByUid(uid: Int): String {
        val packages = service.packageManager.getPackagesForUid(uid)
        return packages?.firstOrNull() ?: ""
    }

    override fun uidByPackageName(packageName: String): Int {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                service.packageManager.getPackageUid(packageName, android.content.pm.PackageManager.PackageInfoFlags.of(0))
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                service.packageManager.getPackageUid(packageName, 0)
            } else {
                service.packageManager.getApplicationInfo(packageName, 0).uid
            }
        } catch (e: Exception) {
            Process.INVALID_UID
        }
    }

    override fun readWIFIState(): WIFIState? {
        return null // Not implemented for now
    }

    override fun includeAllNetworks(): Boolean {
        return false
    }

    override fun usePlatformAutoDetectInterfaceControl(): Boolean {
        return true
    }

    override fun autoDetectInterfaceControl(fd: Int) {
        service.protect(fd)
    }

    override fun useProcFS(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.Q
    }

    override fun localDNSTransport(): LocalDNSTransport? {
        return null // Not implemented for now
    }

    override fun underNetworkExtension(): Boolean {
        return false
    }

    override fun systemCertificates(): StringIterator {
        return StringArray(emptyList<String>().iterator())
    }

    // Helper classes
    private class StringArray(private val iterator: Iterator<String>) : StringIterator {
        override fun len(): Int = 0
        override fun hasNext(): Boolean = iterator.hasNext()
        override fun next(): String = iterator.next()
    }

    private class NetworkInterfaceArray(private val iterator: Iterator<NetworkInterface>) : NetworkInterfaceIterator {
        override fun hasNext(): Boolean = iterator.hasNext()
        override fun next(): NetworkInterface = iterator.next()
    }
}
