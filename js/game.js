import { EnemyManager } from "./enemyManager.js";
import { TowerManager } from "./towerManager.js";
import { WaveManager } from "./waveManager.js";

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
    this.lives = 20; // Player lives
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
    this.waveManager = new WaveManager(this);

    // Main loop
    this.lastTime = 0;

    // Debug mode on by default
    this.debugMode = true;

    // Hook wave button
    sendWaveBtn.addEventListener("click", () => {
      this.waveManager.sendWaveEarly();
    });

    const pauseBtn = document.getElementById("pauseButton");
    pauseBtn.addEventListener("click", () => {
      this.paused = !this.paused;
      pauseBtn.textContent = this.paused ? "Resume" : "Pause";
    });

    debugToggle.addEventListener("click", () => {
      this.debugMode = !this.debugMode;
      debugToggle.textContent = this.debugMode
        ? "Disable Debug Mode"
        : "Enable Debug Mode";
      debugTableContainer.style.display = this.debugMode ? "block" : "none";
    });
    debugToggle.textContent = "Disable Debug Mode";
    debugTableContainer.style.display = "block";

    this.canvas.addEventListener("click", (e) => this.handleCanvasClick(e));
    this.canvas.addEventListener("mousemove", (e) => this.handleMouseMove(e));
  }

  setLevelData(data, bgImg) {
    this.levelData = data;
    this.backgroundImg = bgImg;

    const scaleX = this.width / data.mapWidth;
    const scaleY = this.height / data.mapHeight;

    this.path = data.path.map((pt) => ({
      x: pt.x * scaleX,
      y: pt.y * scaleY,
    }));
    this.towerSpots = data.towerSpots.map((s) => ({
      x: s.x * scaleX,
      y: s.y * scaleY,
      occupied: false,
    }));

    this.waveManager.loadWavesFromLevel(data);
  }

  setEnemyTypes(types) {
    this.enemyTypes = types.map((e) => {
      if (e.name === "drone") return { ...e, baseHp: 30, gold: 5 };
      if (e.name === "leaf_blower") return { ...e, baseHp: 60, gold: 8 };
      if (e.name === "trench_digger") return { ...e, baseHp: 100, gold: 12 };
      if (e.name === "trench_walker") return { ...e, baseHp: 150, gold: 15 };
      return { ...e, baseHp: 50, gold: 5 };
    });
  }

  start() {
    requestAnimationFrame((ts) => this.gameLoop(ts));
  }

  gameLoop(timestamp) {
    const delta = timestamp - this.lastTime || 0;
    this.lastTime = timestamp;
    const deltaSec = delta / 1000;

    // Check for game over
    if (this.lives <= 0) {
      this.paused = true;
      alert("Game Over");
      return;
    }

    // If not paused, update
    if (!this.paused) {
      this.waveManager.update(deltaSec);
      this.enemyManager.update(deltaSec);
      this.towerManager.update(deltaSec);
    }

    // Decrement lives if enemies exit
    this.enemies = this.enemies.filter((enemy) => {
      if (enemy.x > this.width || enemy.y > this.height) {
        this.lives -= 1;
        return false;
      }
      return true;
    });

    // Always draw (even if paused)
    this.draw();

    requestAnimationFrame((ts) => this.gameLoop(ts));
  }

  draw() {
    if (this.backgroundImg) {
      this.ctx.drawImage(this.backgroundImg, 0, 0, this.width, this.height);
    } else {
      this.ctx.clearRect(0, 0, this.width, this.height);
    }

    this.enemies.forEach((enemy) => {
      this.enemyManager.drawEnemy(this.ctx, enemy);
    });

    this.towerManager.drawProjectiles(this.ctx);
    this.towerManager.drawTowers(this.ctx);

    this.ctx.fillStyle = "white";
    this.ctx.fillText(`Gold: ${this.gold}`, 10, 50);
    this.ctx.fillText(
      `Wave: ${this.waveManager.waveIndex + 1}/${this.waveManager.waves.length}`,
      10,
      70
    );
    this.ctx.fillText(`Lives: ${this.lives}`, 10, 90); // Display lives
  }
}