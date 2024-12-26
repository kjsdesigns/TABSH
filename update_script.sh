#!/usr/bin/env bash

# Overwrite index.html
cat << 'EOF' > index.html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>My Tower Defense</title>
    <link rel="stylesheet" type="text/css" href="css/style.css">
  </head>
  <body>
    <!-- Wrap the canvas + buttons in a container so they're anchored relative to the canvas -->
    <div id="gameContainer">
      <!-- Game canvas -->
      <canvas id="gameCanvas" width="800" height="600"></canvas>
      
      <!-- Container for speed, pause, settings buttons (top-right) -->
      <div id="topButtons">
        <button id="speedToggleButton" class="actionButton">1x</button>
        <!-- Pause/Resume button with icons -->
        <button id="pauseButton" class="actionButton">&#9658;</button>
        <!-- Gear icon for settings -->
        <button id="settingsButton" class="actionButton">&#9881;</button>
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

    <!-- Settings dialog (hidden by default) -->
    <div id="settingsDialog">
      <div id="settingsDialogClose">&#10006;</div>
      <div id="settingsContent">
        <!-- Starting gold + restart -->
        <div style="margin-bottom: 8px;">
          <label for="startingGoldInput">Starting gold</label>
          <input type="number" id="startingGoldInput" value="1000" />
          <button id="restartGameButton">Restart Game</button>
        </div>
        <!-- Enemy HP segmented toggle -->
        <div id="enemyHpSegment" style="margin-bottom: 10px;">
          <!-- Populated by main.js -->
        </div>
        <!-- Debug table container -->
        <div id="debugTableContainer" style="margin-top: 10px;">
          <table id="debugTable"></table>
        </div>
      </div>
    </div>

    <!-- End-game messages (overlays) -->
    <div id="loseMessage">
      <h1 style="font-size: 3em; margin: 0;">You lost</h1>
      <div style="font-size: 6em;">X</div>
    </div>
    <div id="winMessage">
      <h1 style="font-size: 3em; margin: 0;">You win!</h1>
      <div id="winStars" style="font-size: 4em; color: gold; margin-top: 10px;"></div>
    </div>

    <script type="module" src="./js/main.js"></script>
  </body>
</html>
EOF

# Overwrite css/style.css
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

/* Top-right buttons (Pause, Speed, Settings) container */
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
    padding: 6px 10px; /* 2px more all around than before */
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

/* Settings dialog */
#settingsDialog {
    display: none;
    position: fixed;
    top: 50%;
    left: 50%;
    width: 300px;
    background: rgba(0,0,0,0.85);
    border: 2px solid #999;
    border-radius: 8px;
    transform: translate(-50%, -50%);
    z-index: 9999;
    padding: 10px;
}

/* Close button for the settings dialog */
#settingsDialogClose {
    float: right;
    cursor: pointer;
    margin-bottom: 10px;
}

/* Lose / Win messages (dialog style) */
#loseMessage,
#winMessage {
    display: none;
    text-align: center;
    font-family: sans-serif;
    margin-top: 20px;
    position: fixed;
    top: 40%;
    left: 50%;
    transform: translate(-50%, -50%);
    background: rgba(0,0,0,0.85);
    border: 2px solid #999;
    padding: 20px;
    border-radius: 8px;
    z-index: 9999;
}

/* Debug table styling */
#debugTable {
    border-collapse: collapse;
    border: 1px solid #999;
}

#debugTable th,
#debugTable td {
    padding: 4px 8px;
    border: 1px solid #666;
}
EOF

