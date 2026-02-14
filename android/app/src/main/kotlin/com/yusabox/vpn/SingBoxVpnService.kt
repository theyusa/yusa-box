package com.yusabox.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.net.ConnectivityManager
import android.net.Network
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import io.nekohasekai.libbox.BoxService
import io.nekohasekai.libbox.Libbox
import io.nekohasekai.libbox.TunOptions
import go.Seq

class SingBoxVpnService : VpnService() {

    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            super.onAvailable(network)
            Log.i(TAG, "Network available: $network")
            VpnServiceManager.sendLog("[NATIVE] Network available")
            
            if (VpnServiceManager.isConnected() && currentConfig != null) {
                Log.i(TAG, "Attempting auto-reconnect after network restore")
                VpnServiceManager.sendLog("[NATIVE] Auto-reconnecting after network restore...")
                connectionRetryCount = 0
                attemptRetry()
            }
        }

        override fun onLost(network: Network) {
            super.onLost(network)
            Log.i(TAG, "Network lost: $network")
            VpnServiceManager.sendLog("[NATIVE] Network lost")
            
            if (VpnServiceManager.isConnected()) {
                Log.i(TAG, "VPN was connected, resetting connections...")
                resetConnections()
                Log.i(TAG, "VPN was connected, will attempt reconnect on network restore")
                VpnServiceManager.updateStatus(3, "Network kayboldu, yeniden bağlanılıyor...")
            }
        }
    }

    private var interfaceDescriptor: ParcelFileDescriptor? = null
    private var boxService: BoxService? = null
    private var platformInterface: PlatformInterfaceImpl? = null
    private var connectionStartTime: Long = 0
    
    private val TAG = "SingBoxVpnService"
    private var connectionRetryCount = 0
    private val maxRetryCount = 3
    private var currentConfig: String? = null
    private var currentServerName: String? = null

    companion object {
        const val ACTION_START = "com.yusabox.vpn.START"
        const val ACTION_STOP = "com.yusabox.vpn.STOP"
        const val ACTION_RECONNECT = "com.yusabox.vpn.RECONNECT"
        const val EXTRA_CONFIG = "config"
        const val EXTRA_SERVER_NAME = "server_name"
        const val CHANNEL_ID = "vpn_channel"
        const val NOTIFICATION_ID = 1001
        
        const val STATE_DISCONNECTED = 0
        const val STATE_CONNECTING = 1
        const val STATE_CONNECTED = 2
        const val STATE_ERROR = 4
    }

    private var isLibraryLoaded = false
    private var wakeLock: android.os.PowerManager.WakeLock? = null

    init {
        isLibraryLoaded = SingBoxWrapper.isLoaded
        if (isLibraryLoaded) {
            Log.i(TAG, "SingBox library loaded successfully")
        } else {
            val error = SingBoxWrapper.getLoadError()
            Log.e(TAG, "SingBox library NOT loaded. Error: $error")
        }
    }

    override fun onCreate() {
        super.onCreate()
        
        // Initialize go.Seq
        Seq.setContext(this)
        
        // Setup libbox
        try {
            val baseDir = filesDir
            baseDir.mkdirs()
            val workingDir = getExternalFilesDir(null) ?: filesDir
            workingDir.mkdirs()
            val tempDir = cacheDir
            tempDir.mkdirs()
            
            SingBoxWrapper.setup(baseDir.path, workingDir.path, tempDir.path)
            Log.i(TAG, "Libbox setup completed")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to setup libbox: ${e.message}", e)
        }
        
        createNotificationChannel()
        VpnServiceManager.service = this
        
        registerNetworkCallback()
        acquireWakeLock()
        
        Log.i(TAG, "SingBox VPN Service created")
        VpnServiceManager.sendLog("[NATIVE] Service initialized")
    }

    private fun registerNetworkCallback() {
        val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        try {
            connectivityManager.registerDefaultNetworkCallback(networkCallback)
            Log.i(TAG, "Network callback registered")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register network callback: ${e.message}")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val config = intent.getStringExtra(EXTRA_CONFIG)
                currentConfig = config
                currentServerName = intent.getStringExtra(EXTRA_SERVER_NAME)
                if (config != null) {
                    connectionRetryCount = 0
                    startVpn(config)
                }
            }
            ACTION_STOP -> {
                stopVpn()
                connectionRetryCount = 0
            }
            ACTION_RECONNECT -> {
                if (currentConfig != null) {
                    connectionRetryCount++
                    if (connectionRetryCount <= maxRetryCount) {
                        Log.i(TAG, "Reconnecting attempt $connectionRetryCount/$maxRetryCount")
                        VpnServiceManager.sendLog("[NATIVE] Reconnecting... ($connectionRetryCount/$maxRetryCount)")
                        stopVpn()
                        startVpn(currentConfig!!)
                    } else {
                        Log.w(TAG, "Max retry count reached")
                        VpnServiceManager.sendLog("[NATIVE] Max retry count reached")
                        VpnServiceManager.updateStatus(STATE_ERROR, "Maksimum yeniden bağlanma sayısı aşıldı")
                    }
                }
            }
        }
        return START_NOT_STICKY
    }

    private fun startVpn(config: String) {
        Log.i(TAG, "=== START VPN CALLED ===")
        
        VpnServiceManager.updateStatus(STATE_CONNECTING, "Bağlanıyor...")
        
        val serverName = currentServerName ?: "Bilinmeyen"
        VpnServiceManager.updateConnectionInfo(serverName)
        
        // VPN işlemini arka plan thread'inde çalıştır
        Thread {
            try {
                // Library kontrolü
                if (!SingBoxWrapper.isLoaded) {
                    val error = SingBoxWrapper.getLoadError()
                    Log.e(TAG, "SingBox library not loaded. Error: $error")
                    VpnServiceManager.updateStatus(STATE_ERROR, "Library yüklenmedi: $error")
                    VpnServiceManager.sendLog("[ERROR] SingBox library not loaded: $error")
                    Handler(Looper.getMainLooper()).post { stopVpn() }
                    return@Thread
                }

                if (config.isEmpty()) {
                    Log.e(TAG, "Config is empty")
                    VpnServiceManager.updateStatus(STATE_ERROR, "Config boş")
                    VpnServiceManager.sendLog("[ERROR] Config is empty")
                    Handler(Looper.getMainLooper()).post { stopVpn() }
                    return@Thread
                }

                // Foreground service başlat
                try {
                    startForeground(NOTIFICATION_ID, createNotification("Bağlanıyor..."))
                    Log.i(TAG, "Foreground service started")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start foreground service: ${e.message}", e)
                    VpnServiceManager.updateStatus(STATE_ERROR, "Foreground service hatası")
                    return@Thread
                }

                Log.i(TAG, "Starting VPN with server: $serverName")
                Log.d(TAG, "Config length: ${config.length} bytes")
                
                // Create PlatformInterface
                platformInterface = PlatformInterfaceImpl(this)

                // Create BoxService with config String (not file path!)
                try {
                    boxService = SingBoxWrapper.createService(config, platformInterface!!)
                    if (boxService == null) {
                        Log.e(TAG, "Failed to create BoxService")
                        VpnServiceManager.updateStatus(STATE_ERROR, "Service oluşturulamadı")
                        VpnServiceManager.sendLog("[ERROR] Failed to create BoxService")
                        Handler(Looper.getMainLooper()).post { stopVpn() }
                        return@Thread
                    }
                    Log.i(TAG, "BoxService created successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to create BoxService: ${e.message}", e)
                    VpnServiceManager.updateStatus(STATE_ERROR, "Service oluşturma hatası: ${e.message}")
                    VpnServiceManager.sendLog("[ERROR] Service creation failed: ${e.message}")
                    Handler(Looper.getMainLooper()).post { stopVpn() }
                    return@Thread
                }

                // Start BoxService
                try {
                    SingBoxWrapper.startService(boxService)
                    Log.i(TAG, "BoxService started successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start BoxService: ${e.message}", e)
                    VpnServiceManager.updateStatus(STATE_ERROR, "Service başlatma hatası: ${e.message}")
                    VpnServiceManager.sendLog("[ERROR] Service start failed: ${e.message}")
                    Handler(Looper.getMainLooper()).post { stopVpn() }
                    return@Thread
                }

                connectionStartTime = System.currentTimeMillis()
                VpnServiceManager.updateStatus(STATE_CONNECTED, "Bağlandı")
                VpnServiceManager.sendLog("[INFO] Connected to: $serverName")

                VpnServiceManager.startTrafficMonitoring()
                Log.i(TAG, "=== VPN CONNECTION SUCCESSFUL ===")
                
            } catch (e: IllegalStateException) {
                Log.e(TAG, "IllegalStateException: ${e.message}", e)
                VpnServiceManager.updateStatus(STATE_ERROR, "Sistem hatası: ${e.message}")
                VpnServiceManager.sendLog("[ERROR] IllegalStateException: ${e.message}")
                Log.i(TAG, "=== VPN CONNECTION FAILED ===")
            } catch (e: IllegalArgumentException) {
                Log.e(TAG, "IllegalArgumentException: ${e.message}", e)
                VpnServiceManager.updateStatus(STATE_ERROR, "Yanlış config: ${e.message}")
                VpnServiceManager.sendLog("[ERROR] IllegalArgumentException: ${e.message}")
                Log.i(TAG, "=== VPN CONNECTION FAILED ===")
            } catch (e: SecurityException) {
                Log.e(TAG, "SecurityException: ${e.message}", e)
                VpnServiceManager.updateStatus(STATE_ERROR, "İzin hatası: ${e.message}")
                VpnServiceManager.sendLog("[ERROR] SecurityException: ${e.message}")
                Log.i(TAG, "=== VPN CONNECTION FAILED ===")
            } catch (e: UnsatisfiedLinkError) {
                Log.e(TAG, "UnsatisfiedLinkError: ${e.message}", e)
                VpnServiceManager.updateStatus(STATE_ERROR, "Native library hatası: ${e.message}")
                VpnServiceManager.sendLog("[ERROR] Native library error: ${e.message}")
                Log.i(TAG, "=== VPN CONNECTION FAILED ===")
            } catch (e: Exception) {
                Log.e(TAG, "VPN connection error", e)
                e.printStackTrace()
                VpnServiceManager.updateStatus(STATE_ERROR, "Hata: ${e.message}")
                VpnServiceManager.sendLog("[ERROR] VPN connection error: ${e.message}")
                Log.i(TAG, "=== VPN CONNECTION FAILED ===")
            }
        }.start()
    }
    
    /**
     * Open TUN interface - called by PlatformInterface
     */
    fun openTunInterface(options: TunOptions): Int {
        val builder = Builder()
            .setSession("YusaBox VPN")
            .setMtu(options.mtu)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false)
        }

        // Add IPv4 addresses
        options.inet4Address?.let { iterator ->
            while (iterator.hasNext()) {
                val address = iterator.next()
                builder.addAddress(address.address(), address.prefix())
            }
        }

        // Add IPv6 addresses
        options.inet6Address?.let { iterator ->
            while (iterator.hasNext()) {
                val address = iterator.next()
                builder.addAddress(address.address(), address.prefix())
            }
        }

        if (options.autoRoute) {
            // Add DNS server
            options.dnsServerAddress?.let {
                builder.addDnsServer(it.address)
            }

            // Add IPv4 routes
            options.inet4RouteAddress?.let { iterator ->
                while (iterator.hasNext()) {
                    val route = iterator.next()
                    builder.addRoute(route.address(), route.prefix())
                }
            }

            // Add IPv6 routes
            options.inet6RouteAddress?.let { iterator ->
                while (iterator.hasNext()) {
                    val route = iterator.next()
                    builder.addRoute(route.address(), route.prefix())
                }
            }

            // Exclude IPv4 routes
            options.inet4RouteExcludeAddress?.let { iterator ->
                while (iterator.hasNext()) {
                    val route = iterator.next()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        builder.excludeRoute(android.net.IpPrefix(android.net.InetAddresses.parseNumericAddress(route.address()), route.prefix()))
                    }
                }
            }

            // Exclude IPv6 routes
            options.inet6RouteExcludeAddress?.let { iterator ->
                while (iterator.hasNext()) {
                    val route = iterator.next()
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        builder.excludeRoute(android.net.IpPrefix(android.net.InetAddresses.parseNumericAddress(route.address()), route.prefix()))
                    }
                }
            }
        }

        val pfd = builder.establish()
            ?: throw IllegalStateException("android: the application is not prepared or is revoked")
        
        interfaceDescriptor = pfd
        return pfd.fd
    }

    private fun stopVpn() {
        Log.i(TAG, "=== STOP VPN CALLED ===")
        
        VpnServiceManager.updateStatus(3, "Bağlantı kesiliyor...")
        VpnServiceManager.sendLog("[INFO] Disconnecting...")
        
        if (connectionStartTime > 0) {
            val duration = (System.currentTimeMillis() - connectionStartTime) / 1000
            VpnServiceManager.sendLog("[INFO] Connection duration: ${duration}s")
        }
        
        VpnServiceManager.stopTrafficMonitoring()

        // Stop VPN işlemini arka plan thread'inde çalıştır
        Thread {
            try {
                // BoxService durdur
                boxService?.let { service ->
                    Log.d(TAG, "Closing BoxService")
                    try {
                        if (SingBoxWrapper.isLoaded) {
                            SingBoxWrapper.closeService(service)
                            // Destroy reference
                            try {
                                Seq.destroyRef((service as Object).hashCode())
                            } catch (e: Exception) {
                                Log.w(TAG, "Failed to destroy ref: ${e.message}")
                            }
                            Log.i(TAG, "BoxService closed")
                        } else {
                            Log.w(TAG, "Cannot close service: library not loaded")
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error closing BoxService: ${e.message}", e)
                    }
                }
                
                // Interface kapat
                try {
                    interfaceDescriptor?.close()
                    Log.i(TAG, "VPN interface closed")
                } catch (e: Exception) {
                    Log.e(TAG, "Error closing interface: ${e.message}", e)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping VPN: ${e.message}", e)
                VpnServiceManager.sendLog("[ERROR] ERROR stopping VPN: ${e.message}")
            } finally {
                interfaceDescriptor = null
                boxService = null
                platformInterface = null
                connectionStartTime = 0
                
                // Foreground service durdur
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        ServiceCompat.stopForeground(this@SingBoxVpnService, ServiceCompat.STOP_FOREGROUND_REMOVE)
                    } else {
                        @Suppress("DEPRECATION")
                        stopForeground(true)
                    }
                    stopSelf()
                    Log.i(TAG, "Service stopped")
                } catch (e: Exception) {
                    Log.e(TAG, "Error stopping service: ${e.message}", e)
                }
                
                VpnServiceManager.updateStatus(STATE_DISCONNECTED, "Bağlantı kesildi")
                Log.i(TAG, "=== VPN STOPPED ===")
            }
        }.start()
    }
    
    private fun attemptRetry() {
        if (connectionRetryCount < maxRetryCount && currentConfig != null) {
            Log.i(TAG, "Scheduling retry in 3 seconds...")
            
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                VpnServiceManager.sendLog("[NATIVE] Starting retry...")
                stopVpn()
                startVpn(currentConfig!!)
            }, 3000)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "VPN Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            
            serviceChannel.enableVibration(false)
            serviceChannel.setShowBadge(false)

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(contentText: String): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("YusaBox VPN")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
        
        return builder.build()
    }

    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
            wakeLock = powerManager.newWakeLock(
                android.os.PowerManager.PARTIAL_WAKE_LOCK,
                "yusabox:vpn"
            )
            wakeLock?.acquire(10 * 60 * 1000L)
            Log.i(TAG, "WakeLock acquired")
            VpnServiceManager.sendLog("[NATIVE] WakeLock acquired")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to acquire WakeLock: ${e.message}")
        }
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.release()
            wakeLock = null
            Log.i(TAG, "WakeLock released")
            VpnServiceManager.sendLog("[NATIVE] WakeLock released")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to release WakeLock: ${e.message}")
        }
    }

    private fun resetConnections() {
        // Reset işlemini arka plan thread'inde çalıştır
        Thread {
            try {
                if (boxService != null && SingBoxWrapper.isLoaded && currentConfig != null) {
                    // Close current service
                    SingBoxWrapper.closeService(boxService)
                    
                    // Recreate service
                    platformInterface = PlatformInterfaceImpl(this)
                    boxService = SingBoxWrapper.createService(currentConfig!!, platformInterface!!)
                    
                    if (boxService != null) {
                        SingBoxWrapper.startService(boxService)
                        Log.i(TAG, "Connections reset successfully")
                        VpnServiceManager.sendLog("[NATIVE] Connections reset")
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to reset connections: ${e.message}")
            }
        }.start()
    }

    override fun onDestroy() {
        super.onDestroy()
        
        try {
            val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            connectivityManager.unregisterNetworkCallback(networkCallback)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unregister network callback: ${e.message}")
        }
        
        releaseWakeLock()
        stopVpn()
        VpnServiceManager.service = null
        
        Log.i(TAG, "SingBox VPN Service destroyed")
        VpnServiceManager.sendLog("[NATIVE] Service destroyed")
    }
}
