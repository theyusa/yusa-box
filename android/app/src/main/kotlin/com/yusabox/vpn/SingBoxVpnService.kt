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
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat

class SingBoxVpnService : VpnService() {

    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            super.onAvailable(network)
            Log.i(TAG, "Network available: $network")
            VpnServiceManager.sendLog("[NATIVE] Network available")
        }

        override fun onLost(network: Network) {
            super.onLost(network)
            Log.i(TAG, "Network lost: $network")
            VpnServiceManager.sendLog("[NATIVE] Network lost")
            
            if (VpnServiceManager.isConnected()) {
                Log.i(TAG, "Will attempt reconnect on network restore")
            }
        }
    }

    private var interfaceDescriptor: ParcelFileDescriptor? = null
    private var boxService: Long? = null
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

    init {
        System.loadLibrary("box")
    }

    external fun setup(assetPath: String, tempPath: String, disableMemoryLimit: Boolean)
    external fun newService(config: String, fd: Long): Long
    external fun startService(ptr: Long)
    external fun closeService(ptr: Long)
    override fun protect(socket: Int): Boolean
    external fun getTrafficStats(): Array<Long>

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        VpnServiceManager.service = this
        
        registerNetworkCallback()
        
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
        VpnServiceManager.updateStatus(STATE_CONNECTING, "Bağlanıyor...")
        
        val serverName = currentServerName ?: "Bilinmeyen"
        VpnServiceManager.updateConnectionInfo(serverName)
        
        startForeground(NOTIFICATION_ID, createNotification("Bağlanıyor..."))

        try {
            val builder = Builder()
            builder.setSession("YusaBox VPN")
            builder.addAddress("10.0.0.2", 32)
            builder.addRoute("0.0.0.0", 0)
            builder.setMtu(1500)

            interfaceDescriptor = builder.establish()

            if (interfaceDescriptor != null) {
                setup(filesDir.absolutePath, filesDir.absolutePath, false)
                boxService = newService(config, interfaceDescriptor!!.fd.toLong())
                
                protectSocketConnections()
                startService(boxService!!)
                
                connectionStartTime = System.currentTimeMillis()
                VpnServiceManager.updateStatus(STATE_CONNECTED, "Bağlandı")
                VpnServiceManager.sendLog("[NATIVE] Connected to: $serverName")
                
                VpnServiceManager.startTrafficMonitoring()
            } else {
                Log.e(TAG, "Failed to establish VPN interface")
                VpnServiceManager.updateStatus(STATE_ERROR, "VPN interface oluşturulamadı")
                VpnServiceManager.sendLog("[NATIVE] ERROR: Cannot establish VPN interface")
                attemptRetry()
            }
        } catch (e: Exception) {
            Log.e(TAG, "VPN connection error", e)
            VpnServiceManager.updateStatus(STATE_ERROR, "Hata: ${e.message}")
            VpnServiceManager.sendLog("[NATIVE] ERROR: ${e.message}")
            attemptRetry()
        }
    }
    
    private fun protectSocketConnections() {
        try {
            val result = protect(0)
            Log.i(TAG, "Socket protection enabled: $result")
            VpnServiceManager.sendLog("[NATIVE] Socket protection: $result")
        } catch (e: Exception) {
            Log.w(TAG, "Socket protection failed: ${e.message}")
        }
    }

    private fun stopVpn() {
        VpnServiceManager.updateStatus(3, "Bağlantı kesiliyor...")
        VpnServiceManager.sendLog("[NATIVE] Disconnecting...")
        
        if (connectionStartTime > 0) {
            val duration = (System.currentTimeMillis() - connectionStartTime) / 1000
            VpnServiceManager.sendLog("[NATIVE] Connection duration: ${duration}s")
        }
        
        VpnServiceManager.stopTrafficMonitoring()

        try {
            boxService?.let { closeService(it) }
            interfaceDescriptor?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping VPN", e)
            VpnServiceManager.sendLog("[NATIVE] ERROR stopping VPN: ${e.message}")
        } finally {
            interfaceDescriptor = null
            boxService = null
            connectionStartTime = 0
            
            stopForeground(true)
            stopSelf()
            
            VpnServiceManager.updateStatus(STATE_DISCONNECTED, "Bağlantı kesildi")
        }
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

    override fun onDestroy() {
        super.onDestroy()
        
        try {
            val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            connectivityManager.unregisterNetworkCallback(networkCallback)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unregister network callback: ${e.message}")
        }
        
        stopVpn()
        VpnServiceManager.service = null
        
        Log.i(TAG, "SingBox VPN Service destroyed")
        VpnServiceManager.sendLog("[NATIVE] Service destroyed")
    }
}
