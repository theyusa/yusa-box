package com.yusabox.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat

class SingBoxVpnService : VpnService() {

    private var interfaceDescriptor: ParcelFileDescriptor? = null
    private var boxService: Long? = null

    companion object {
        const val ACTION_START = "com.yusabox.vpn.START"
        const val ACTION_STOP = "com.yusabox.vpn.STOP"
        const val EXTRA_CONFIG = "config"
        const val CHANNEL_ID = "vpn_channel"
    }

    init {
        System.loadLibrary("box")
    }

    external fun setup(assetPath: String, tempPath: String, disableMemoryLimit: Boolean)
    external fun newService(config: String, fd: Long): Long
    external fun startService(ptr: Long)
    external fun closeService(ptr: Long)

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        VpnServiceManager.service = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val config = intent.getStringExtra(EXTRA_CONFIG)
                if (config != null) {
                    startVpn(config)
                }
            }
            ACTION_STOP -> {
                stopVpn()
            }
        }
        return START_NOT_STICKY
    }

    private fun startVpn(config: String) {
        VpnServiceManager.updateStatus(1, "Bağlanıyor...")

        startForeground(1, createNotification())

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
                startService(boxService!!)

                VpnServiceManager.updateStatus(2, "Bağlandı")
                VpnServiceManager.startTrafficMonitoring()
            } else {
                VpnServiceManager.updateStatus(4, "VPN interface oluşturulamadı")
            }
        } catch (e: Exception) {
            e.printStackTrace()
            VpnServiceManager.updateStatus(4, "Hata: ${e.message}")
            stopVpn()
        }
    }

    private fun stopVpn() {
        VpnServiceManager.updateStatus(3, "Bağlantı kesiliyor...")
        VpnServiceManager.stopTrafficMonitoring()

        try {
            boxService?.let { closeService(it) }
            interfaceDescriptor?.close()
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            interfaceDescriptor = null
            boxService = null
            stopForeground(true)
            stopSelf()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "VPN Service Channel",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("YusaBox VPN")
            .setContentText("VPN servisi çalışıyor...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .build()
    }

    override fun onDestroy() {
        stopVpn()
        VpnServiceManager.service = null
        super.onDestroy()
    }
}
