package nuviapptest.co.impostor

import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var soundPool: SoundPool? = null
    private val sounds = mutableMapOf<String, Int>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        soundPool = SoundPool.Builder().setMaxStreams(3).setAudioAttributes(attributes).build()
        val soundAssets = mapOf(
            "tap" to "flutter_assets/assets/audio/ui/click1.wav",
            "select" to "flutter_assets/assets/audio/ui/click2.wav",
            "confirm" to "flutter_assets/assets/audio/ui/switch15.wav",
            "back" to "flutter_assets/assets/audio/ui/click3.wav",
            "toggle" to "flutter_assets/assets/audio/ui/switch2.wav",
            "reveal" to "flutter_assets/assets/audio/ui/switch6.wav",
            "timerEnd" to "flutter_assets/assets/audio/ui/switch15.wav"
        )
        soundAssets.forEach { (name, path) ->
            assets.openFd(path).use { descriptor ->
                sounds[name] = soundPool!!.load(descriptor, 1)
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "impostor/ui_audio")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        val name = call.argument<String>("sound")
                        val volume = (call.argument<Double>("volume") ?: .35).toFloat()
                        sounds[name]?.let { soundPool?.play(it, volume, volume, 1, 0, 1f) }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}
