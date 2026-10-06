package com.example.mantra_jaap_tracker

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private var volumeSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "mantra_jaap/volume_keys")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    volumeSink = events
                }

                override fun onCancel(arguments: Any?) {
                    volumeSink = null
                }
            })
    }

    // Activity.dispatchKeyEvent runs before the Flutter view sees the key.
    // While the counter screen listens, volume keys are consumed (the volume
    // does not change) and each press is sent to Dart once; holding a key
    // does not auto-repeat, so a long press can't run the count away.
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val sink = volumeSink ?: return super.dispatchKeyEvent(event)
        val direction = when (event.keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP -> "up"
            KeyEvent.KEYCODE_VOLUME_DOWN -> "down"
            else -> return super.dispatchKeyEvent(event)
        }
        if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
            sink.success(direction)
        }
        return true
    }
}