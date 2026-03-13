package com.tecclub.flutter_singbox.bg

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.tecclub.flutter_singbox.R
import com.tecclub.flutter_singbox.constant.Action
import com.tecclub.flutter_singbox.config.SimpleConfigManager
import com.tecclub.flutter_singbox.constant.Status
import androidx.lifecycle.MutableLiveData

class ServiceNotification(
    private val statusLiveData: MutableLiveData<Status>,
    private val service: Service
) {
    companion object {
        private const val CHANNEL_ID = "tecclub_singbox_channel_v2"
        private const val NOTIFICATION_ID = 1
    }

    private lateinit var notificationBuilder: NotificationCompat.Builder

    private val notificationTitle: String
        get() = SimpleConfigManager.getNotificationTitle()

    private val notificationDescription: String
        get() = SimpleConfigManager.getNotificationDescription()

    init {
        try {
            android.util.Log.e("ServiceNotification", "Initializing notification")
            createNotificationChannel()

            // Нажатие на уведомление — открыть приложение
            val openAppIntent = service.packageManager
                .getLaunchIntentForPackage(service.packageName)
                ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP }
            val openPendingIntent = if (openAppIntent != null) {
                PendingIntent.getActivity(
                    service, 0, openAppIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            } else null

            // Кнопка "Отключить" — используем стандартный ACTION для остановки сервиса
            val stopIntent = Intent(Action.SERVICE_CLOSE)
                .setPackage(service.packageName)
            val stopPendingIntent = PendingIntent.getBroadcast(
                service, 1, stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            android.util.Log.e("ServiceNotification", "Creating notification builder with title: $notificationTitle")
            notificationBuilder = NotificationCompat.Builder(service, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_vpn_key)
                .setContentTitle(notificationTitle)
                .setContentText(notificationDescription)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .setOngoing(true)
                .addAction(android.R.drawable.ic_delete, "Отключить", stopPendingIntent)

            if (openPendingIntent != null) {
                notificationBuilder.setContentIntent(openPendingIntent)
            }

            android.util.Log.e("ServiceNotification", "Notification builder created successfully")
        } catch (e: Exception) {
            android.util.Log.e("ServiceNotification", "Error initializing notification: ${e.message}", e)
            notificationBuilder = NotificationCompat.Builder(service, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_vpn_key)
                .setContentTitle(notificationTitle)
                .setContentText(notificationDescription)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                notificationTitle,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "$notificationTitle service notification"
                setShowBadge(false)
            }
            val notificationManager = service.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun show(profileName: String, details: String) {
        val title = notificationTitle
        val desc = if (details.isNotEmpty()) details else notificationDescription

        val notification = notificationBuilder
            .setContentTitle(title)
            .setContentText(desc)
            .build()

        service.startForeground(NOTIFICATION_ID, notification)
    }

    fun start() {
        statusLiveData.postValue(Status.Started)
    }

    fun stop() {
        statusLiveData.postValue(Status.Stopped)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            service.stopForeground(Service.STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            service.stopForeground(true)
        }
    }
}