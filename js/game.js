import { EnemyManager } from "./enemyManager.js";
import { TowerManager } from "./towerManager.js";
import { WaveManager }  from "./waveManager.js";

export class Game {
  constructor(
    canvas,
    sendWaveBtn,
    enemyStatsDiv,
    towerSelectPanel,
    debugToggle,
    debugTableContainer
  ) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d");
    this.width = canvas.width;
    this.height = canvas.height;

    this.gold = 200;
    this.lives = 20;

    // Speed handling (unchanged from previous)
    this.speedOptions = [1, 2, 4, 0.5]; 
    this.speedIndex = 0;
    this.gameSpeed = this.speedOptions[this.speedIndex]; // default = 1x

    // For #2: start paused + label = "Start game"
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

    // Main loop
    this.lastTime = 0;

    // Debug mode on by default
    this.debugMode = true;

    // Hook wave button
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
    // On fresh load or restart => label "Start game"
    pauseBtn.textContent = "Start game";
    pauseBtn.addEventListener("click", () => {
      // If it's the very first click, unpause + set label to "Pause"
      if (this.isFirstStart) {
        this.isFirstStart = false;
        this.paused = false;
        pauseBtn.textContent = "Pause";
        return;
      }
      // Otherwise, normal pause toggling
      this.paused = !this.paused;
      pauseBtn.textContent = this.paused ? "Resume" : "Pause";
    });

    // Debug toggle
    debugToggle.addEventListener("click", () => {
      this.debugMode = !this.debugMode;
      debugToggle.textContent = this.debugMode
        ? "Disable Debug Mode"
        : "Enable Debug Mode";
      debugTableContainer.style.display = this.debugMode ? "block" : "none";
    });
    debugToggle.textContent = "Disable Debug Mode";
    debugTableContainer.style.display = "block";

    // Canvas click
    this.canvas.addEventListener("click", (e) => this.handleCanvasClick(e));

    // Canvas mousemove for cursor changes
    this.canvas.addEventListener("mousemove", (e) => this.handleMouseMove(e));
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

  /**
   * Adjust the enemy base HP to be 20% less than before,
   * and give each enemy a random speed (~ +/-20% from a chosen base).
   */
  setEnemyTypes(types) {
    function randomSpeed(base) {
      const factor = 0.8 + Math.random() * 0.4; // ±20%
      return base * factor;
    }
    this.enemyTypes = types.map(e => {
      if (e.name === "drone") {
        return {
          ...e,
          baseHp: 30 * 0.8, // 20% less
          gold: 5,
          speed: randomSpeed(80),
        };
      }
      if (e.name === "leaf_blower") {
        return {
          ...e,
          baseHp: 60 * 0.8,
          gold: 8,
          speed: randomSpeed(60),
        };
      }
      if (e.name === "trench_digger") {
        return {
          ...e,
          baseHp: 100 * 0.8,
          gold: 12,
          speed: randomSpeed(30),
        };
      }
      if (e.name === "trench_walker") {
        return {
          ...e,
          baseHp: 150 * 0.8,
          gold: 15,
          speed: randomSpeed(25),
        };
      }
      // fallback
      return {
        ...e,
        baseHp: 50 * 0.8,
        gold: 5,
        speed: randomSpeed(50),
      };
    });
  }

  start() {
    requestAnimationFrame((ts) => this.gameLoop(ts));
  }

  gameLoop(timestamp) {
    let delta = (timestamp - this.lastTime) || 0;
    this.lastTime = timestamp;

    // Convert to seconds, then scale by gameSpeed
    let deltaSec = delta / 1000;
    deltaSec *= this.gameSpeed;

    // If not paused, update
    if (!this.paused) {
      this.waveManager.update(deltaSec);
      this.enemyManager.update(deltaSec);
      this.towerManager.update(deltaSec);
    }

    // Always draw (even if paused)
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

  handleMouseMove(e) {
    const rect = this.canvas.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;

    let hoveringClickable = false;

    // Check tower spot
    for (const s of this.towerSpots) {
      const dx = mx - s.x;
      const dy = my - s.y;
      if (dx * dx + dy * dy < 100) {
        hoveringClickable = true;
        break;
      }
    }

    // Check enemies
    if (!hoveringClickable) {
      for (const enemy of this.enemies) {
        // enemy is centered at (enemy.x, enemy.y),
        // so bounding box is (x - width/2, y - height/2) to (x + width/2, y + height/2)
        const left   = enemy.x - enemy.width / 2;
        const right  = enemy.x + enemy.width / 2;
        const top    = enemy.y - enemy.height / 2;
        const bottom = enemy.y + enemy.height / 2;

        if (mx >= left && mx <= right && my >= top && my <= bottom) {
          hoveringClickable = true;
          break;
        }
      }
    }

    // Update canvas cursor
    this.canvas.style.cursor = hoveringClickable ? "pointer" : "default";
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

    // Tower spots
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
    this.ctx.fillText(`Gold: ${this.gold}`, 10, 50);
    this.ctx.fillText(
      `Wave: ${this.waveManager.waveIndex + 1}/${this.waveManager.waves.length}`,
      10,
      70
    );
    this.ctx.fillText(`Lives: ${this.lives}`, 10, 90);
    if (
      !this.waveManager.waveActive &&
      this.waveManager.waveIndex < this.waveManager.waves.length
    ) {
      this.ctx.fillText("Next wave is ready", 10, 110);
    }
  }
}