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
    this.enemyTypes = [];

    // Pause control
    this.paused = false;

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

    // We also grab #pauseButton from the DOM
    const pauseBtn = document.getElementById("pauseButton");
    pauseBtn.addEventListener("click", () => {
      this.paused = !this.paused;
      pauseBtn.textContent = this.paused ? "Resume" : "Pause";
    });

    // Debug toggle from prior code, omitted for brevity ...
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

    // **Load waves into WaveManager now that level data is available**
    this.waveManager.loadWavesFromLevel(data);
  }

  setEnemyTypes(types) {
    this.enemyTypes = types.map(e => {
      if (e.name === "drone")         return { ...e, baseHp: 30,  gold: 5 };
      if (e.name === "leaf_blower")   return { ...e, baseHp: 60,  gold: 8 };
      if (e.name === "trench_digger") return { ...e, baseHp: 100, gold: 12 };
      if (e.name === "trench_walker") return { ...e, baseHp: 150, gold: 15 };
      return { ...e, baseHp: 50,      gold: 5 };
    });
  }

  start() {
    requestAnimationFrame((ts) => this.gameLoop(ts));
  }

  gameLoop(timestamp) {
    const delta = timestamp - this.lastTime || 0;
    this.lastTime = timestamp;
    const deltaSec = delta / 1000;

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

  // Change cursor to pointer if over a tower spot or enemy
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

    // Check enemies if not found tower spot
    if (!hoveringClickable) {
      for (const enemy of this.enemies) {
        if (
          mx >= enemy.x &&
          mx <= enemy.x + enemy.width &&
          my >= enemy.y &&
          my <= enemy.y + enemy.height
        ) {
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
    if (!this.waveManager.waveActive && this.waveManager.waveIndex < this.waveManager.waves.length) {
      this.ctx.fillText(`Next wave is ready`, 10, 90);
    }
  }
}