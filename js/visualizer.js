/**
 * Waveform + spectrum canvas renderer
 */

export class Visualizer {
  /**
   * @param {HTMLCanvasElement} canvas
   * @param {() => AnalyserNode | null} getAnalyser
   * @param {() => boolean} isPlaying
   */
  constructor(canvas, getAnalyser, isPlaying) {
    this.canvas = canvas;
    this.getAnalyser = getAnalyser;
    this.isPlaying = isPlaying;
    this.ctx2d = canvas.getContext("2d");
    this.raf = 0;
    this.timeData = null;
    this.freqData = null;

    this.colors = {
      bgTop: "#101814",
      bgBot: "#1a2a24",
      wave: "#5eead4",
      spectrum: "rgba(217, 119, 6, 0.85)",
      grid: "rgba(248, 252, 249, 0.08)",
      idle: "rgba(94, 234, 212, 0.25)",
    };
  }

  start() {
    const loop = () => {
      this.draw();
      this.raf = requestAnimationFrame(loop);
    };
    this.raf = requestAnimationFrame(loop);
  }

  stop() {
    cancelAnimationFrame(this.raf);
  }

  draw() {
    const { canvas, ctx2d } = this;
    const w = canvas.width;
    const h = canvas.height;
    const analyser = this.getAnalyser();

    const g = ctx2d.createLinearGradient(0, 0, 0, h);
    g.addColorStop(0, this.colors.bgTop);
    g.addColorStop(1, this.colors.bgBot);
    ctx2d.fillStyle = g;
    ctx2d.fillRect(0, 0, w, h);

    ctx2d.strokeStyle = this.colors.grid;
    ctx2d.lineWidth = 1;
    for (let x = 0; x < w; x += 60) {
      ctx2d.beginPath();
      ctx2d.moveTo(x, 0);
      ctx2d.lineTo(x, h);
      ctx2d.stroke();
    }
    for (let y = 0; y < h; y += 40) {
      ctx2d.beginPath();
      ctx2d.moveTo(0, y);
      ctx2d.lineTo(w, y);
      ctx2d.stroke();
    }

    if (!analyser || !this.isPlaying()) {
      this.#drawIdleWave(w, h);
      return;
    }

    if (!this.timeData || this.timeData.length !== analyser.fftSize) {
      this.timeData = new Uint8Array(analyser.fftSize);
      this.freqData = new Uint8Array(analyser.frequencyBinCount);
    }

    analyser.getByteTimeDomainData(this.timeData);
    analyser.getByteFrequencyData(this.freqData);

    this.#drawSpectrum(w, h);
    this.#drawWave(w, h);
  }

  #drawIdleWave(w, h) {
    const t = performance.now() / 1000;
    ctxStrokeWave(this.ctx2d, w, h, this.colors.idle, (x) => {
      const n = x / w;
      return Math.sin(n * Math.PI * 4 + t) * 0.12 + Math.sin(n * Math.PI * 9 - t * 1.3) * 0.05;
    });
  }

  #drawSpectrum(w, h) {
    const data = this.freqData;
    const bars = Math.min(96, data.length);
    const barW = w / bars;
    const ctx = this.ctx2d;

    ctx.fillStyle = this.colors.spectrum;
    for (let i = 0; i < bars; i++) {
      const v = data[i] / 255;
      const barH = v * h * 0.55;
      ctx.globalAlpha = 0.35 + v * 0.5;
      ctx.fillRect(i * barW, h - barH, Math.max(1, barW - 1), barH);
    }
    ctx.globalAlpha = 1;
  }

  #drawWave(w, h) {
    const data = this.timeData;
    const ctx = this.ctx2d;
    ctx.lineWidth = 2;
    ctx.strokeStyle = this.colors.wave;
    ctx.beginPath();
    const slice = w / data.length;
    for (let i = 0; i < data.length; i++) {
      const v = (data[i] - 128) / 128;
      const x = i * slice;
      const y = h * 0.42 + v * h * 0.32;
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.stroke();
  }
}

function ctxStrokeWave(ctx, w, h, color, ampFn) {
  ctx.lineWidth = 2;
  ctx.strokeStyle = color;
  ctx.beginPath();
  for (let x = 0; x <= w; x += 3) {
    const y = h * 0.42 + ampFn(x) * h;
    if (x === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }
  ctx.stroke();
}
