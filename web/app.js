/**
 * AeroBar — Interactive Web Companion & Simulator
 * Recreating Ilter Canberk's viral macOS air conditioner menu bar app
 */

// Application State
const state = {
  isOn: true,
  targetTemp: 21,
  roomTemp: 23,
  unit: 'C',
  mode: 'Cool',
  fanSpeed: 'Auto',
  sleep: 'Off',
  airflow: 'Vertical',
  isEco: false,
  soundEnabled: true,
  provider: 'smartthings',
  isSyncing: false
};

// Mode Color Profiles
const MODE_COLORS = {
  Cool: {
    primary: 'rgba(0, 210, 255, 0.85)',
    secondary: 'rgba(0, 122, 255, 0.45)',
    tertiary: 'rgba(100, 230, 255, 0.2)'
  },
  Heat: {
    primary: 'rgba(255, 120, 40, 0.85)',
    secondary: 'rgba(255, 70, 30, 0.45)',
    tertiary: 'rgba(255, 180, 70, 0.2)'
  },
  Auto: {
    primary: 'rgba(100, 210, 255, 0.85)',
    secondary: 'rgba(160, 220, 255, 0.45)',
    tertiary: 'rgba(255, 255, 255, 0.2)'
  },
  Dry: {
    primary: 'rgba(190, 90, 245, 0.85)',
    secondary: 'rgba(140, 60, 220, 0.45)',
    tertiary: 'rgba(220, 150, 255, 0.2)'
  },
  Fan: {
    primary: 'rgba(230, 230, 235, 0.8)',
    secondary: 'rgba(180, 180, 190, 0.4)',
    tertiary: 'rgba(140, 140, 150, 0.15)'
  },
  Eco: {
    primary: 'rgba(48, 209, 88, 0.85)',
    secondary: 'rgba(34, 160, 68, 0.45)',
    tertiary: 'rgba(90, 240, 130, 0.2)'
  }
};

const FAN_SPEED_MULTIPLIERS = {
  Auto: 1.1,
  Quiet: 0.5,
  Low: 0.75,
  Med: 1.0,
  High: 1.45,
  Turbo: 2.0
};

// Web Audio API Sound Synthesizer
class SoundFX {
  constructor() {
    this.ctx = null;
  }

  init() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      this.ctx = new AudioCtx();
    }
    if (this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  playBeep(isDouble = false) {
    if (!state.soundEnabled) return;
    this.init();
    if (!this.ctx) return;

    const now = this.ctx.currentTime;
    if (isDouble) {
      this.createTone(1950, now, 0.05);
      this.createTone(2450, now + 0.065, 0.06);
    } else {
      this.createTone(2100, now, 0.065);
    }
  }

  createTone(freq, startTime, duration) {
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(freq, startTime);

    gain.gain.setValueAtTime(0.0001, startTime);
    gain.gain.exponentialRampToValueAtTime(0.2, startTime + 0.01);
    gain.gain.exponentialRampToValueAtTime(0.0001, startTime + duration);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start(startTime);
    osc.stop(startTime + duration + 0.02);
  }
}

const soundFX = new SoundFX();

// DOM Elements Cache
const elements = {
  powerBtn: document.getElementById('power-toggle-btn'),
  statusBtn: document.getElementById('aerobar-status-btn'),
  statusTemp: document.getElementById('status-temp-text'),
  popover: document.getElementById('aerobar-popover'),
  popoverCard: document.getElementById('popover-card'),
  roomTempDisplay: document.getElementById('room-temp-display'),
  tempNumber: document.getElementById('temp-number'),
  tempUnitSymbol: document.getElementById('temp-unit-symbol'),
  ledDisplay: document.getElementById('ac-led-display'),
  louverFlap: document.getElementById('ac-louver-flap'),
  ecoBtn: document.getElementById('eco-mode-pill'),
  tempRangeInput: document.getElementById('temp-range-input'),
  sliderFill: document.getElementById('slider-fill'),
  sliderThumb: document.getElementById('slider-thumb'),
  stepperMinus: document.getElementById('stepper-minus-btn'),
  stepperPlus: document.getElementById('stepper-plus-btn'),
  boundMin: document.getElementById('bound-min-label'),
  boundMax: document.getElementById('bound-max-label'),
  modeValue: document.getElementById('mode-value'),
  fanValue: document.getElementById('fan-value'),
  fanIcon: document.getElementById('fan-icon'),
  sleepValue: document.getElementById('sleep-value'),
  sleepDot: document.getElementById('sleep-dot'),
  airflowValue: document.getElementById('airflow-value'),
  connectionStatus: document.getElementById('connection-status'),
  statusIcon: document.getElementById('status-icon'),
  statusText: document.getElementById('status-text'),
  settingsBtn: document.getElementById('settings-trigger-btn'),
  settingsDrawer: document.getElementById('settings-drawer'),
  drawerCloseBtn: document.getElementById('drawer-close-btn'),
  providerSelect: document.getElementById('provider-select'),
  audioToggle: document.getElementById('audio-toggle'),
  unitSegments: document.querySelectorAll('#unit-segmented-control .segment-btn'),
  clock: document.getElementById('menubar-clock'),
  canvas: document.getElementById('breeze-canvas')
};

