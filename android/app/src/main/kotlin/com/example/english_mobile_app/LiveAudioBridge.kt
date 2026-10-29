package com.example.english_mobile_app

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.media.*
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.NoiseSuppressor
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.atomic.AtomicInteger

/** Android PCM bridge: 16 kHz mic / 24 kHz speaker, no files or TTS fallback. */
class LiveAudioBridge(private val activity: Activity, messenger: BinaryMessenger) {
    companion object { const val REQUEST_MIC = 7412 }
    private val main = Handler(Looper.getMainLooper())
    private val methods = MethodChannel(messenger, "fluenttalk/live_audio")
    private val events = EventChannel(messenger, "fluenttalk/live_audio/events")
    private var sink: EventChannel.EventSink? = null
    private var pending: Pair<Int, MethodChannel.Result>? = null
    private var engine: Engine? = null

    init {
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, eventSink: EventChannel.EventSink) { sink = eventSink }
            override fun onCancel(args: Any?) { sink = null; close() }
        })
        methods.setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<Int>("session") ?: return result.error("session", "Missing session", null)
        try {
            if (call.method == "prepare") {
                if (pending != null) return result.error("microphone", "Permission request in progress", null)
                engine?.close(); engine = null
                if (Build.VERSION.SDK_INT >= 23 &&
                    activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                    pending = id to result
                    activity.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), REQUEST_MIC)
                } else { prepare(id, result) }
                return
            }
            if (call.method == "close") {
                if (pending?.first == id) {
                    pending?.second?.error("cancelled", "Call cancelled", null); pending = null
                }
                if (engine?.id == id) { engine?.close(); engine = null }
                result.success(null)
                return
            }
            val audio = engine
            if (audio == null || audio.id != id) {
                result.error("cancelled", "Call is no longer active", null)
                return
            }
            when (call.method) {
                "start" -> audio.start()
                "play" -> audio.play(call.argument<ByteArray>("pcm") ?: byteArrayOf())
                "stopPlayback" -> audio.stopPlayback()
                "mute" -> audio.muted = call.argument<Boolean>("muted") == true
                else -> { result.notImplemented(); return }
            }
            result.success(null)
        } catch (_: SecurityException) { result.error("permission", "Microphone permission required", null) }
        catch (_: Exception) { result.error("microphone", "Audio device unavailable", null) }
    }

    private fun prepare(id: Int, result: MethodChannel.Result) {
        try {
            engine = Engine(id)
            result.success(null)
        } catch (_: Exception) {
            engine?.close(); engine = null
            result.error("microphone", "Audio device unavailable", null)
        }
    }

    fun onPermissionResult(code: Int, grants: IntArray): Boolean {
        if (code != REQUEST_MIC) return false
        val request = pending ?: return true
        pending = null
        if (grants.isNotEmpty() && grants[0] == PackageManager.PERMISSION_GRANTED) prepare(request.first, request.second)
        else request.second.error("permission", "Microphone permission required", null)
        return true
    }

    fun close() {
        pending?.second?.error("cancelled", "Call cancelled", null); pending = null
        engine?.close(); engine = null
    }

    private inner class Engine(val id: Int) {
        private val manager = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        private val oldMode = manager.mode
        private val oldDevice = if (Build.VERSION.SDK_INT >= 31) manager.communicationDevice else null
        @Suppress("DEPRECATION") private val oldSpeaker = manager.isSpeakerphoneOn
        private var record: AudioRecord? = null
        private var track: AudioTrack? = null
        private var aec: AcousticEchoCanceler? = null
        private var ns: NoiseSuppressor? = null
        private var focus: AudioFocusRequest? = null
        private var recording: Thread? = null
        private var playback: Thread? = null
        @Volatile private var closed = false
        @Volatile private var started = false
        @Volatile var muted = false
        private val lock = Any()
        private val queue = LinkedBlockingQueue<Pair<Int, ByteArray>>(200)
        private val epoch = AtomicInteger()
        private val queuedBytes = AtomicInteger()
        private var writtenFrames = 0L
        private var hadAudio = false

        private fun emit(type: String, extra: Map<String, Any> = emptyMap()) {
            main.post { if (!closed && engine === this) sink?.success(mapOf("session" to id, "type" to type) + extra) }
        }

        fun start() {
            if (closed || started) return
            try {
                val attrs = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build()
                if (Build.VERSION.SDK_INT >= 26) {
                    focus = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                        .setAudioAttributes(attrs).setOnAudioFocusChangeListener({ change ->
                            if (change < 0 && !closed) emit("error", mapOf("reason" to "audio-focus"))
                        }, main).build()
                    check(manager.requestAudioFocus(focus!!) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
                }
                manager.mode = AudioManager.MODE_IN_COMMUNICATION
                if (Build.VERSION.SDK_INT >= 31) {
                    val devices = manager.availableCommunicationDevices
                    val preferred = devices.firstOrNull { it.type in setOf(
                        AudioDeviceInfo.TYPE_WIRED_HEADSET, AudioDeviceInfo.TYPE_USB_HEADSET,
                        AudioDeviceInfo.TYPE_BLUETOOTH_SCO, AudioDeviceInfo.TYPE_BLE_HEADSET) }
                        ?: devices.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
                    if (preferred != null) manager.setCommunicationDevice(preferred)
                } else { @Suppress("DEPRECATION") manager.isSpeakerphoneOn = true }
                val minIn = AudioRecord.getMinBufferSize(16000, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
                check(minIn > 0)
                val mic = AudioRecord(MediaRecorder.AudioSource.VOICE_COMMUNICATION, 16000,
                    AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, maxOf(minIn, 6400))
                record = mic
                check(mic.state == AudioRecord.STATE_INITIALIZED)
                if (AcousticEchoCanceler.isAvailable()) aec = AcousticEchoCanceler.create(mic.audioSessionId)?.also { it.enabled = true }
                if (NoiseSuppressor.isAvailable()) ns = NoiseSuppressor.create(mic.audioSessionId)?.also { it.enabled = true }
                val minOut = AudioTrack.getMinBufferSize(24000, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)
                check(minOut > 0)
                track = AudioTrack.Builder().setAudioAttributes(attrs)
                    .setAudioFormat(AudioFormat.Builder().setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(24000).setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
                    .setBufferSizeInBytes(maxOf(minOut, 9600)).setTransferMode(AudioTrack.MODE_STREAM).build()
                check(track!!.state == AudioTrack.STATE_INITIALIZED)
                track!!.play()
                mic.startRecording()
                check(mic.recordingState == AudioRecord.RECORDSTATE_RECORDING)
                started = true
                recording = Thread({
                    android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_AUDIO)
                    val buffer = ByteArray(1280) // 40 ms, bounded channel traffic.
                    try {
                        while (!closed) {
                            val count = mic.read(buffer, 0, buffer.size)
                            if (count < 0) throw IllegalStateException("Microphone read failed")
                            if (count > 0 && !muted) emit("pcm", mapOf("pcm" to buffer.copyOf(count)))
                        }
                    } catch (_: Exception) { if (!closed) emit("error", mapOf("reason" to "microphone")) }
                }, "FluentTalk-mic").also { it.start() }
                playback = Thread({ pumpPlayback() }, "FluentTalk-speaker").also { it.start() }
            } catch (error: Exception) { close(); throw error }
        }

        fun play(bytes: ByteArray) {
            if (closed || !started || bytes.isEmpty()) return
            check(bytes.size % 2 == 0 && bytes.size <= 384000)
            synchronized(lock) {
                check(queuedBytes.get() + bytes.size <= 384000) // At most 8 seconds; never grow forever.
                queuedBytes.addAndGet(bytes.size)
                check(queue.offer(epoch.get() to bytes))
            }
        }

        private fun pumpPlayback() {
            android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_AUDIO)
            try {
                while (!closed) {
                    val packet = queue.poll(15, java.util.concurrent.TimeUnit.MILLISECONDS)
                    if (packet != null) {
                        var offset = 0
                        while (!closed && offset < packet.second.size && packet.first == epoch.get()) {
                            val count = synchronized(lock) {
                                if (packet.first != epoch.get()) 0 else {
                                    val n = track!!.write(packet.second, offset, packet.second.size - offset, AudioTrack.WRITE_NON_BLOCKING)
                                    check(n >= 0)
                                    writtenFrames += n / 2
                                    if (n > 0) hadAudio = true
                                    n
                                }
                            }
                            offset += count
                            if (count == 0) Thread.sleep(5)
                        }
                        synchronized(lock) { if (packet.first == epoch.get()) queuedBytes.addAndGet(-packet.second.size) }
                    }
                    synchronized(lock) {
                        val head = track?.playbackHeadPosition?.toLong()?.and(0xffffffffL) ?: 0
                        if (hadAudio && queue.isEmpty() && head >= writtenFrames) {
                            hadAudio = false
                            emit("drained")
                        }
                    }
                }
            } catch (_: InterruptedException) { /* call ended */ }
            catch (_: Exception) { if (!closed) emit("error", mapOf("reason" to "playback")) }
        }

        fun stopPlayback() {
            synchronized(lock) {
                epoch.incrementAndGet(); queue.clear(); queuedBytes.set(0)
                track?.pause(); track?.flush(); writtenFrames = 0; hadAudio = false
                if (!closed && started) track?.play()
            }
        }

        fun close() {
            if (closed) return
            closed = true
            try { record?.stop() } catch (_: Exception) {}
            recording?.join(200)
            playback?.interrupt(); playback?.join(200)
            synchronized(lock) {
                queue.clear(); queuedBytes.set(0)
                try { track?.pause(); track?.flush(); track?.release() } catch (_: Exception) {}
                track = null
            }
            aec?.release(); ns?.release(); record?.release(); record = null
            if (Build.VERSION.SDK_INT >= 31) {
                if (oldDevice != null) manager.setCommunicationDevice(oldDevice)
                else manager.clearCommunicationDevice()
            }
            else { @Suppress("DEPRECATION") manager.isSpeakerphoneOn = oldSpeaker }
            manager.mode = oldMode
            if (Build.VERSION.SDK_INT >= 26) focus?.let { manager.abandonAudioFocusRequest(it) }
        }
    }
}
