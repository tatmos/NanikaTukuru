/**
 * Web Audio graph for NanikaTukuru 音響ラボ
 *
 * osc + noise -> filter -> (dry + delay wet) -> master -> analyser -> destination
 */

export class AudioLab {
  constructor() {
    /** @type {AudioContext | null} */
    this.ctx = null;
    this.playing = false;

    /** @type {OscillatorNode | null} */
    this.osc = null;
    /** @type {AudioBufferSourceNode | null} */
    this.noise = null;

    this.oscGain = null;
    this.noiseGain = null;
    this.filter = null;
    this.delay = null;
    this.delayFeedback = null;
    this.delayWet = null;
    this.dryGain = null;
    this.master = null;
    this.analyser = null;

    this.params = {
      wave: "sawtooth",
      freq: 440,
      oscGain: 0.35,
      noiseGain: 0.08,
      filterType: "lowpass",
      cutoff: 2400,
      q: 0.9,
      delayTime: 0.22,
      delayFb: 0.28,
      delayWet: 0.35,
      master: 0.55,
    };
  }

  async ensureContext() {
    if (!this.ctx) {
      this.ctx = new AudioContext();
      this.#buildGraph();
    }
    if (this.ctx.state === "suspended") {
      await this.ctx.resume();
    }
    return this.ctx;
  }

  #buildGraph() {
    const ctx = this.ctx;
    this.oscGain = ctx.createGain();
    this.noiseGain = ctx.createGain();
    this.filter = ctx.createBiquadFilter();
    this.delay = ctx.createDelay(1.5);
    this.delayFeedback = ctx.createGain();
    this.delayWet = ctx.createGain();
    this.dryGain = ctx.createGain();
    this.master = ctx.createGain();
    this.analyser = ctx.createAnalyser();

    this.analyser.fftSize = 2048;
    this.analyser.smoothingTimeConstant = 0.8;

    this.oscGain.connect(this.filter);
    this.noiseGain.connect(this.filter);

    this.filter.connect(this.dryGain);
    this.filter.connect(this.delay);
    this.delay.connect(this.delayFeedback);
    this.delayFeedback.connect(this.delay);
    this.delay.connect(this.delayWet);

    this.dryGain.connect(this.master);
    this.delayWet.connect(this.master);
    this.master.connect(this.analyser);
    this.analyser.connect(ctx.destination);

    this.#applyParams();
  }

  #makeNoiseBuffer() {
    const seconds = 2;
    const sampleRate = this.ctx.sampleRate;
    const buffer = this.ctx.createBuffer(1, sampleRate * seconds, sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < data.length; i++) {
      data[i] = Math.random() * 2 - 1;
    }
    return buffer;
  }

  #applyParams() {
    const p = this.params;
    const now = this.ctx.currentTime;

    this.filter.type = p.filterType;
    this.filter.frequency.setTargetAtTime(p.cutoff, now, 0.03);
    this.filter.Q.setTargetAtTime(p.q, now, 0.03);

    this.oscGain.gain.setTargetAtTime(p.oscGain, now, 0.03);
    this.noiseGain.gain.setTargetAtTime(p.noiseGain, now, 0.03);

    this.delay.delayTime.setTargetAtTime(p.delayTime, now, 0.03);
    this.delayFeedback.gain.setTargetAtTime(p.delayFb, now, 0.03);
    this.delayWet.gain.setTargetAtTime(p.delayWet, now, 0.03);
    this.dryGain.gain.setTargetAtTime(1 - p.delayWet * 0.5, now, 0.03);
    this.master.gain.setTargetAtTime(p.master, now, 0.03);

    if (this.osc) {
      this.osc.type = p.wave;
      this.osc.frequency.setTargetAtTime(p.freq, now, 0.02);
    }
  }

  setParam(key, value) {
    this.params[key] = value;
    if (this.ctx) {
      this.#applyParams();
    }
  }

  async start() {
    await this.ensureContext();
    if (this.playing) return;

    this.osc = this.ctx.createOscillator();
    this.osc.type = this.params.wave;
    this.osc.frequency.value = this.params.freq;
    this.osc.connect(this.oscGain);
    this.osc.start();

    this.noise = this.ctx.createBufferSource();
    this.noise.buffer = this.#makeNoiseBuffer();
    this.noise.loop = true;
    this.noise.connect(this.noiseGain);
    this.noise.start();

    this.#applyParams();
    this.playing = true;
  }

  stop() {
    if (!this.playing) return;

    try {
      this.osc?.stop();
      this.noise?.stop();
    } catch {
      /* already stopped */
    }
    this.osc?.disconnect();
    this.noise?.disconnect();
    this.osc = null;
    this.noise = null;
    this.playing = false;
  }
}
