const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const vm = require('node:vm');

function harness({permission = true} = {}) {
  const events = [], sockets = [], sources = [], timers = new Map();
  let stopped = 0, closed = 0, worklet, timerId = 0;
  const track = {enabled: true, stop() { stopped++; }};
  const node = () => ({connect() {}, disconnect() {}});
  class AudioContext {
    constructor() { this.state = 'running'; this.sampleRate = 48000; this.currentTime = 1; this.destination = {}; this.audioWorklet = {addModule: async () => {}}; }
    async resume() {}
    async close() { this.state = 'closed'; closed++; }
    createMediaStreamSource() { return node(); }
    createGain() { return {...node(), gain: {value: 1}}; }
    createBuffer(_, length, rate) { return {duration: length / rate, getChannelData: () => new Float32Array(length)}; }
    createBufferSource() {
      const source = {...node(), start() {}, stop() { this.stopped = true; }}; sources.push(source); return source;
    }
  }
  class WebSocket {
    static OPEN = 1;
    constructor(url) { this.url=url; this.readyState=1; this.bufferedAmount=0; this.sent=[]; sockets.push(this); }
    send(message) { this.sent.push(JSON.parse(message)); }
    close() { this.readyState=3; }
  }
  const document = {hidden: false, addEventListener() {}, removeEventListener() {}};
  const window = {isSecureContext: true, addEventListener() {}, removeEventListener() {}};
  vm.runInNewContext(readFileSync('web/live_audio.js', 'utf8'), {
    window, document, AudioContext, WebSocket, navigator: {mediaDevices: {getUserMedia: async () => {
      if (!permission) { const error = new Error(); error.name = 'NotAllowedError'; throw error; }
      return {getTracks: () => [track], getAudioTracks: () => [track]};
    }}}, AudioWorkletNode: class {constructor() {worklet = this; this.port={};} connect() {} disconnect() {}},
    setTimeout: (cb, delay) => {timers.set(++timerId,{cb,delay}); return timerId;}, clearTimeout: id => timers.delete(id),
    btoa: value => Buffer.from(value,'binary').toString('base64'), atob: value => Buffer.from(value,'base64').toString('binary'),
  });
  const client = window.fluentLiveCreate(event => events.push(JSON.parse(event)));
  const ticket = {token: 'auth_tokens/fixture', expiresAt: new Date(Date.now()+300000).toISOString(), setup: {model:'models/fixture'}};
  async function connected() {
    await client.prepare();
    const promise = client.connect(JSON.stringify(ticket));
    const socket = sockets[0]; socket.onopen();
    socket.onmessage({data: JSON.stringify({setupComplete:{}})});
    await promise; return socket;
  }
  async function message(value) {
    sockets[0].onmessage({data: JSON.stringify(value)});
    await new Promise(resolve => setImmediate(resolve));
  }
  return {client, events, connected, message, sockets, sources, timers, track, get worklet(){return worklet;},
    get stopped(){return stopped;}, get closed(){return closed;}};
}

test('handshake gates mic until setupComplete and sends little endian PCM', async () => {
  const h=harness(); await h.client.prepare();
  h.worklet.port.onmessage({data:new Float32Array([1,-1])}); assert.equal(h.sockets.length,0);
  const ready=h.client.connect(JSON.stringify({token:'auth_tokens/fixture',expiresAt:new Date(Date.now()+300000).toISOString(),setup:{model:'models/fixture'}}));
  const socket=h.sockets[0]; socket.onopen();
  h.worklet.port.onmessage({data:new Float32Array([1,-1])}); assert.equal(socket.sent.length,1);
  socket.onmessage({data:JSON.stringify({setupComplete:{}})}); await ready;
  h.worklet.port.onmessage({data:new Float32Array([1,-1])});
  const audio=socket.sent.at(-1).realtimeInput.audio;
  assert.equal(audio.mimeType,'audio/pcm;rate=48000');
  assert.equal(Buffer.from(audio.data,'base64').readInt16LE(0),32767);
  assert.equal(Buffer.from(audio.data,'base64').readInt16LE(2),-32768); h.client.close();
});
test('streams audio and transcripts, interruption immediately clears playback',async()=>{
  const h=harness(); await h.connected();
  await h.message({serverContent:{inputTranscription:{text:'Hello'},outputTranscription:{text:'Hi'},modelTurn:{parts:[{inlineData:{mimeType:'audio/pcm;rate=24000',data:'AAAAAA=='}}]}}});
  assert.ok(h.events.some(e=>e.type==='user' && e.text==='Hello')); assert.ok(h.events.some(e=>e.type==='ai' && e.text==='Hi'));
  assert.equal(h.sources.length,1);
  await h.message({serverContent:{interrupted:true}}); assert.equal(h.sources[0].stopped,true); h.client.close();
});
test('mute stops capture and sends audioStreamEnd; unmute restores capture',async()=>{
  const h=harness(), socket=await h.connected(); h.client.mute(true);
  assert.equal(h.track.enabled,false); assert.equal(socket.sent.at(-1).realtimeInput.audioStreamEnd,true);
  const count=socket.sent.length;h.worklet.port.onmessage({data:new Float32Array([1])}); assert.equal(socket.sent.length,count);
  h.client.mute(false); assert.equal(h.track.enabled,true);h.client.close();
});
test('permission denial closes audio context and reports actionable error',async()=>{
  const h=harness({permission:false}); await assert.rejects(h.client.prepare());
  assert.ok(h.events.some(e=>e.type==='error'&&e.text==='permission')); assert.equal(h.closed,1);
});
test('socket timeout rejects pending connection and releases microphone',async()=>{
  const h=harness();await h.client.prepare();
  const connection=h.client.connect(JSON.stringify({token:'auth_tokens/fixture',expiresAt:new Date(Date.now()+300000).toISOString(),setup:{}}));
  const rejected=assert.rejects(connection); [...h.timers.values()].find(t=>t.delay===20000).cb(); await rejected;
  assert.equal(h.stopped,1); assert.equal(h.closed,1);
});
test('backpressure fails closed instead of growing an unbounded audio queue',async()=>{
  const h=harness(), socket=await h.connected();socket.bufferedAmount=300000;
  h.worklet.port.onmessage({data:new Float32Array([1])});
  assert.ok(h.events.some(e=>e.type==='error'&&e.text==='network'));assert.equal(h.stopped,1);
});
