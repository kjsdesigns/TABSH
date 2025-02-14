import { EnemyManager } from "./enemyManager.js";
import { TowerManager } from "./towerManager.js";
import { WaveManager }  from "./waveManager.js";
import { HeroManager }  from "./heroManager.js";

export class Game {
  constructor(
    canvas,
    enemyStatsDiv,
    towerSelectPanel,
    debugTableContainer
  ) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d");
    this.width = canvas.width;
    this.height = canvas.height;

    this.gold = 200;
    this.lives = 20;
    this.maxLives = 20;

    this.speedOptions = [1, 2, 4, 0.5];
    this.speedIndex = 0;
    this.gameSpeed = this.speedOptions[this.speedIndex];

    this.isFirstStart = true;
    this.paused = true;

    this.levelData = null;
    this.backgroundImg = null;
    this.path = [];
    this.towerSpots = [];
    this.enemies = [];

    this.globalEnemyHpMultiplier = 1.0;

    this.enemyManager = new EnemyManager(this);
    this.towerManager = new TowerManager(this);
    this.waveManager  = new WaveManager(this);
    this.heroManager  = new HeroManager(this);

    this.lastTime = 0;
    this.debugMode = true;

    const pauseBtn = document.getElementById("pauseButton");
    pauseBtn.innerHTML = "&#9658;"; // "▶"
    pauseBtn.addEventListener("click", () => {
      if (this.isFirstStart) {
        this.isFirstStart = false;
        this.paused = false;
        pauseBtn.innerHTML = "&#10073;&#10073;"; 
        return;
      }
      this.paused = !this.paused;
      pauseBtn.innerHTML = this.paused ? "&#9658;" : "&#10073;&#10073;";
    });

    const speedBtn = document.getElementById("speedToggleButton");
    speedBtn.addEventListener("click", () => {
      this.speedIndex = (this.speedIndex + 1) % this.speedOptions.length;
      this.gameSpeed = this.speedOptions[this.speedIndex];
      speedBtn.textContent = `${this.gameSpeed}x`;
    });

    this.canvas.addEventListener("click", (e) => this.handleCanvasClick(e));
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
    this.waveManager.loadWavesFromLevel(data);
  }

  start() {
    requestAnimationFrame((ts) => this.gameLoop(ts));
  }

  gameLoop(timestamp) {
    const delta = (timestamp - this.lastTime) || 0;
    this.lastTime = timestamp;
    let deltaSec = delta / 1000;
    deltaSec *= this.gameSpeed;

    if (!this.paused) {
      this.waveManager.update(deltaSec);
      this.enemyManager.update(deltaSec);
      this.towerManager.update(deltaSec);
      this.heroManager.update(deltaSec);
      // also handle collisions where enemies can fight with heroes
      // a simple approach is to do it in heroManager or enemyManager
      // but if we want to do “both sides deal damage,” we can do it there
    }

    this.draw();
    requestAnimationFrame((ts) => this.gameLoop(ts));
  }

  handleCanvasClick(e) {
    const rect = this.canvas.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;
    if (this.uiManager && this.uiManager.handleCanvasClick) {
      // The UI manager is responsible for deciding if we clicked a hero, tower, enemy, spot, etc.
      this.uiManager.handleCanvasClick(mx, my, rect);

      // Also check if we’re setting a new rally for a selected tower (barracks)
      if (this.uiManager.selectedTower && this.uiManager.selectedTower.type === "barracks") {
        // We assume user wanted to set rally here
        const tower = this.uiManager.selectedTower;
        if (tower.unitGroup) {
          tower.unitGroup.setRallyPoint(mx, my);
        }
        // done
        this.uiManager.selectedTower = null;
      }
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

    // Towers (and their units)
    this.towerManager.drawTowers(this.ctx);

    // Heroes
    this.heroManager.draw(this.ctx);

    // Path debug
    if (this.debugMode) {
      this.ctx.fillStyle = "yellow";
      this.path.forEach((wp, i) => {
        this.ctx.beginPath();
        this.ctx.arc(wp.x, wp.y, 5, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.fillStyle = "white";
        this.ctx.fillText(`P${i}`, wp.x - 10, wp.y - 10);
        this.ctx.fillStyle = "yellow";
      });
    }

    // Tower spots debug
    if (this.debugMode) {
      this.ctx.fillStyle = "rgba(0,255,0,0.5)";
      this.towerSpots.forEach((spot, i) => {
        this.ctx.beginPath();
        this.ctx.arc(spot.x, spot.y, 20, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.fillStyle = "white";
        this.ctx.fillText(`T${i}`, spot.x-10, spot.y-25);
        this.ctx.fillStyle = "rgba(0,255,0,0.5)";
      });
    }

    // HUD
    this.ctx.fillStyle = "white";
    this.ctx.fillText(`Gold: ${this.gold}`, 10, 50);
    this.ctx.fillText(`Wave: ${this.waveManager.waveIndex + 1}/${this.waveManager.waves.length}`, 10, 70);
    this.ctx.fillText(`Lives: ${this.lives}/${this.maxLives}`, 10, 90);

    if (!this.waveManager.waveActive && this.waveManager.waveIndex < this.waveManager.waves.length) {
      this.ctx.fillText("Next wave is ready", 10, 110);
    }
  }
}
