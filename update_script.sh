#!/usr/bin/env bash

# 1) Overwrite index.html
cat << 'EOF' > index.html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>My Tower Defense</title>
    <link rel="stylesheet" type="text/css" href="css/style.css">
  </head>
  <body>
    <!-- Game over / victory dialog -->
    <div id="gameOverDialog" style="display: none;">
      <div id="gameOverMessage"></div>
      <button id="closeGameOverDialog">Close</button>
    </div>

    <!-- Wrap the canvas + buttons in a container so they're anchored relative to the canvas -->
    <div id="gameContainer">
      <!-- Game canvas -->
      <canvas id="gameCanvas" width="800" height="600"></canvas>
      
      <!-- Container for Speed / Pause & Wave buttons, anchored top-right of the canvas -->
      <div id="topButtons">
        <button id="speedToggleButton" class="actionButton">1x</button>
        <button id="pauseButton" class="actionButton">Pause</button>
        <button id="sendWaveButton" class="actionButton">Send Next Wave Early</button>
      </div>
    </div>

    <!-- Enemy stats UI (bottom-left) -->
    <div id="enemyStats">
      <img id="enemyImage" src="" alt="enemy">
      <div><strong id="enemyName">Name</strong></div>
      <div>HP: <span id="enemyHp"></span></div>
      <div>Speed: <span id="enemySpeed"></span></div>
      <div>Gold on Kill: <span id="enemyGold"></span></div>
    </div>

    <!-- Panel for tower creation/upgrade -->
    <div id="towerSelectPanel"></div>

    <!-- Bottom bar for debug mode, table, gold input, restart, etc. -->
    <div id="bottomBar">
      <!-- Left side: debug controls -->
      <div class="debugControls">
        <!-- Debug toggle -->
        <div id="debugToggle">Enable Debug Mode</div>
        
        <!-- "Starting gold" + "Restart Game" row -->
        <label for="startingGoldInput">Starting gold</label>
        <input
          type="number"
          id="startingGoldInput"
          value="1000"
        />
        <button id="restartGameButton">Restart Game</button>

        <!-- Debug table container -->
        <div id="debugTableContainer">
          <table id="debugTable"></table>
        </div>
      </div>

      <!-- Right side placeholder (empty) -->
      <div></div>
    </div>

    <script type="module" src="./js/main.js"></script>
  </body>
</html>
EOF

# 2) Overwrite css/style.css
cat << 'EOF' > css/style.css
/* Make the body relatively positioned, so absolutely positioned elements anchor to it */
body {
    margin: 0;
    padding: 0;
    background-color: #333;
    color: #eee;
    font-family: sans-serif;
    position: relative;
}

/* Game Container */
#gameContainer {
    position: relative;
    width: 800px;
    margin: 0 auto;
}

/* Top-right buttons (Pause, Wave, Speed) container */
#topButtons {
    position: absolute;
    top: 10px;
    right: 10px;
    display: flex;
    gap: 6px;
}

/* Make all buttons more tap-friendly */
button,
.actionButton {
    padding: 4px 8px; /* 2px more on each side than before */
    cursor: pointer;
}

/* Action buttons share these styles */
.actionButton {
    background-color: #800;  /* Dark red */
    color: #fff;
    border: 1px solid #600;
    font-size: 12px;
    border-radius: 3px;
}

.actionButton:hover {
    background-color: #a00;  /* Slightly lighter on hover */
}

/* Game canvas styling (center + border) */
#gameCanvas {
    display: block;
    margin: 0 auto;
    background-color: #000;
    border: 2px solid #aaa;
}

/* Enemy stats panel at bottom-left */
#enemyStats {
    display: none;
    position: absolute;
    bottom: 10px;
    left: 10px;
    background: rgba(0,0,0,0.7);
    padding: 6px;
    border: 1px solid #999;
    border-radius: 3px;
}

/* Tower creation/upgrade panel */
#towerSelectPanel {
    display: none;
    position: absolute;
    background: rgba(0,0,0,0.8);
    border: 1px solid #999;
    border-radius: 3px;
    padding: 5px;
    color: #fff;
}

/* Bottom bar container */
#bottomBar {
    width: 800px;
    margin: 0 auto;
    margin-top: 10px;
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
}

/* Left debug controls container */
.debugControls {
    margin-bottom: 6px;
}

/* Debug toggle text */
#debugToggle {
    cursor: pointer;
    margin-bottom: 6px;
}

