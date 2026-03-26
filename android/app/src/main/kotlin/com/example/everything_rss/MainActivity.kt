package com.example.everything_rss

import android.content.res.Configuration
import androidx.annotation.NonNull
import io.flutter.embedding.engine.FlutterEngine
import com.ryanheise.audioservice.AudioServiceActivity
import cl.puntito.simple_pip_mode.PipCallbackHelper

class MainActivity: AudioServiceActivity() {
    private var callbackHelper = PipCallbackHelper()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        callbackHelper.configureFlutterEngine(flutterEngine)
    }

    override fun onPictureInPictureModeChanged(active: Boolean, newConfig: Configuration?) {
        super.onPictureInPictureModeChanged(active, newConfig)
        callbackHelper.onPictureInPictureModeChanged(active)
    }
}
