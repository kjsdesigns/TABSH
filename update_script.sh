#!/usr/bin/env bash

# ========================================
# 1) Overwrite index.html
# ========================================
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
    <div id="gameContainer" style="position: relative; width: 800px; margin: 0 auto;">
      <!-- Game canvas -->
      <canvas id="gameCanvas" width="800" height="600"></canvas>
      
      <!-- Container for Speed / Pause & Wave buttons, anchored top-right of the canvas -->
      <div id="topButtons" style="position: absolute; top: 10px; right: 10px; display: flex; gap: 6px;">
        <button id="speedToggleButton" class="actionButton">1x</button>
        <button id="pauseButton" class="actionButton">Start game</button>
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
        <!-- "Starting gold" + "Restart Game" row -->
        <label for="startingGoldInput">Starting gold</label>
        <input
          type="number"
          id="startingGoldInput"
          value="1000"
        />
        <button id="restartGameButton">Restart Game</button>

        <!-- Enemy HP toggle row -->
        <div id="enemyHpContainer" style="margin-top: 6px;">
          <button id="enemyHpButton">Enemy HP: 100%</button>
        </div>

        <!-- Show current game parameters row -->
        <div id="currentGameLabel" style="margin-top: 6px;">
          Current game: Starting gold: 1000, Enemy HP: 100%
        </div>

        <!-- Debug table container (always shown) -->
        <div id="debugTableContainer" style="display: block; margin-top: 6px;">
          <table id="debugTable"></table>
        </div>
      </div>

      <!-- Right side placeholder (empty) -->
      <div></div>
    </div>

    <!-- End-of-game overlay (hidden by default) -->
    <div
      id="endOverlay"
      style="
        display: none;
        position: fixed;
        top: 0; 
        left: 0;
        width: 100vw; 
        height: 100vh; 
        background: rgba(0, 0, 0, 0.85);
        color: #fff;
        font-family: sans-serif;
        z-index: 9999;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
      "
    ></div>

    <script type="module" src="./js/main.js"></script>
  </body>
</html>
EOF