/* Hide the debug table container by default (shown if debug mode is on) */
#debugTableContainer {
    display: none;
}

/* The debug table itself */
#debugTable {
    border-collapse: collapse;
    border: 1px solid #999; /* Or you can remove if you prefer */
}

/* Starting gold input spacing */
#startingGoldInput {
    width: 60px;
    margin-left: 4px;
    margin-right: 8px;
}

/* Restart button spacing */
#restartGameButton {
    margin-top: 4px;
}

/* Game Over Dialog */
#gameOverDialog {
    position: fixed;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    background: rgba(0,0,0,0.85);
    border: 2px solid #999;
    padding: 20px;
    border-radius: 8px;
    z-index: 9999; /* ensure on top */
    text-align: center;
}

#gameOverMessage {
    font-size: 20px;
    margin-bottom: 12px;
}
EOF

# 3) Overwrite js/enemyManager.js (Halve base HP, stop movement if gameOver)
cat << 'EOF' > js/enemyManager.js
export class EnemyManager {
  constructor(game) {
    this.game = game;

    // Halved all base HP (50% of original)
    this.enemyBaseData = {
      drone: {
        baseHp: 15,
        gold: 5,
        baseSpeed: 80,
      },
      leaf_blower: {
        baseHp: 30,
        gold: 8,
        baseSpeed: 60,
      },
      trench_digger: {
        baseHp: 50,
        gold: 12,
        baseSpeed: 30,
      },
      trench_walker: {
        baseHp: 75,
        gold: 15,
        baseSpeed: 25,
      },
    };

    // Holds the loaded images, widths, heights, etc. from assetLoader.js
    this.loadedEnemyAssets = [];
  }

  setLoadedEnemyAssets(loadedEnemies) {
    this.loadedEnemyAssets = loadedEnemies;
  }

  spawnEnemy(type, hpMultiplier = 1) {
    const baseData = this.enemyBaseData[type] || this.enemyBaseData["drone"];
    const asset = this.loadedEnemyAssets.find(e => e.name === type)
      || this.loadedEnemyAssets[0];

    // 20% global HP reduction, then apply wave multiplier
    const finalHp = baseData.baseHp * 0.8 * hpMultiplier;

    // Random speed ~ ±20% around baseSpeed
    const speedFactor = 0.8 + Math.random() * 0.4;
    const finalSpeed = baseData.baseSpeed * speedFactor;

    const path = this.game.path;
    if (!path || path.length === 0) {
      console.warn("No path defined in Game; cannot spawn enemy properly.");
      return;
    }
    const firstWP = path[0];

    const enemy = {
      name: type,
      image: asset.image,
      width: asset.width,
      height: asset.height,
      x: firstWP.x,
      y: firstWP.y,
      hp: finalHp,
      baseHp: finalHp,
      speed: finalSpeed,
      gold: baseData.gold,
      waypointIndex: 1,
      dead: false,
    };

    this.game.enemies.push(enemy);
  }

  update(deltaSec) {
    // If gameOver, do not update enemies
    if (this.game.gameOver) return;

    // Move enemies, handle death
    this.game.enemies.forEach(e => {
      this.updateEnemy(e, deltaSec);
      if (e.hp <= 0) {
        this.game.gold += e.gold || 0;
        e.dead = true;
        // If this was the selected enemy, clear selection
        if (this.game.uiManager && this.game.uiManager.selectedEnemy === e) {
          this.game.uiManager.selectedEnemy = null;
          this.game.uiManager.hideEnemyStats();
        }
      }
    });

    // Remove dead or off-screen enemies
    this.game.enemies = this.game.enemies.filter(e => {
      if (e.dead) return false;
      if (e.x > this.game.width + e.width) {
        this.game.lives -= 1;
        if (this.game.lives <= 0 && !this.game.gameOver) {
          this.game.lives = 0; 
          this.game.endGame("Game Over");
        }
        return false;
      }
      return true;
    });
  }

  updateEnemy(enemy, deltaSec) {
    const path = this.game.path;
    const nextWP = path[enemy.waypointIndex];
    if (!nextWP) {
      // No next WP => just move off-screen
      enemy.x += enemy.speed * deltaSec;
      return;
    }

    // Move toward next waypoint
    const tx = nextWP.x;
    const ty = nextWP.y;
    const dx = tx - enemy.x;
    const dy = ty - enemy.y;
    const dist = Math.sqrt(dx * dx + dy * dy);
    const step = enemy.speed * deltaSec;

    if (dist <= step) {
      enemy.x = tx;
      enemy.y = ty;
      enemy.waypointIndex++;
    } else {
      enemy.x += (dx / dist) * step;
      enemy.y += (dy / dist) * step;
    }
  }