# Overwrite js/game.js
cat << 'EOF' > js/game.js
import { EnemyManager } from "./enemyManager.js";
import { TowerManager } from "./towerManager.js";
import { WaveManager }  from "./waveManager.js";

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
    // track both current and max lives for the "x/y" display
    this.lives = 20;
    this.maxLives = 20;

    // Speed handling
    this.speedOptions = [1, 2, 4, 0.5];
    this.speedIndex = 0;
    this.gameSpeed = this.speedOptions[this.speedIndex];

    // Start paused, label will show icon "▶" initially
    this.isFirstStart = true;
    this.paused = true;

    // Level data
    this.levelData = null;
    this.backgroundImg = null;
    this.path = [];
    this.towerSpots = [];

    // Enemies
    this.enemies = [];

    // Global enemy HP multiplier (set from outside; includes the 0.5 factor)
    this.globalEnemyHpMultiplier = 1.0;

    // Managers
    this.enemyManager = new EnemyManager(this);
    this.towerManager = new TowerManager(this);
    this.waveManager  = new WaveManager(this);

    // Main loop
    this.lastTime = 0;

    // Debug mode always on now
    this.debugMode = true;

    // Pause/Resume button
    const pauseBtn = document.getElementById("pauseButton");
    pauseBtn.innerHTML = "&#9658;"; // "▶"
    pauseBtn.addEventListener("click", () => {
      if (this.isFirstStart) {
        this.isFirstStart = false;
        this.paused = false;
        pauseBtn.innerHTML = "&#10073;&#10073;"; // "⏸"
        return;
      }
      this.paused = !this.paused;
      pauseBtn.innerHTML = this.paused ? "&#9658;" : "&#10073;&#10073;";
    });

    // Speed toggle button
    const speedBtn = document.getElementById("speedToggleButton");
    speedBtn.addEventListener("click", () => {
      this.speedIndex = (this.speedIndex + 1) % this.speedOptions.length;
      this.gameSpeed = this.speedOptions[this.speedIndex];
      speedBtn.textContent = `${this.gameSpeed}x`;
    });

    // Canvas click
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
    // Tower spots 2x bigger => store them, but we'll draw radius 20
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

    // Tower spots (debug overlay) - radius 20
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
    this.ctx.fillText(`Lives: ${this.lives}/${this.maxLives}`, 10, 90);

    if (
      !this.waveManager.waveActive &&
      this.waveManager.waveIndex < this.waveManager.waves.length
    ) {
      this.ctx.fillText("Next wave is ready", 10, 110);
    }
  }
}
EOF

# Overwrite js/main.js
cat << 'EOF' > js/main.js
import { Game } from "./game.js";
import { level1Data } from "./maps/level1.js";
import { UIManager } from "./uiManager.js";
import { loadAllAssets } from "./assetLoader.js";

/**
 * Global parameters the user can set before starting the game:
 * - enemyHpPercent: now default 100, but we treat that as "50% of old baseline"
 *   => new globalEnemyHpMultiplier = 0.5 * (enemyHpPercent / 100).
 */
let enemyHpPercent = 100;

let game = null;

/**
 * Reusable function to start (or restart) the game with chosen gold.
 */
