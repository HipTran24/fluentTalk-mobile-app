/* Direct Gemini Live audio transport. Only expiring tokens enter this module. */
(() => {
  class FluentLive {
    constructor(callback) {
      this.callback = callback; this.closed = false; this.ready = false;
      this.muted = false; this.sources = new Set(); this.playAt = 0;
      this.visibility = () => { if (document.hidden) this.fail('background'); };
      this.unload = () => this.close();
      document.addEventListener('visibilitychange', this.visibility);
      window.addEventListener('pagehide', this.unload);
    }
    emit(type, text = '') { this.callback(JSON.stringify({type, text})); }
    async prepare() {
      if (!window.isSecureContext || !navigator.mediaDevices?.getUserMedia) {
        this.fail('unsupported'); throw new Error('unsupported');
      }
      try {
        this.context = new AudioContext();
        await this.context.resume();
        if (this.closed) throw new Error('cancelled');
        const stream = await navigator.mediaDevices.getUserMedia({audio: {
          echoCancellation: true, noiseSuppression: true, autoGainControl: true, channelCount: 1
        }});
        if (this.closed) { stream.getTracks().forEach(t => t.stop()); throw new Error('cancelled'); }
        this.stream = stream;
        stream.getAudioTracks()[0].onended = () => { if (!this.closed) this.fail('microphone'); };
        await this.context.audioWorklet.addModule('live-mic-worklet.js');
        if (this.closed) throw new Error('cancelled');
        this.input = this.context.createMediaStreamSource(stream);
        this.worklet = new AudioWorkletNode(this.context, 'fluent-mic');
        this.silent = this.context.createGain(); this.silent.gain.value = 0;
        this.input.connect(this.worklet); this.worklet.connect(this.silent); this.silent.connect(this.context.destination);
        this.worklet.port.onmessage = e => {
          if (!this.ready || this.muted || this.closed || this.socket?.readyState !== WebSocket.OPEN) return;
          if (this.socket.bufferedAmount > 262144) return this.fail('network');
          const samples = e.data, bytes = new Uint8Array(samples.length * 2), view = new DataView(bytes.buffer);
          for (let i = 0; i < samples.length; i++) {
            const v = Math.max(-1, Math.min(1, samples[i]));
            view.setInt16(i * 2, v < 0 ? v * 32768 : v * 32767, true);
          }
          let binary = ''; for (const byte of bytes) binary += String.fromCharCode(byte);
          this.send({realtimeInput: {audio: {mimeType: `audio/pcm;rate=${this.context.sampleRate}`, data: btoa(binary)}}});
        };
        return null;
      } catch (e) {
        if (!this.closed) this.fail(e.name === 'NotAllowedError' ? 'permission' : 'microphone');
        throw new Error('microphone');
      }
    }
    async connect(ticketJson) {
      if (this.closed || !this.stream) throw new Error('cancelled');
      const ticket = JSON.parse(ticketJson);
      if (!ticket.token?.startsWith('auth_tokens/')) throw new Error('invalid-token');
      const ttl = Date.parse(ticket.expiresAt) - Date.now();
      if (!(ttl > 0)) throw new Error('expired');
      this.expiry = setTimeout(() => this.fail('expired'), Math.min(ttl, 300000));
      return new Promise((resolve, reject) => {
        this.rejectConnect = reject;
        this.handshake = setTimeout(() => this.fail('timeout'), 20000);
        this.socket = new WebSocket('wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContentConstrained?access_token=' + encodeURIComponent(ticket.token));
        this.socket.onopen = () => this.send({setup: ticket.setup});
        // Preserve event order even when frames are Blob payloads.
        let messages = Promise.resolve();
        this.socket.onmessage = e => {
          messages = messages.then(async () => {
            if (this.closed) return;
            const message = JSON.parse(typeof e.data === 'string' ? e.data : await e.data.text());
            if (message.setupComplete) {
              clearTimeout(this.handshake); this.rejectConnect = null; this.ready = true;
              this.emit('ready'); resolve(null);
              this.send({realtimeInput: {text: 'Please greet me briefly and ask one easy question to start our English practice.'}});
            }
            if (message.error) return this.fail('provider');
            if (message.goAway) return this.fail('expired');
            const content = message.serverContent;
            if (!content) return;
            if (content.interrupted) { this.stopPlayback(); this.emit('listening'); }
            if (content.inputTranscription?.text) this.emit('user', content.inputTranscription.text);
            if (content.outputTranscription?.text) this.emit('ai', content.outputTranscription.text);
            for (const part of content.modelTurn?.parts ?? []) {
              if (part.inlineData?.data && part.inlineData.mimeType?.startsWith('audio/pcm')) this.play(part.inlineData);
            }
            if (content.turnComplete && this.sources.size === 0) this.emit('listening');
          }).catch(() => { if (!this.closed) this.fail('provider'); });
        };
        this.socket.onerror = () => this.fail('network');
        this.socket.onclose = e => {
          if (!this.closed) this.fail(e.code === 1008 ? 'access' : 'disconnected');
        };
      });
    }
    send(message) { if (!this.closed && this.socket?.readyState === WebSocket.OPEN) this.socket.send(JSON.stringify(message)); }
    play(part) {
      const raw = atob(part.data), bytes = Uint8Array.from(raw, c => c.charCodeAt(0));
      const view = new DataView(bytes.buffer);
      const rate = Number(/rate=(\d+)/.exec(part.mimeType)?.[1] ?? 24000);
      if (bytes.length % 2 || rate < 8000 || rate > 96000) throw new Error('invalid-audio');
      if (this.playAt - this.context.currentTime > 8) return this.fail('network');
      const buffer = this.context.createBuffer(1, bytes.length / 2, rate), output = buffer.getChannelData(0);
      for (let i = 0; i < output.length; i++) output[i] = view.getInt16(i * 2, true) / 32768;
      const source = this.context.createBufferSource(); source.buffer = buffer; source.connect(this.context.destination);
      this.playAt = Math.max(this.context.currentTime + 0.025, this.playAt);
      this.sources.add(source);
      source.onended = () => {
        this.sources.delete(source); source.disconnect();
        if (!this.closed && this.sources.size === 0) this.emit('listening');
      };
      source.start(this.playAt); this.playAt += buffer.duration;
      this.emit('speaking');
    }
    stopPlayback() {
      for (const source of this.sources) { source.onended = null; try { source.stop(); source.disconnect(); } catch (_) {} }
      this.sources.clear(); this.playAt = 0;
    }
    mute(value) {
      this.muted = value;
      if (this.stream) this.stream.getAudioTracks().forEach(t => { t.enabled = !value; });
      if (value) this.send({realtimeInput: {audioStreamEnd: true}});
    }
    fail(reason) { if (!this.closed) { this.emit('error', reason); this.close(); } }
    close() {
      if (this.closed) return;
      this.closed = true; this.ready = false;
      clearTimeout(this.expiry); clearTimeout(this.handshake);
      document.removeEventListener('visibilitychange', this.visibility);
      window.removeEventListener('pagehide', this.unload);
      if (this.rejectConnect) { this.rejectConnect(new Error('closed')); this.rejectConnect = null; }
      if (this.socket) { this.socket.onclose = null; this.socket.onerror = null; this.socket.close(); }
      this.stopPlayback();
      this.stream?.getTracks().forEach(t => t.stop());
      this.input?.disconnect(); this.worklet?.disconnect(); this.silent?.disconnect();
      if (this.context && this.context.state !== 'closed') this.context.close().catch(() => {});
    }
  }
  window.fluentLiveCreate = callback => new FluentLive(callback);
})();