  drawEnemy(ctx, enemy) {
    this.drawImageSafely(
      ctx,
      enemy.image,
      enemy.x - enemy.width / 2,
      enemy.y - enemy.height / 2,
      enemy.width,
      enemy.height
    );

    // HP bar
    if (enemy.hp < enemy.baseHp) {
      const barW = enemy.width;
      const barH = 4;
      const pct  = Math.max(0, enemy.hp / enemy.baseHp);

      const barX = enemy.x - barW / 2;
      const barY = enemy.y - enemy.height / 2 - 6;

      ctx.fillStyle = "red";
      ctx.fillRect(barX, barY, barW, barH);

      ctx.fillStyle = "lime";
      ctx.fillRect(barX, barY, barW * pct, barH);
    }
  }

  drawImageSafely(ctx, image, x, y, w, h) {
    if (image.complete && image.naturalHeight !== 0) {
      ctx.drawImage(image, x, y, w, h);
    } else {
      console.warn("Image not loaded or invalid:", image);
    }
  }
}
EOF

# 4) Overwrite js/game.js (Add endGame() method, handle gameOver)
cat << 'EOF' > js/game.js
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

    // Speed handling
    this.speedOptions = [1, 2, 4, 0.5];
    this.speedIndex = 0;
    this.gameSpeed = this.speedOptions[this.speedIndex];

    // Start paused, label will say "Start game"
    this.isFirstStart = true;
    this.paused = true;

    // For detecting final win/loss
    this.gameOver = false;

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

    // Delegate clicks to UI Manager
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

    // Load waves into WaveManager
    this.waveManager.loadWavesFromLevel(data);
  }

  start() {
    requestAnimationFrame((ts) => this.gameLoop(ts));
  }

  endGame(message) {
    // Mark game over, pause
    this.gameOver = true;
    this.paused   = true;

    // Show the dialog
    const dlg = document.getElementById("gameOverDialog");
    const msg = document.getElementById("gameOverMessage");
    msg.textContent = message;
    dlg.style.display = "block";
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
    }

    // Always draw
    this.draw();
    requestAnimationFrame((ts) => this.gameLoop(ts));
  }

  handleCanvasClick(e) {
    if (this.uiManager && this.uiManager.handleCanvasClick) {
      const rect = this.canvas.getBoundingClientRect();
      const mx = e.clientX - rect.left;
      const my = e.clientY - rect.top;
      this.uiManager.handleCanvasClick(mx, my, rect);
    }
  }

  draw() {
    if (this.backgroundImg) {
      this.ctx.drawImage(this.backgroundImg, 0, 0, this.width, this.height);
    } else {
      this.ctx.clearRect(0, 0, this.width, this.height);
    }

    this.enemies.forEach(enemy => {
      this.enemyManager.drawEnemy(this.ctx, enemy);
    });

    this.towerManager.drawProjectiles(this.ctx);
    this.towerManager.drawTowers(this.ctx);

    // Tower spots (debug overlay) -- doubled radius
    this.ctx.fillStyle = "rgba(0, 255, 0, 0.5)";
    this.towerSpots.forEach((spot, i) => {
      this.ctx.beginPath();
      this.ctx.arc(spot.x, spot.y, 20, 0, Math.PI * 2);
      this.ctx.fill();
      if (this.debugMode) {
        this.ctx.fillStyle = "white";
        this.ctx.fillText(`T${i}`, spot.x - 10, spot.y - 25);
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
EOF

# 5) Overwrite js/towerManager.js (Track goldSpent, add sell logic)
cat << 'EOF' > js/towerManager.js
export class TowerManager {
  constructor(game) {
    this.game = game;
    this.towers = [];
    this.projectiles = [];

    // Single data definition for tower types
    this.towerTypes = [
      {
        type: "point",
        basePrice: 80,
        range: 169,
        splashRadius: 0,
        fireRate: 1.5,
        upgrades: [
          { level: 1, damage: 10, upgradeCost: 0   },
          { level: 2, damage: 15, upgradeCost: 50  },
          { level: 3, damage: 20, upgradeCost: 100 },
          { level: 4, damage: 25, upgradeCost: 150 },
        ],
      },
      {
        type: "splash",
        basePrice: 80,
        range: 104,
        splashRadius: 50,
        fireRate: 1.5,
        upgrades: [
          { level: 1, damage: 8,  upgradeCost: 0   },
          { level: 2, damage: 12, upgradeCost: 50  },
          { level: 3, damage: 16, upgradeCost: 100 },
          { level: 4, damage: 20, upgradeCost: 150 },
        ],
      },
    ];
  }

  getTowerData() {
    return this.towerTypes;
  }

  createTower(towerTypeName) {
    const def = this.towerTypes.find(t => t.type === towerTypeName);
    if (!def) return null;

    const firstLvl = def.upgrades[0];
    // Track gold spent (initial build cost)
    return {
      type: def.type,
      level: 1,
      range: def.range,
      damage: firstLvl.damage,
      splashRadius: def.splashRadius,
      fireRate: def.fireRate,
      fireCooldown: 0,
      upgradeCost: def.upgrades[1] ? def.upgrades[1].upgradeCost : 0,
      maxLevel: def.upgrades.length,
      x: 0,
      y: 0,
      spot: null,
      goldSpent: def.basePrice, // store total gold spent
    };
  }

  update(deltaSec) {
    // If gameOver, skip
    if (this.game.gameOver) return;

    // Fire towers
    this.towers.forEach(tower => {
      tower.fireCooldown -= deltaSec;
      if (tower.fireCooldown <= 0) {
        this.fireTower(tower);
        tower.fireCooldown = tower.fireRate;
      }
    });

    // Move projectiles
    this.projectiles.forEach(proj => {
      const step = proj.speed * deltaSec;
      const dx = proj.targetX - proj.x;
      const dy = proj.targetY - proj.y;
      const dist = Math.sqrt(dx * dx + dy * dy);

      if (dist <= step) {
        proj.x = proj.targetX;
        proj.y = proj.targetY;
        proj.hit = true;
      } else {
        proj.x += (dx / dist) * step;
        proj.y += (dy / dist) * step;
      }
    });

    // Handle collisions
    this.projectiles.forEach(proj => {
      if (proj.hit) {
        if (proj.splashRadius > 0) {
          // Splash damage
          const enemiesHit = this.game.enemies.filter(e => {
            const ex = e.x + e.width / 2;
            const ey = e.y + e.height / 2;
            const dx = proj.targetX - ex;
            const dy = proj.targetY - ey;
            return dx*dx + dy*dy <= proj.splashRadius * proj.splashRadius;
          });
          enemiesHit.forEach(e => {
            if (e === proj.mainTarget) e.hp -= proj.damage;
            else e.hp -= proj.damage / 2;
          });
        } else {
          // Single target
          if (proj.mainTarget) {
            proj.mainTarget.hp -= proj.damage;
          }
        }
      }
    });

    // Clean up projectiles that have hit
    this.projectiles = this.projectiles.filter(p => !p.hit);
  }

  fireTower(tower) {
    const enemiesInRange = this.game.enemies.filter(e => {
      const ex = e.x + e.width / 2;
      const ey = e.y + e.height / 2;
      const dx = ex - tower.x;
      const dy = ey - tower.y;
      return (dx*dx + dy*dy) <= (tower.range * tower.range);
    });
    if (!enemiesInRange.length) return;

    // Lock onto first enemy
    const target = enemiesInRange[0];
    const ex = target.x + target.width / 2;
    const ey = target.y + target.height / 2;

    this.projectiles.push({
      x: tower.x,
      y: tower.y,
      w: 4,
      h: 4,
      speed: 300,
      damage: tower.damage,
      splashRadius: tower.splashRadius,
      mainTarget: target,
      targetX: ex,
      targetY: ey,
      hit: false,
    });
  }

  upgradeTower(tower) {
    const def = this.towerTypes.find(t => t.type === tower.type);
    if (!def) return;
    if (tower.level >= def.upgrades.length) return; // maxed

    const nextLvlIndex = tower.level;
    const nextLvl = def.upgrades[nextLvlIndex];
    if (!nextLvl) return;

    if (this.game.gold < nextLvl.upgradeCost) return;

    // Spend gold
    this.game.gold -= nextLvl.upgradeCost;
    tower.goldSpent += nextLvl.upgradeCost; // track it
    tower.level++;

    tower.damage = nextLvl.damage;
    tower.upgradeCost = def.upgrades[tower.level]
      ? def.upgrades[tower.level].upgradeCost
      : 0;
  }

  sellTower(tower) {
    // 80% of goldSpent
    const refund = Math.floor(tower.goldSpent * 0.8);
    this.game.gold += refund;

    // Remove tower from manager
    this.towers = this.towers.filter(t => t !== tower);

    // Free the spot
    if (tower.spot) tower.spot.occupied = false;
  }

  drawTowers(ctx) {
    this.towers.forEach(t => {
      ctx.beginPath();
      // Double the circle radius from "12 + t.level*2" to something bigger
      ctx.arc(t.x, t.y, (24 + t.level*4), 0, Math.PI * 2);
      ctx.fillStyle = (t.type === "point") ? "blue" : "red";
      ctx.fill();
      ctx.strokeStyle = "#fff";
      ctx.stroke();

      // Optional range circle
      ctx.beginPath();
      ctx.arc(t.x, t.y, t.range, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(255,255,255,0.3)";
      ctx.stroke();
    });
  }

  drawProjectiles(ctx) {
    ctx.fillStyle = "yellow";
    this.projectiles.forEach(proj => {
      ctx.fillRect(proj.x - 2, proj.y - 2, proj.w, proj.h);
    });
  }
}
EOF

# 6) Overwrite js/uiManager.js (Increase towerSpot detectionDist, add Sell button)
cat << 'EOF' > js/uiManager.js
export class UIManager {
    constructor(game, enemyStatsDiv, towerSelectPanel, debugTable) {
      this.game = game;
      this.enemyStatsDiv = enemyStatsDiv;
      this.towerSelectPanel = towerSelectPanel;
      this.debugTable = debugTable;
  
      this.enemyImage    = document.getElementById("enemyImage");
      this.enemyNameEl   = document.getElementById("enemyName");
      this.enemyHpEl     = document.getElementById("enemyHp");
      this.enemySpeedEl  = document.getElementById("enemySpeed");
      this.enemyGoldEl   = document.getElementById("enemyGold");
  
      this.selectedEnemy = null;
    }
  
    initDebugTable() {
      this.debugTable.innerHTML = "";
      const towerData = this.game.towerManager.getTowerData();
      if (!towerData.length) return;
  
      const thead = document.createElement("thead");
      const headerRow = document.createElement("tr");
      headerRow.innerHTML = `
        <th style="min-width: 120px;"></th>
        <th>${towerData[0].type.toUpperCase()} Tower</th>
        <th>${towerData[1].type.toUpperCase()} Tower</th>
      `;
      thead.appendChild(headerRow);
      this.debugTable.appendChild(thead);
  
      const tbody = document.createElement("tbody");
  
      // Base Price row
      const basePriceRow = document.createElement("tr");
      basePriceRow.innerHTML = `
        <td><strong>Base Price</strong></td>
        <td>$${towerData[0].basePrice}</td>
        <td>$${towerData[1].basePrice}</td>
      `;
      tbody.appendChild(basePriceRow);
  
      // Upgrades
      const maxUpgrades = Math.max(
        towerData[0].upgrades.length,
        towerData[1].upgrades.length
      );
  
      for (let i = 0; i < maxUpgrades; i++) {
        const lvl = i + 1;
  
        // damage row
        const rowDamage = document.createElement("tr");
        rowDamage.innerHTML = `
          <td>Level ${lvl} Damage</td>
          <td>${towerData[0].upgrades[i] ? towerData[0].upgrades[i].damage : "-"}</td>
          <td>${towerData[1].upgrades[i] ? towerData[1].upgrades[i].damage : "-"}</td>
        `;
        tbody.appendChild(rowDamage);
  
        // upgrade cost row (except lvl 1)
        if (lvl > 1) {
          const rowCost = document.createElement("tr");
          rowCost.innerHTML = `
            <td>Level ${lvl} Upgrade Cost</td>
            <td>$${towerData[0].upgrades[i] ? towerData[0].upgrades[i].upgradeCost : "-"}</td>
            <td>$${towerData[1].upgrades[i] ? towerData[1].upgrades[i].upgradeCost : "-"}</td>
          `;
          tbody.appendChild(rowCost);
        }
      }
  
      this.debugTable.appendChild(tbody);
    }
  
    /**
     * Increase detectionDist from 100 to 400
     * (so user can click anywhere within the doubled radius).
     */
    getTowerSpotAt(mx, my, detectionDist = 400) {
      return this.game.towerSpots.find(s => {
        const dx = mx - s.x;
        const dy = my - s.y;
        return dx * dx + dy * dy < detectionDist;
      });
    }
  
    getEnemyAt(mx, my) {
      return this.game.enemies.find(e => {
        const left   = e.x - e.width / 2;
        const right  = e.x + e.width / 2;
        const top    = e.y - e.height / 2;
        const bottom = e.y + e.height / 2;
        return (mx >= left && mx <= right && my >= top && my <= bottom);
      });
    }
  
    getEntityUnderMouse(mx, my) {
      const spot = this.getTowerSpotAt(mx, my);
      if (spot) {
        return { type: "towerSpot", spot };
      }
      const enemy = this.getEnemyAt(mx, my);
      if (enemy) {
        return { type: "enemy", enemy };
      }
      return null;
    }
  
    handleCanvasClick(mx, my, rect) {
      const entity = this.getEntityUnderMouse(mx, my);
      if (!entity) {
        this.selectedEnemy = null;
        this.hideEnemyStats();
        this.hideTowerPanel();
        return;
      }
  
      if (entity.type === "towerSpot") {
        const spot = entity.spot;
        const existingTower = this.game.towerManager.towers.find(t => t.spot === spot);
        if (existingTower) {
          this.showExistingTowerPanel(existingTower, rect);
        } else {
          this.showNewTowerPanel(spot, rect);
        }
        return;
      }
  
      if (entity.type === "enemy") {
        const clickedEnemy = entity.enemy;
        this.selectedEnemy = clickedEnemy;
        this.showEnemyStats(clickedEnemy);
        this.hideTowerPanel();
      }
    }
  
    showExistingTowerPanel(tower, rect) {
      this.towerSelectPanel.innerHTML = "";
      this.towerSelectPanel.style.background = "none";
      this.towerSelectPanel.style.border = "none";
      this.towerSelectPanel.style.borderRadius = "0";
      this.towerSelectPanel.style.textAlign = "center";
  
      const title = document.createElement("div");
      title.style.fontWeight = "bold";
      title.textContent = `${tower.type.toUpperCase()} Tower`;
      this.towerSelectPanel.appendChild(title);

      // SELL BUTTON
      const sellBtn = document.createElement("button");
      sellBtn.textContent = "Sell Tower";
      sellBtn.style.marginBottom = "6px";
      sellBtn.addEventListener("click", () => {
        this.game.towerManager.sellTower(tower);
        this.hideTowerPanel();
      });
      this.towerSelectPanel.appendChild(sellBtn);
  
      const currStats = document.createElement("div");
      currStats.innerHTML = `
        Level: ${tower.level}<br>
        Damage: ${tower.damage}<br>
        Fire Rate: ${tower.fireRate.toFixed(2)}s
      `;
      this.towerSelectPanel.appendChild(currStats);
  
      if (tower.level < tower.maxLevel) {
        const nextLevel = tower.level + 1;
        const def = this.game.towerManager.getTowerData().find(d => d.type === tower.type);
        if (def) {
          const nextDef = def.upgrades[tower.level];
          if (nextDef) {
            const nextDamage = nextDef.damage;
            const cost = nextDef.upgradeCost;
            const nextRate = Math.max(0.8, tower.fireRate - 0.2).toFixed(2);
  
            const nextStats = document.createElement("div");
            nextStats.innerHTML = `
              <hr>
              <strong>Next Level ${nextLevel}:</strong><br>
              Damage: ${nextDamage}<br>
              Fire Rate: ${nextRate}s<br>
              Upgrade Cost: $${cost}
            `;
            this.towerSelectPanel.appendChild(nextStats);
  
            const upgradeBtn = document.createElement("button");
            upgradeBtn.textContent = "Upgrade";
            upgradeBtn.disabled = (this.game.gold < cost);
            upgradeBtn.addEventListener("click", () => {
              this.game.towerManager.upgradeTower(tower);
              this.hideTowerPanel();
            });
            this.towerSelectPanel.appendChild(upgradeBtn);
          }
        }
      } else {
        const maxed = document.createElement("div");
        maxed.style.marginTop = "6px";
        maxed.textContent = "Tower is at max level.";
        this.towerSelectPanel.appendChild(maxed);
      }
  
      this.towerSelectPanel.style.display = "block";
      const panelW = this.towerSelectPanel.offsetWidth;
      const panelH = this.towerSelectPanel.offsetHeight;
  
      const towerScreenX = tower.x + rect.left;
      const towerScreenY = tower.y + rect.top;
      this.towerSelectPanel.style.left = (towerScreenX - panelW / 2) + "px";
      this.towerSelectPanel.style.top  = (towerScreenY - panelH) + "px";
    }
  
    showNewTowerPanel(spot, rect) {
      this.towerSelectPanel.innerHTML = "";
      this.towerSelectPanel.style.background = "none";
      this.towerSelectPanel.style.border = "none";
      this.towerSelectPanel.style.borderRadius = "0";
      this.towerSelectPanel.style.textAlign = "center";
  
      const container = document.createElement("div");
      container.style.display = "flex";
      container.style.gap = "10px";
      container.style.justifyContent = "center";
      container.style.alignItems = "flex-start";
  
      const towerDefs = this.game.towerManager.getTowerData();
      towerDefs.forEach(def => {
        const towerDiv = document.createElement("div");
        towerDiv.style.background = "rgba(0,0,0,0.7)";
        towerDiv.style.border = "1px solid #999";
        towerDiv.style.padding = "4px";
        towerDiv.style.borderRadius = "4px";
        towerDiv.style.minWidth = "80px";
  
        const nameEl = document.createElement("div");
        nameEl.style.fontWeight = "bold";
        nameEl.textContent = def.type.toUpperCase();
        towerDiv.appendChild(nameEl);
  
        const statsEl = document.createElement("div");
        statsEl.innerHTML = `DMG: ${def.upgrades[0].damage}<br>Rate: ${def.fireRate}s`;
        towerDiv.appendChild(statsEl);
  
        const buildBtn = document.createElement("button");
        buildBtn.textContent = `$${def.basePrice}`;
        buildBtn.addEventListener("click", () => {
          if (this.game.gold >= def.basePrice && !spot.occupied) {
            this.game.gold -= def.basePrice;
            const newTower = this.game.towerManager.createTower(def.type);
            newTower.x = spot.x;
            newTower.y = spot.y;
            newTower.spot = spot;
            spot.occupied = true;
            this.game.towerManager.towers.push(newTower);
          }
          this.hideTowerPanel();
        });
        towerDiv.appendChild(buildBtn);
  
        container.appendChild(towerDiv);
      });
  
      this.towerSelectPanel.appendChild(container);
  
      this.towerSelectPanel.style.display = "block";
      const panelW = this.towerSelectPanel.offsetWidth;
      const panelH = this.towerSelectPanel.offsetHeight;
  
      const spotScreenX = spot.x + rect.left;
      const spotScreenY = spot.y + rect.top;
      this.towerSelectPanel.style.left = (spotScreenX - panelW / 2) + "px";
      this.towerSelectPanel.style.top  = (spotScreenY - panelH) + "px";
    }
  
    hideTowerPanel() {
      this.towerSelectPanel.style.display = "none";
    }
  
    showEnemyStats(enemy) {
      this.enemyStatsDiv.style.display = "block";
      this.enemyImage.src          = enemy.image.src;
      this.enemyNameEl.textContent = enemy.name;
      this.enemyHpEl.textContent   = `${enemy.hp}/${enemy.baseHp}`;
      this.enemySpeedEl.textContent= enemy.speed.toFixed(1);
      this.enemyGoldEl.textContent = enemy.gold;
    }
  
    hideEnemyStats() {
      this.enemyStatsDiv.style.display = "none";
    }
  
    handleMouseMove(e) {
      const rect = this.game.canvas.getBoundingClientRect();
      const mx = e.clientX - rect.left;
      const my = e.clientY - rect.top;
  
      const entity = this.getEntityUnderMouse(mx, my);
      this.game.canvas.style.cursor = entity ? "pointer" : "default";
    }
}
EOF

# 7) Overwrite js/waveManager.js (Declare victory when waveIndex >= waves.length)
cat << 'EOF' > js/waveManager.js
export class WaveManager {
  constructor(game) {
    this.game = game;
    this.waveIndex = 0;
    this.waveActive = false;
    this.timeUntilNextWave = 0;
    this.waves = [];
  }

  loadWavesFromLevel(levelData) {
    this.waves = (levelData && levelData.waves) || [];
    console.log("Waves loaded (reloaded):", this.waves);
  }

  update(deltaSec) {
    // If game is over, no updates
    if (this.game.gameOver) return;

    // If no active wave, see if there's another wave
    if (!this.waveActive && this.waveIndex < this.waves.length) {
      this.timeUntilNextWave -= deltaSec;
      if (this.timeUntilNextWave <= 0) {
        this.startWave(this.waveIndex);
      }
    }

    // Check if current wave is finished
    if (this.waveActive) {
      const waveInfo = this.waves[this.waveIndex];
      const allSpawned = waveInfo.enemyGroups.every(g => g.spawnedCount >= g.count);
      if (allSpawned && this.game.enemies.length === 0) {
        // wave done
        this.waveActive = false;
        this.waveIndex++;
        this.timeUntilNextWave = 0;

        // If waveIndex == waves.length => all waves done => Victory
        if (this.waveIndex >= this.waves.length && !this.game.gameOver) {
          this.game.endGame("You Win!");
        }
      }
    }
  }

  startWave(index) {
    this.waveActive = true;
    const waveInfo = this.waves[index];

    waveInfo.enemyGroups.forEach(group => {
      group.spawnedCount = 0;
      const timer = setInterval(() => {
        if (this.game.gameOver) {
          clearInterval(timer);
          return;
        }
        if (group.spawnedCount >= group.count) {
          clearInterval(timer);
          return;
        }
        this.spawnEnemyGroup(group);
        group.spawnedCount++;
      }, group.spawnInterval);
    });
  }

  spawnEnemyGroup(group) {
    this.game.enemyManager.spawnEnemy(group.type, group.hpMultiplier);
  }

  sendWaveEarly() {
    if (!this.waveActive && this.waveIndex < this.waves.length) {
      this.startWave(this.waveIndex);
    }
  }
}
EOF

# 8) Update main.js to hide the gameOverDialog on restart
cat << 'EOF' > js/main.js
import { Game } from "./game.js";
import { level1Data } from "./maps/level1.js";
import { UIManager } from "./uiManager.js";
import { loadAllAssets } from "./assetLoader.js";

let game = null;

async function startGameWithGold(startingGold) {
  // Hide any leftover gameOverDialog
  const dlg = document.getElementById("gameOverDialog");
  dlg.style.display = "none";

  const canvas = document.getElementById("gameCanvas");
  const pauseBtn = document.getElementById("pauseButton");
  const sendWaveBtn = document.getElementById("sendWaveButton");
  const enemyStatsDiv = document.getElementById("enemyStats");
  const towerSelectPanel = document.getElementById("towerSelectPanel");
  const debugToggle = document.getElementById("debugToggle");
  const debugTableContainer = document.getElementById("debugTableContainer");
  const debugTable = document.getElementById("debugTable");

  // Create new Game
  game = new Game(
    canvas,
    sendWaveBtn,
    enemyStatsDiv,
    towerSelectPanel,
    debugToggle,
    debugTableContainer
  );

  // UI Manager
  const uiManager = new UIManager(game, enemyStatsDiv, towerSelectPanel, debugTable);
  uiManager.initDebugTable();
  game.uiManager = uiManager;

  // Enemy definitions for loading
  const enemyTypes = [
    { name: "drone",         src: "assets/enemies/drone.png" },
    { name: "leaf_blower",   src: "assets/enemies/leaf_blower.png" },
    { name: "trench_digger", src: "assets/enemies/trench_digger.png" },
    { name: "trench_walker", src: "assets/enemies/trench_walker.png" },
  ];

  // Load images / assets
  const { loadedEnemies, loadedBackground } = await loadAllAssets(
    enemyTypes,
    level1Data.background
  );

  // Provide loaded enemy assets to the EnemyManager
  game.enemyManager.setLoadedEnemyAssets(loadedEnemies);

  // Configure level data
  game.setLevelData(level1Data, loadedBackground);

  // Override starting gold
  game.gold = startingGold;

  // Start
  game.start();
}

window.addEventListener("load", async () => {
  const startGoldInput = document.getElementById("startingGoldInput");
  const restartGameButton = document.getElementById("restartGameButton");

  // Close button on gameOverDialog
  const closeBtn = document.getElementById("closeGameOverDialog");
  if (closeBtn) {
    closeBtn.addEventListener("click", () => {
      const dlg = document.getElementById("gameOverDialog");
      dlg.style.display = "none";
    });
  }

  // 1) Default or user-supplied gold
  await startGameWithGold(parseInt(startGoldInput.value) || 1000);

  // 2) On "Restart Game", re-init
  restartGameButton.addEventListener("click", async () => {
    const desiredGold = parseInt(startGoldInput.value) || 0;
    await startGameWithGold(desiredGold);
  });
});
EOF

# 9) Finally, commit and push
git add . && git commit -m "Implement requested updates: double tower spots, half enemy HP, sell tower button, unify inline styles in style.css, show/hide gameOver dialog" && git push