async function startGameWithGold(startingGold) {
  const canvas = document.getElementById("gameCanvas");
  const pauseBtn = document.getElementById("pauseButton");
  const enemyStatsDiv = document.getElementById("enemyStats");
  const towerSelectPanel = document.getElementById("towerSelectPanel");
  const debugTableContainer = document.getElementById("debugTableContainer");
  const loseMessage = document.getElementById("loseMessage");
  const winMessage = document.getElementById("winMessage");

  // Clear any end-game messages
  loseMessage.style.display = "none";
  winMessage.style.display = "none";
  const starsElem = winMessage.querySelector("#winStars");
  if (starsElem) starsElem.innerHTML = "";

  // Create new Game
  game = new Game(
    canvas,
    enemyStatsDiv,
    towerSelectPanel,
    debugTableContainer
  );

  // UI Manager
  const uiManager = new UIManager(game, enemyStatsDiv, towerSelectPanel, debugTableContainer, loseMessage, winMessage);
  uiManager.initDebugTable();
  game.uiManager = uiManager;

  // This factor is 0.5 * (enemyHpPercent / 100) => new 100% = old 50%
  game.globalEnemyHpMultiplier = 0.5 * (enemyHpPercent / 100);

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

/**
 * On load, initialize the game + set up UI events.
 */
window.addEventListener("load", async () => {
  const startGoldInput = document.getElementById("startingGoldInput");
  const restartGameButton = document.getElementById("restartGameButton");

  // Settings dialog references
  const settingsDialog = document.getElementById("settingsDialog");
  const settingsButton = document.getElementById("settingsButton");
  const settingsDialogClose = document.getElementById("settingsDialogClose");

  // Create segmented HP toggle
  const hpOptions = [];
  for (let v = 80; v <= 120; v += 5) {
    hpOptions.push(v);
  }

  const enemyHpSegment = document.getElementById("enemyHpSegment");
  // Clear old if any
  enemyHpSegment.innerHTML = "";
  hpOptions.forEach(value => {
    const btn = document.createElement("button");
    btn.textContent = value + "%";
    btn.classList.add("enemyHpOption");
    // Highlight if default
    if (value === enemyHpPercent) {
      btn.style.backgroundColor = "#444";
    }
    btn.addEventListener("click", () => {
      enemyHpPercent = value;
      // Clear all highlights
      document.querySelectorAll(".enemyHpOption").forEach(b => {
        b.style.backgroundColor = "";
      });
      // Highlight this one
      btn.style.backgroundColor = "#444";
    });
    enemyHpSegment.appendChild(btn);
  });

  // Start game with default or user-supplied gold
  await startGameWithGold(parseInt(startGoldInput.value) || 1000);

  // Restart game event
  restartGameButton.addEventListener("click", async () => {
    const desiredGold = parseInt(startGoldInput.value) || 0;
    await startGameWithGold(desiredGold);
  });

  // Toggle the settings dialog on gear click
  settingsButton.addEventListener("click", () => {
    const style = settingsDialog.style.display;
    settingsDialog.style.display = (style === "none" || style === "") ? "block" : "none";
  });

  // Close the settings dialog
  settingsDialogClose.addEventListener("click", () => {
    settingsDialog.style.display = "none";
  });
});
EOF

# Overwrite js/uiManager.js
cat << 'EOF' > js/uiManager.js
export class UIManager {
    constructor(
      game,
      enemyStatsDiv,
      towerSelectPanel,
      debugTable,
      loseMessageDiv,
      winMessageDiv
    ) {
      this.game = game;
      this.enemyStatsDiv = enemyStatsDiv;
      this.towerSelectPanel = towerSelectPanel;
      this.debugTable = debugTable;
      this.loseMessageDiv = loseMessageDiv;
      this.winMessageDiv = winMessageDiv;
  
      // Elements inside enemyStatsDiv
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
  
    // Increase detectionDist to 200 (was 100)
    getTowerSpotAt(mx, my, detectionDist = 200) {
      return this.game.towerSpots.find(s => {
        const dx = mx - s.x;
        const dy = my - s.y;
        return dx * dx + dy * dy < detectionDist * detectionDist;
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
        // clicked empty space, hide panels
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
  
      const currStats = document.createElement("div");
      currStats.innerHTML = `
        Level: ${tower.level}<br>
        Damage: ${tower.damage}<br>
        Fire Rate: ${tower.fireRate.toFixed(2)}s
      `;
      this.towerSelectPanel.appendChild(currStats);
  
      // Next-level info if not maxed
      if (tower.level < tower.maxLevel) {
        const nextLevel = tower.level + 1;
        const def = this.game.towerManager.getTowerData().find(d => d.type === tower.type);
        if (def) {
          const nextDef = def.upgrades[tower.level]; // tower.level=1 => index=1
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

      // Add Sell Tower button
      const sellBtn = document.createElement("button");
      sellBtn.style.display = "block";
      sellBtn.style.margin = "6px auto 0 auto";
      sellBtn.textContent = "Sell Tower";
      sellBtn.addEventListener("click", () => {
        this.game.towerManager.sellTower(tower);
        this.hideTowerPanel();
      });
      this.towerSelectPanel.appendChild(sellBtn);
  
      // Show, measure, then position
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
      this.enemyHpEl.textContent   = `${enemy.hp.toFixed(1)}/${enemy.baseHp.toFixed(1)}`;
      this.enemySpeedEl.textContent= enemy.speed.toFixed(1);
      this.enemyGoldEl.textContent = enemy.gold;
    }
  
    hideEnemyStats() {
      this.enemyStatsDiv.style.display = "none";
    }

    /**
     * Called by enemyManager when lives <= 0
     */
    showLoseDialog() {
      this.loseMessageDiv.style.display = "block";
    }

    /**
     * Called by waveManager on final wave completion if we still have >0 lives
     * Display 1, 2, or 3 stars based on how many lives remain
     */
    showWinDialog(finalLives, maxLives) {
      this.winMessageDiv.style.display = "block";
      const starsDiv = this.winMessageDiv.querySelector("#winStars");

      let starCount = 1;
      if (finalLives >= 18) {
        starCount = 3;
      } else if (finalLives >= 10) {
        starCount = 2;
      }

      const starSymbols = [];
      for(let i=1; i<=3; i++){
        if (i <= starCount) {
          // lit star
          starSymbols.push("★");
        } else {
          // dull star
          starSymbols.push("☆");
        }
      }
      if(starsDiv) {
        starsDiv.innerHTML = starSymbols.join(" ");
      }
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

# Commit and push changes
git add .
git commit -m "Implement requested UI updates: remove wave button, create settings dialog, pause/resume icons, segmented HP toggle, tower selling, style refactoring, and new baseline enemy HP at 50%."
git push