// Canvas Breeze Animation Loop
const ctx = elements.canvas.getContext('2d');
let animationFrameId = null;
let breezePhase = 0;

function renderBreeze() {
  ctx.clearRect(0, 0, elements.canvas.width, elements.canvas.height);

  if (!state.isOn) {
    animationFrameId = requestAnimationFrame(renderBreeze);
    return;
  }

  const speedMultiplier = FAN_SPEED_MULTIPLIERS[state.fanSpeed] || 1.0;
  breezePhase += 0.045 * speedMultiplier;

  const colors = state.isEco ? MODE_COLORS.Eco : (MODE_COLORS[state.mode] || MODE_COLORS.Cool);

  const width = elements.canvas.width;
  const height = elements.canvas.height;
  const centerX = width / 2;
  const startY = 6;
  const endY = height;

  // Airflow Direction Offset
  let swingOffset = 0;
  if (state.airflow === 'Horizontal') {
    swingOffset = Math.sin(breezePhase * 0.4) * 35;
  } else if (state.airflow === '3D Swing') {
    swingOffset = Math.sin(breezePhase * 0.5) * 45;
  }

  const streamCount = 13;
  const topSpread = 160;
  const bottomSpread = 240;

  // Layer 1: Ambient Glow Wash
  ctx.save();
  ctx.beginPath();
  ctx.moveTo(centerX - topSpread / 2, startY);
  ctx.lineTo(centerX + topSpread / 2, startY);
  ctx.lineTo(centerX + bottomSpread / 2 + swingOffset, endY);
  ctx.lineTo(centerX - bottomSpread / 2 + swingOffset, endY);
  ctx.closePath();

  const washGrad = ctx.createLinearGradient(0, startY, 0, endY);
  washGrad.addColorStop(0, colors.secondary);
  washGrad.addColorStop(0.5, colors.tertiary);
  washGrad.addColorStop(1, 'rgba(0,0,0,0)');
  ctx.fillStyle = washGrad;
  ctx.filter = 'blur(10px)';
  ctx.fill();
  ctx.restore();

  // Layer 2: Fluttering Curved Streamers
  for (let i = 0; i < streamCount; i++) {
    const norm = (i / (streamCount - 1)) - 0.5; // -0.5 to 0.5
    const startX = centerX + norm * topSpread;

    const waveAmp = 8 + Math.abs(norm) * 6;
    const waveFreq = 2.4;
    const sway = Math.sin(breezePhase + i * 0.42) * waveAmp;

    const endX = centerX + norm * bottomSpread + swingOffset + sway;

    const cp1x = startX + sway * 0.35;
    const cp1y = startY + (endY - startY) * 0.35;
    const cp2x = endX - sway * 0.45;
    const cp2y = startY + (endY - startY) * 0.7;

    ctx.beginPath();
    ctx.moveTo(startX, startY);
    ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, endX, endY);

    const grad = ctx.createLinearGradient(0, startY, 0, endY);
    grad.addColorStop(0, 'rgba(255, 255, 255, 0.9)');
    grad.addColorStop(0.2, colors.primary);
    grad.addColorStop(0.7, colors.secondary);
    grad.addColorStop(1, 'rgba(255, 255, 255, 0)');

    ctx.strokeStyle = grad;
    ctx.lineWidth = i % 2 === 0 ? 1.8 : 1.2;
    ctx.stroke();
  }

  animationFrameId = requestAnimationFrame(renderBreeze);
}