# ========================================
# 2) Overwrite css/style.css
#   (We'll just append some optional styling for #endOverlay messages.)
# ========================================
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
  
  /* Game canvas styling (center + border) */
  #gameCanvas {
    display: block;
    margin: 0 auto;
    background-color: #000;
    border: 2px solid #aaa;
  }
  
  /* Container for top-right buttons (Pause / Send Wave) */
  #topButtons {
    position: absolute;
    top: 10px;
    right: 10px;
    display: flex;
    gap: 6px;
  }
  
  /* Shared style for both action buttons (Pause, Wave) */
  .actionButton {
    background-color: #800;  /* Dark red */
    color: #fff;
    border: 1px solid #600;
    padding: 2px 6px;
    font-size: 12px;
    border-radius: 3px;
    cursor: pointer;
  }
  
  .actionButton:hover {
    background-color: #a00;  /* Slightly lighter on hover */
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

  /* Optional styling for endOverlay content */
  .endMessage {
    font-size: 48px;
    margin-bottom: 20px;
  }
  .bigRedX {
    color: red;
    font-size: 120px;
    margin-bottom: 20px;
  }
  .starContainer {
    font-size: 64px;
  }
  .starLit {
    color: gold;
    margin: 0 6px;
  }
  .starDim {
    color: gray;
    margin: 0 6px;
  }
EOF

# ========================================
# 3) Overwrite js/game.js
#    - Always debug = true
#    - Show lives as x/y
#    - Add maxLives property
#    - Add overlay functions for losing/winning
#    - Remove debug toggle logic
# ========================================
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
EOF

# ========================================
# 4) Overwrite js/main.js
#    - Add logic for HP toggle
#    - Update "currentGameLabel"
# ========================================
cat << 'EOF' > js/main.js
import { Game } from "./game.js";
import { level1Data } from "./maps/level1.js";
import { UIManager } from "./uiManager.js";
import { loadAllAssets } from "./assetLoader.js";

let game = null;

/**
 * Reusable function to start (or restart) the game with chosen gold and HP factor.
 */
async function startGameWithParams(startingGold, hpFactor) {
  const canvas = document.getElementById("gameCanvas");
  const pauseBtn = document.getElementById("pauseButton");
  const sendWaveBtn = document.getElementById("sendWaveButton");
  const enemyStatsDiv = document.getElementById("enemyStats");
  const towerSelectPanel = document.getElementById("towerSelectPanel");
  // We removed debugToggle
  const debugTableContainer = document.getElementById("debugTableContainer");
  const debugTable = document.getElementById("debugTable");

  // Create new Game
  game = new Game(
    canvas,
    sendWaveBtn,
    enemyStatsDiv,
    towerSelectPanel,
    debugTableContainer
  );

  // Provide the chosen params
  game.gold = startingGold;
  game.enemyHpFactor = hpFactor;

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

  // Start game loop
  game.start();

  // Update the "currentGameLabel"
  const currentGameLabel = document.getElementById("currentGameLabel");
  const hpPct = Math.round(hpFactor * 100);
  currentGameLabel.textContent = `Current game: Starting gold: ${startingGold}, Enemy HP: ${hpPct}%`;
}

window.addEventListener("load", async () => {
  const startGoldInput = document.getElementById("startingGoldInput");
  const restartGameButton = document.getElementById("restartGameButton");
  const enemyHpButton = document.getElementById("enemyHpButton");

  // For cycling HP from 80% to 120% in increments of 5%
  const possibleHPFactors = [0.8, 0.85, 0.9, 0.95, 1.0, 1.05, 1.1, 1.15, 1.2];
  let hpIndex = 4; // points to 1.0 in the array

  // Start with default
  await startGameWithParams(
    parseInt(startGoldInput.value) || 1000,
    possibleHPFactors[hpIndex]
  );

  // "Restart Game" => re-init with current gold + current HP factor
  restartGameButton.addEventListener("click", async () => {
    const desiredGold = parseInt(startGoldInput.value) || 0;
    await startGameWithParams(desiredGold, possibleHPFactors[hpIndex]);
  });

  // HP toggle button
  enemyHpButton.addEventListener("click", async () => {
    hpIndex = (hpIndex + 1) % possibleHPFactors.length;
    const hpFactor = possibleHPFactors[hpIndex];
    const hpPct = Math.round(hpFactor * 100);
    enemyHpButton.textContent = `Enemy HP: ${hpPct}%`;

    // If you want the button to dynamically change mid-game, you could do:
    // game.enemyHpFactor = hpFactor;
    // Or if we want to restart the game each time:
    const desiredGold = parseInt(startGoldInput.value) || 0;
    await startGameWithParams(desiredGold, hpFactor);
  });
});
EOF

# ========================================
# 5) Overwrite js/waveManager.js
#    - Ensure final wave victory check shows overlay
# ========================================
cat << 'EOF' > js/waveManager.js
export class WaveManager {
  constructor(game) {
    this.game = game;

    this.waveIndex = 0;
    this.waveActive = false;

    // Start with no forced delay; wave can start immediately if unpaused
    this.timeUntilNextWave = 0;

    this.waves = [];
  }

  loadWavesFromLevel(levelData) {
    this.waves = (levelData && levelData.waves) || [];
    console.log("Waves loaded (reloaded):", this.waves);
  }

  update(deltaSec) {
    // If wave not active, see if there's another wave to start
    if (!this.waveActive && this.waveIndex < this.waves.length) {
      this.timeUntilNextWave -= deltaSec;
      if (this.timeUntilNextWave <= 0) {
        this.startWave(this.waveIndex);
      }
    }

    // Check if the current wave is finished
    if (this.waveActive) {
      const waveInfo = this.waves[this.waveIndex];
      const allSpawned = waveInfo.enemyGroups.every(g => g.spawnedCount >= g.count);
      if (allSpawned && this.game.enemies.length === 0) {
        // Wave done
        this.waveActive = false;
        this.waveIndex++;
        // no forced delay for next wave
        this.timeUntilNextWave = 0;

        // If that was the last wave, and it's done, show "You Win"
        if (this.waveIndex >= this.waves.length) {
          // Completed all waves
          this.game.showWinOverlay();
        }
      }
    }
  }

  startWave(index) {
    this.waveActive = true;
    const waveInfo = this.waves[index];

    // For each group, spawn them over time (parallel if intervals overlap)
    waveInfo.enemyGroups.forEach(group => {
      group.spawnedCount = 0;
      const timer = setInterval(() => {
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
    // Use the consolidated logic in enemyManager
    this.game.enemyManager.spawnEnemy(group.type, group.hpMultiplier);
  }

  sendWaveEarly() {
    if (!this.waveActive && this.waveIndex < this.waves.length) {
      this.startWave(this.waveIndex);
    }
  }
}
EOF

# ========================================
# 6) Overwrite js/enemyManager.js
#    - Remove alert("Game Over"), call showLoseOverlay() instead
#    - Factor in game.enemyHpFactor
# ========================================
cat << 'EOF' > js/enemyManager.js
export class EnemyManager {
  constructor(game) {
    this.game = game;

    // Internal data: "raw" stats
    this.enemyBaseData = {
      drone: {
        baseHp: 30,
        gold: 5,
        baseSpeed: 80,
      },
      leaf_blower: {
        baseHp: 60,
        gold: 8,
        baseSpeed: 60,
      },
      trench_digger: {
        baseHp: 100,
        gold: 12,
        baseSpeed: 30,
      },
      trench_walker: {
        baseHp: 150,
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
    // Find matching image asset (fallback to index[0] if missing)
    const asset = this.loadedEnemyAssets.find(e => e.name === type)
      || this.loadedEnemyAssets[0];

    // 20% global HP reduction, wave multiplier, AND game.enemyHpFactor
    const finalHp = baseData.baseHp * 0.8 * hpMultiplier * this.game.enemyHpFactor;

    // Random speed ~ ±20% around baseSpeed
    const speedFactor = 0.8 + Math.random() * 0.4;
    const finalSpeed = baseData.baseSpeed * speedFactor;

    // Start at path[0]
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

    // Remove dead enemies or enemies that exit
    this.game.enemies = this.game.enemies.filter(e => {
      if (e.dead) return false;

      // If the enemy is off-screen to the right
      if (e.x > this.game.width + e.width) {
        this.game.lives -= 1;
        if (this.game.lives <= 0) {
          this.game.lives = 0;
          this.game.showLoseOverlay();
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
    const dist = Math.sqrt(dx*dx + dy*dy);
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

# ========================================
# 7) Git commit and push
# ========================================
git add . && git commit -m "Implement requested changes: lives x/y, wave count, enemy HP toggle, always debug, stylized lose/win overlays" && git push