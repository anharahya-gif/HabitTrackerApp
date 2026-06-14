package com.anhar.dailio

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import android.net.Uri
import android.media.Ringtone
import android.media.RingtoneManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var currentRingtone: Ringtone? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Memastikan layar HP menyala dan bypass lockscreen ketika alarm memicu full-screen intent
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.anhar.dailio/alarm").setMethodCallHandler { call, result ->
            when (call.method) {
                "getAlarmUri" -> {
                    try {
                        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM).toString()
                        result.success(uri)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getAlarmSounds" -> {
                    try {
                        val manager = RingtoneManager(this)
                        manager.setType(RingtoneManager.TYPE_ALARM)
                        val cursor = manager.cursor
                        val list = mutableListOf<Map<String, String>>()
                        while (cursor.moveToNext()) {
                            val title = cursor.getString(RingtoneManager.TITLE_COLUMN_INDEX)
                            val uri = manager.getRingtoneUri(cursor.position).toString()
                            list.add(mapOf("title" to title, "uri" to uri))
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "playAlarmSound" -> {
                    val uriStr = call.argument<String>("uri")
                    if (uriStr != null) {
                        try {
                            currentRingtone?.stop()
                            val uri = Uri.parse(uriStr)
                            currentRingtone = RingtoneManager.getRingtone(applicationContext, uri)
                            currentRingtone?.play()
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    } else {
                        result.error("BAD_ARGS", "Missing sound URI", null)
                    }
                }
                "stopAlarmSound" -> {
                    try {
                        currentRingtone?.stop()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        currentRingtone?.stop()
        super.onDestroy()
    }
}