// Update UI View
function updateUI() {
  const minTemp = state.unit === 'C' ? 16 : 60;
  const maxTemp = state.unit === 'C' ? 32 : 90;

  // Power state
  if (state.isOn) {
    elements.powerBtn.classList.add('active');
    elements.popoverCard.classList.remove('ac-off');
    elements.louverFlap.classList.add('open');
    elements.fanIcon.classList.add('spinning');
    elements.statusTemp.textContent = `${state.targetTemp}°`;
    elements.ledDisplay.textContent = state.targetTemp;
  } else {
    elements.powerBtn.classList.remove('active');
    elements.popoverCard.classList.add('ac-off');
    elements.louverFlap.classList.remove('open');
    elements.fanIcon.classList.remove('spinning');
    elements.statusTemp.textContent = 'OFF';
  }

  // Target temperature display
  elements.tempNumber.textContent = state.targetTemp;
  elements.tempUnitSymbol.textContent = `°${state.unit}`;
  elements.roomTempDisplay.textContent = `Room ${state.roomTemp}°${state.unit}`;

  // Eco Mode
  if (state.isEco) {
    elements.ecoBtn.classList.add('active');
  } else {
    elements.ecoBtn.classList.remove('active');
  }

  // Slider & Range
  elements.tempRangeInput.min = minTemp;
  elements.tempRangeInput.max = maxTemp;
  elements.tempRangeInput.value = state.targetTemp;
  elements.boundMin.textContent = `${minTemp}°`;
  elements.boundMax.textContent = `${maxTemp}°`;

  const progress = (state.targetTemp - minTemp) / (maxTemp - minTemp);
  const trackWidth = elements.sliderTrackWrapper ? elements.sliderTrackWrapper.clientWidth : 200;
  const thumbWidth = 46;
  const maxTravel = Math.max(trackWidth - thumbWidth, 1);
  const thumbLeft = progress * maxTravel;

  elements.sliderFill.style.width = `${thumbLeft + thumbWidth}px`;
  elements.sliderThumb.style.left = `${thumbLeft}px`;

  // Cards
  elements.modeValue.textContent = state.mode;
  elements.fanValue.textContent = state.fanSpeed;
  elements.sleepValue.textContent = state.sleep;
  elements.airflowValue.textContent = state.airflow;

  if (state.sleep !== 'Off') {
    elements.sleepDot.classList.add('active');
  } else {
    elements.sleepDot.classList.remove('active');
  }

  // Fan RPM animation speed
  const fanDuration = (1.2 / (FAN_SPEED_MULTIPLIERS[state.fanSpeed] || 1.0)).toFixed(2);
  elements.fanIcon.style.animationDuration = `${fanDuration}s`;
}

// Sync Trigger with simulated feedback
function triggerSync() {
  elements.connectionStatus.classList.add('syncing');
  elements.statusText.textContent = 'Syncing...';
  elements.statusIcon.textContent = '􀅈';

  setTimeout(() => {
    elements.connectionStatus.classList.remove('syncing');
    elements.statusText.textContent = 'Connected';
    elements.statusIcon.textContent = '􀇻';
  }, 450);
}

// Event Listeners

// 1. Power Toggle
elements.powerBtn.addEventListener('click', () => {
  state.isOn = !state.isOn;
  soundFX.playBeep(true);
  triggerSync();
  updateUI();
});

// 2. Status Bar Item Toggle (Popover show/hide)
elements.statusBtn.addEventListener('click', () => {
  elements.statusBtn.classList.toggle('active');
  const isVisible = elements.popover.style.display !== 'none';
  elements.popover.style.display = isVisible ? 'none' : 'block';
});

// 3. Temperature Slider
elements.tempRangeInput.addEventListener('input', (e) => {
  if (!state.isOn) return;
  const val = parseInt(e.target.value, 10);
  if (val !== state.targetTemp) {
    state.targetTemp = val;
    soundFX.playBeep(false);
    updateUI();
  }
});

elements.tempRangeInput.addEventListener('change', () => {
  triggerSync();
});

// 4. Steppers Minus & Plus
elements.stepperMinus.addEventListener('click', () => {
  if (!state.isOn) return;
  const minTemp = state.unit === 'C' ? 16 : 60;
  if (state.targetTemp > minTemp) {
    state.targetTemp -= 1;
    soundFX.playBeep(false);
    triggerSync();
    updateUI();
  }
});

elements.stepperPlus.addEventListener('click', () => {
  if (!state.isOn) return;
  const maxTemp = state.unit === 'C' ? 32 : 90;
  if (state.targetTemp < maxTemp) {
    state.targetTemp += 1;
    soundFX.playBeep(false);
    triggerSync();
    updateUI();
  }
});

// 5. Eco Mode Toggle
elements.ecoBtn.addEventListener('click', () => {
  if (!state.isOn) return;
  state.isEco = !state.isEco;
  if (state.isEco && state.targetTemp < 24) {
    state.targetTemp = 24;
  }
  soundFX.playBeep(false);
  triggerSync();
  updateUI();
});

// 6. Interactive Dropdown Menus for Cards
const dropdownMap = [
  { card: 'card-mode', dropdown: 'mode-dropdown', prop: 'mode', attr: 'data-mode' },
  { card: 'card-fan', dropdown: 'fan-dropdown', prop: 'fanSpeed', attr: 'data-fan' },
  { card: 'card-sleep', dropdown: 'sleep-dropdown', prop: 'sleep', attr: 'data-sleep' },
  { card: 'card-airflow', dropdown: 'airflow-dropdown', prop: 'airflow', attr: 'data-airflow' }
];

