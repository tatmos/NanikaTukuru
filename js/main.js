import { AudioLab } from "./audio-lab.js";
import { Visualizer } from "./visualizer.js";

const lab = new AudioLab();

const els = {
  play: document.getElementById("btn-play"),
  stop: document.getElementById("btn-stop"),
  status: document.getElementById("status-label"),
  freqReadout: document.getElementById("freq-readout"),
  canvas: document.getElementById("viz"),
  wave: document.getElementById("wave"),
  freq: document.getElementById("freq"),
  freqOut: document.getElementById("freq-out"),
  oscGain: document.getElementById("osc-gain"),
  oscOut: document.getElementById("osc-out"),
  noiseGain: document.getElementById("noise-gain"),
  noiseOut: document.getElementById("noise-out"),
  filterType: document.getElementById("filter-type"),
  cutoff: document.getElementById("cutoff"),
  cutoffOut: document.getElementById("cutoff-out"),
  filterQ: document.getElementById("filter-q"),
  qOut: document.getElementById("q-out"),
  delayTime: document.getElementById("delay-time"),
  delayOut: document.getElementById("delay-out"),
  delayFb: document.getElementById("delay-fb"),
  fbOut: document.getElementById("fb-out"),
  delayWet: document.getElementById("delay-wet"),
  wetOut: document.getElementById("wet-out"),
  master: document.getElementById("master"),
  masterOut: document.getElementById("master-out"),
};

const viz = new Visualizer(
  els.canvas,
  () => lab.analyser,
  () => lab.playing
);
viz.start();

function setPlayingUi(playing) {
  els.play.disabled = playing;
  els.stop.disabled = !playing;
  els.status.textContent = playing ? "再生中" : "停止中";
  els.status.classList.toggle("is-live", playing);
}

els.play.addEventListener("click", async () => {
  try {
    await lab.start();
    setPlayingUi(true);
  } catch (err) {
    console.error(err);
    els.status.textContent = "起動に失敗";
  }
});

els.stop.addEventListener("click", () => {
  lab.stop();
  setPlayingUi(false);
});

function bindRange(input, output, key, map = (v) => Number(v)) {
  const sync = () => {
    const value = map(input.value);
    output.textContent = formatOut(value);
    lab.setParam(key, value);
    if (key === "freq") {
      els.freqReadout.textContent = `${Math.round(value)} Hz`;
    }
  };
  input.addEventListener("input", sync);
  sync();
}

function formatOut(value) {
  if (Number.isInteger(value)) return String(value);
  return String(Math.round(value * 100) / 100);
}

bindRange(els.freq, els.freqOut, "freq", (v) => Number(v));
bindRange(els.oscGain, els.oscOut, "oscGain", (v) => Number(v));
bindRange(els.noiseGain, els.noiseOut, "noiseGain", (v) => Number(v));
bindRange(els.cutoff, els.cutoffOut, "cutoff", (v) => Number(v));
bindRange(els.filterQ, els.qOut, "q", (v) => Number(v));
bindRange(els.delayTime, els.delayOut, "delayTime", (v) => Number(v));
bindRange(els.delayFb, els.fbOut, "delayFb", (v) => Number(v));
bindRange(els.delayWet, els.wetOut, "delayWet", (v) => Number(v));
bindRange(els.master, els.masterOut, "master", (v) => Number(v));

els.wave.addEventListener("change", () => {
  lab.setParam("wave", els.wave.value);
});

els.filterType.addEventListener("change", () => {
  lab.setParam("filterType", els.filterType.value);
});

setPlayingUi(false);
