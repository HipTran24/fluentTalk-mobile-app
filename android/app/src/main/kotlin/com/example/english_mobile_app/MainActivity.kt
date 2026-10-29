package com.example.english_mobile_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var liveAudio: LiveAudioBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        liveAudio = LiveAudioBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onRequestPermissionsResult(code: Int, permissions: Array<out String>, grants: IntArray) {
        if (liveAudio?.onPermissionResult(code, grants) == true) return
        super.onRequestPermissionsResult(code, permissions, grants)
    }

    override fun onStop() {
        liveAudio?.close()
        super.onStop()
    }

    override fun onDestroy() {
        liveAudio?.close()
        super.onDestroy()
    }
}