dropdownMap.forEach(({ card, dropdown, prop, attr }) => {
  const cardEl = document.getElementById(card);
  const dropdownEl = document.getElementById(dropdown);

  cardEl.addEventListener('click', (e) => {
    e.stopPropagation();
    if (!state.isOn) return;

    // Close other dropdowns
    dropdownMap.forEach((item) => {
      if (item.dropdown !== dropdown) {
        document.getElementById(item.dropdown).classList.add('hidden');
      }
    });

    dropdownEl.classList.toggle('hidden');
  });

  dropdownEl.querySelectorAll('.dropdown-item').forEach((item) => {
    item.addEventListener('click', (e) => {
      e.stopPropagation();
      const val = item.getAttribute(attr);
      if (val) {
        state[prop] = val;
        soundFX.playBeep(false);
        triggerSync();
        dropdownEl.classList.add('hidden');
        updateUI();
      }
    });
  });
});

// Close open dropdowns on click outside
document.addEventListener('click', () => {
  dropdownMap.forEach(({ dropdown }) => {
    document.getElementById(dropdown).classList.add('hidden');
  });
});

// 7. Settings Drawer Toggle
elements.settingsBtn.addEventListener('click', (e) => {
  e.stopPropagation();
  elements.settingsDrawer.classList.remove('hidden');
});

elements.drawerCloseBtn.addEventListener('click', () => {
  elements.settingsDrawer.classList.add('hidden');
});

// 8. Provider Selector
elements.providerSelect.addEventListener('change', (e) => {
  state.provider = e.target.value;
  const helpText = document.getElementById('provider-help');
  const stFields = document.querySelectorAll('.smartthings-field');
  const sensiboFields = document.querySelectorAll('.sensibo-field');
  const daikinFields = document.querySelectorAll('.daikin-field');
  const tuyaFields = document.querySelectorAll('.tuya-field');

  stFields.forEach((el) => el.classList.add('hidden'));
  sensiboFields.forEach((el) => el.classList.add('hidden'));
  daikinFields.forEach((el) => el.classList.add('hidden'));
  tuyaFields.forEach((el) => el.classList.add('hidden'));

  if (state.provider === 'smartthings') {
    helpText.textContent = 'Connect directly to your Samsung Smart AC using a SmartThings Personal Access Token.';
    stFields.forEach((el) => el.classList.remove('hidden'));
  } else if (state.provider === 'sensibo') {
    helpText.textContent = 'Cloud REST API integration with Sensibo Sky / Air Pods.';
    sensiboFields.forEach((el) => el.classList.remove('hidden'));
  } else if (state.provider === 'daikin') {
    helpText.textContent = 'Local LAN HTTP control for Daikin WiFi adapter (BRP / SkyFi).';
    daikinFields.forEach((el) => el.classList.remove('hidden'));
  } else if (state.provider === 'tuya') {
    helpText.textContent = 'Tuya / Smart Life Cloud IoT OpenAPI device commands.';
    tuyaFields.forEach((el) => el.classList.remove('hidden'));
  } else if (state.provider === 'lg') {
    helpText.textContent = 'LG ThinQ OpenAPI cloud appliance connection.';
  } else {
    helpText.textContent = 'Realistic in-memory AC simulation with instant visual feedback.';
  }
});

// 9. Temperature Unit Segmented Control
elements.unitSegments.forEach((btn) => {
  btn.addEventListener('click', () => {
    elements.unitSegments.forEach((b) => b.classList.remove('active'));
    btn.classList.add('active');

    const newUnit = btn.getAttribute('data-unit');
    if (newUnit !== state.unit) {
      if (newUnit === 'F') {
        state.targetTemp = Math.round((state.targetTemp * 9) / 5 + 32);
        state.roomTemp = Math.round((state.roomTemp * 9) / 5 + 32);
      } else {
        state.targetTemp = Math.round(((state.targetTemp - 32) * 5) / 9);
        state.roomTemp = Math.round(((state.roomTemp - 32) * 5) / 9);
      }
      state.unit = newUnit;
      updateUI();
    }
  });
});

// 10. Sound Toggle
elements.audioToggle.addEventListener('change', (e) => {
  state.soundEnabled = e.target.checked;
});

// 11. Top Clock Live Update
function updateClock() {
  const d = new Date();
  const options = { weekday: 'short', month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' };
  elements.clock.textContent = d.toLocaleDateString('en-US', options).replace(/,/g, '');
}
setInterval(updateClock, 30000);
updateClock();

// Initialize View and Breeze Loop
updateUI();
renderBreeze();
