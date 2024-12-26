import { EnemyManager } from "./enemyManager.js";
import { TowerManager } from "./towerManager.js";
import { WaveManager }  from "./waveManager.js";

export class Game {
  constructor(
    canvas,
    sendWaveBtn,
    enemyStatsDiv,
    towerSelectPanel,
    /* Removed debugToggle, */ 
    debugTableContainer
  ) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d");
    this.width = canvas.width;
    this.height = canvas.height;

    // Basic stats
    this.gold = 200;
    this.lives = 20;
    this.maxLives = 20; // For x/y display

    // Speed handling
    this.speedOptions = [1, 2, 4, 0.5];
    this.speedIndex = 0;
    this.gameSpeed = this.speedOptions[this.speedIndex];

    // Start paused, label will say "Start game"
    this.isFirstStart = true;
    this.paused = true;

    // Level data
    this.levelData = null;
    this.backgroundImg = null;
    this.path = [];
    this.towerSpots = [];

    // Enemies
    this.enemies = [];

    // Managers
    this.enemyManager = new EnemyManager(this);
    this.towerManager = new TowerManager(this);
    this.waveManager  = new WaveManager(this);

    // Additional factor for toggling enemy HP (default 1.0 => 100%)
    this.enemyHpFactor = 1.0;

    // Main loop
    this.lastTime = 0;

    // Debug mode always on
    this.debugMode = true;
    debugTableContainer.style.display = "block";

    // Hook up wave button
    sendWaveBtn.addEventListener("click", () => {
      this.waveManager.sendWaveEarly();
    });

    // Speed toggle button
    const speedBtn = document.getElementById("speedToggleButton");
    speedBtn.addEventListener("click", () => {
      this.speedIndex = (this.speedIndex + 1) % this.speedOptions.length;
      this.gameSpeed = this.speedOptions[this.speedIndex];
      speedBtn.textContent = `${this.gameSpeed}x`;
    });

    // Pause / "Start game" button
    const pauseBtn = document.getElementById("pauseButton");
    pauseBtn.textContent = "Start game";
    pauseBtn.addEventListener("click", () => {
      if (this.isFirstStart) {
        this.isFirstStart = false;
        this.paused = false;
        pauseBtn.textContent = "Pause";
        return;
      }
      this.paused = !this.paused;
      pauseBtn.textContent = this.paused ? "Resume" : "Pause";
    });

    // Canvas click => pass to UIManager
    this.canvas.addEventListener("click", (e) => this.handleCanvasClick(e));

    // Reference to overlay
    this.endOverlay = document.getElementById("endOverlay");
  }

  setLevelData(data, bgImg) {
    this.levelData = data;
    this.backgroundImg = bgImg;

    const scaleX = this.width / data.mapWidth;
    const scaleY = this.height / data.mapHeight;

    this.path = data.path.map(pt => ({
      x: pt.x * scaleX,
      y: pt.y * scaleY,
    }));
    this.towerSpots = data.towerSpots.map(s => ({
      x: s.x * scaleX,
      y: s.y * scaleY,
      occupied: false,
    }));

    // Load waves into WaveManager
    this.waveManager.loadWavesFromLevel(data);
  }

  start() {
    requestAnimationFrame((ts) => this.gameLoop(ts));
  }

  gameLoop(timestamp) {
    const delta = (timestamp - this.lastTime) || 0;
    this.lastTime = timestamp;

    // Convert to seconds, then scale by gameSpeed
    let deltaSec = delta / 1000;
    deltaSec *= this.gameSpeed;

    // Update if not paused
    if (!this.paused) {
      this.waveManager.update(deltaSec);
      this.enemyManager.update(deltaSec);
      this.towerManager.update(deltaSec);
    }

    // Always draw
    this.draw();
    requestAnimationFrame((ts) => this.gameLoop(ts));
  }

  handleCanvasClick(e) {
    const rect = this.canvas.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;
    if (this.uiManager && this.uiManager.handleCanvasClick) {
      this.uiManager.handleCanvasClick(mx, my, rect);
    }
  }

  draw() {
    if (this.backgroundImg) {
      this.ctx.drawImage(this.backgroundImg, 0, 0, this.width, this.height);
    } else {
      this.ctx.clearRect(0, 0, this.width, this.height);
    }

    // Enemies
    this.enemies.forEach(enemy => {
      this.enemyManager.drawEnemy(this.ctx, enemy);
    });

    // Projectiles
    this.towerManager.drawProjectiles(this.ctx);

    // Towers
    this.towerManager.drawTowers(this.ctx);

    // Tower spots (debug overlay)
    this.ctx.fillStyle = "rgba(0, 255, 0, 0.5)";
    this.towerSpots.forEach((spot, i) => {
      this.ctx.beginPath();
      this.ctx.arc(spot.x, spot.y, 10, 0, Math.PI * 2);
      this.ctx.fill();
      if (this.debugMode) {
        this.ctx.fillStyle = "white";
        this.ctx.fillText(`T${i}`, spot.x - 10, spot.y - 15);
        this.ctx.fillStyle = "rgba(0, 255, 0, 0.5)";
      }
    });

    // Path debug
    this.ctx.fillStyle = "yellow";
    this.path.forEach((wp, i) => {
      this.ctx.beginPath();
      this.ctx.arc(wp.x, wp.y, 5, 0, Math.PI * 2);
      this.ctx.fill();
      if (this.debugMode) {
        this.ctx.fillStyle = "white";
        this.ctx.fillText(`P${i}`, wp.x - 10, wp.y - 10);
        this.ctx.fillStyle = "yellow";
      }
    });

    // HUD
    this.ctx.fillStyle = "white";
    // Gold
    this.ctx.fillText(`Gold: ${this.gold}`, 10, 50);
    // Waves (use total wave count)
    this.ctx.fillText(
      `Wave: ${this.waveManager.waveIndex + 1}/${this.waveManager.waves.length}`,
      10,
      70
    );
    // Lives as x/y
    this.ctx.fillText(`Lives: ${this.lives}/${this.maxLives}`, 10, 90);

    if (
      !this.waveManager.waveActive &&
      this.waveManager.waveIndex < this.waveManager.waves.length
    ) {
      this.ctx.fillText("Next wave is ready", 10, 110);
    }
  }

  showLoseOverlay() {
    this.paused = true;
    // Show an overlay with "You Lost" and giant red X
    this.endOverlay.innerHTML = `
      <div class="endMessage">You Lost</div>
      <div class="bigRedX">X</div>
    `;
    this.endOverlay.style.display = "flex";
  }

  showWinOverlay() {
    this.paused = true;
    // Evaluate how many stars
    let starCount = 1;
    if (this.lives >= 18) {
      starCount = 3;
    } else if (this.lives >= 10) {
      starCount = 2;
    }
    // Build star markup
    const starHTML = [
      starCount >= 1 ? '<span class="starLit">★</span>' : '<span class="starDim">★</span>',
      starCount >= 2 ? '<span class="starLit">★</span>' : '<span class="starDim">★</span>',
      starCount >= 3 ? '<span class="starLit">★</span>' : '<span class="starDim">★</span>'
    ].join("");

    this.endOverlay.innerHTML = `
      <div class="endMessage">You Win</div>
      <div class="starContainer">
        ${starHTML}
      </div>
    `;
    this.endOverlay.style.display = "flex";
  }
}
