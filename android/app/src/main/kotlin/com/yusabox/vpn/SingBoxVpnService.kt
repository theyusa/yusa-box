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
import io.nekohasekai.libbox.BoxService
import io.nekohasekai.libbox.Libbox

class SingBoxVpnService : VpnService() {

    private var interfaceDescriptor: ParcelFileDescriptor? = null
    private var boxService: BoxService? = null

    companion object {
        const val ACTION_START = "com.yusabox.vpn.START"
        const val ACTION_STOP = "com.yusabox.vpn.STOP"
        const val EXTRA_CONFIG = "config"
        const val CHANNEL_ID = "vpn_channel"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
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
        // Start Foreground Service
        startForeground(1, createNotification())

        try {
            // Establish VPN Interface
            val builder = Builder()
            builder.setSession("YusaBox VPN")
            builder.addAddress("10.0.0.2", 32)
            builder.addRoute("0.0.0.0", 0)
            builder.setMtu(1500)
            
            interfaceDescriptor = builder.establish()

            if (interfaceDescriptor != null) {
                // Initialize Libbox
                // Note: The actual initialization depends on the Libbox API.
                // Assuming standard usage:
                Libbox.setup(filesDir.absolutePath, filesDir.absolutePath, false)
                boxService = Libbox.newService(config, interfaceDescriptor!!.fd.toLong())
                boxService?.start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            stopVpn()
        }
    }

    private fun stopVpn() {
        try {
            boxService?.close()
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
            //.setSmallIcon(R.drawable.ic_notification) // Ensure this icon exists or use standard
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .build()
    }

    override fun onDestroy() {
        stopVpn()
        super.onDestroy()
    }
}
