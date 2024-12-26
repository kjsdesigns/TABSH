#!/usr/bin/env bash

# OVERVIEW OF CHANGES
# 1) Add "Settings" heading at top-left of settings dialog.
# 2) Two-column layout: left column has "current game" info, "enemy HP" label + segmented buttons, 
#    starting gold input, and "Restart Game" at the bottom; right column holds the tower stats table.
# 3) Reduce text size in tower stats table by 2px.
# 4) Show "Current game" info again (like the old debug label).
# 5) Label to the left of enemy HP buttons "Enemy HP", and reduce the button text size and padding.
# 6) Enemy image popup: max 80px each dimension.
# 7) Build tower dialog: show fire rate with 1 decimal place.
# 8) Fix the issue where "You lost" remains after restarting by resetting gameOver/lives at restart.

# This script overwrites index.html, css/style.css, js/main.js, and js/uiManager.js
# to apply the requested changes. Then it commits and pushes.

########################################
# Overwrite index.html
########################################
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

    <!-- Settings dialog (hidden by default, now 2-column layout) -->
    <div id="settingsDialog">
      <div id="settingsDialogClose">&#10006;</div>
      <h2 id="settingsHeading">Settings</h2>
      <div id="settingsDialogContent">
        <!-- LEFT column: current game info, enemy HP label & toggles, gold, restart -->
        <div id="settingsLeftColumn">
          <div id="currentGameLabel" class="smallInfoLabel"></div>

          <!-- "Enemy HP" label + segmented buttons -->
          <div id="enemyHpRow">
            <label id="enemyHpLabel">Enemy HP</label>
            <div id="enemyHpSegment"></div>
          </div>

          <!-- Starting gold + input -->
          <div id="startingGoldRow">
            <label for="startingGoldInput">Starting gold</label>
            <input type="number" id="startingGoldInput" value="1000" />
          </div>

          <!-- Restart game button at bottom -->
          <button id="restartGameButton" class="actionButton" style="margin-top: 10px;">
            Restart Game
          </button>
        </div>

        <!-- RIGHT column: tower stats table -->
        <div id="settingsRightColumn">
          <div id="debugTableContainer">
            <table id="debugTable"></table>
          </div>
        </div>
      </div>
    </div>

    <!-- Lose message -->
    <div id="loseMessage">
      <h1 style="font-size: 3em; margin: 0;">You lost</h1>
      <div style="font-size: 6em;">X</div>
      <div style="margin-top: 10px;">
        <button id="loseRestartBtn" class="actionButton" style="margin-right: 10px;">Restart</button>
        <button id="loseSettingsBtn" class="actionButton">Settings</button>
      </div>
    </div>

    <!-- Win message -->
    <div id="winMessage">
      <h1 style="font-size: 3em; margin: 0;">You win!</h1>
      <div id="winStars" style="font-size: 4em; color: gold; margin-top: 10px;"></div>
      <div style="margin-top: 10px;">
        <button id="winRestartBtn" class="actionButton" style="margin-right: 10px;">Restart</button>
        <button id="winSettingsBtn" class="actionButton">Settings</button>
      </div>
    </div>

    <script type="module" src="./js/main.js"></script>
  </body>
</html>
EOF


########################################
# Overwrite css/style.css
########################################
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

/* Constrain the enemy image to 80px max each dimension */
#enemyImage {
    max-width: 80px;
    max-height: 80px;
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
    width: 600px;
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

/* "Settings" heading */
#settingsHeading {
    margin: 0;
    margin-bottom: 10px;
}

/* 2-column layout for settings content */
#settingsDialogContent {
    display: flex;
    flex-direction: row;
    gap: 15px;
}

/* left column = 200-250px wide, right column flexible */
#settingsLeftColumn {
    flex: 0 0 220px;
    display: flex;
    flex-direction: column;
    gap: 10px;
}

#enemyHpRow {
    display: flex;
    align-items: center;
    gap: 5px;
}

#enemyHpLabel {
    font-size: 12px; 
    margin: 0; 
    padding: 0;
}

/* The segmented HP buttons: smaller text, less padding */
.enemyHpOption {
    font-size: 10px;         /* 2px smaller than default 12px */
    padding: 3px 2px;        /* reduce top/bottom by ~50%, left/right to 1-2px */
    margin-right: 2px;
}

/* Container for tower stats table on right */
#settingsRightColumn {
    flex: 1;
}

/* Debug table container + smaller text in table */
#debugTableContainer {
    margin-top: 0;
}

#debugTable {
    border-collapse: collapse;
    border: 1px solid #999;
    font-size: 10px; /* reduce by 2px from normal ~12px */
    width: 100%;
}

#debugTable th,
#debugTable td {
    padding: 4px 8px;
    border: 1px solid #666;
}

.smallInfoLabel {
    font-size: 12px;
    line-height: 1.2em;
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
EOF


########################################
# Overwrite js/main.js
########################################
cat << 'EOF' > js/main.js
import { Game } from "./game.js";
import { level1Data } from "./maps/level1.js";
import { UIManager } from "./uiManager.js";
import { loadAllAssets } from "./assetLoader.js";

/**
 * Global parameters:
 * - enemyHpPercent: we use (enemyHpPercent/100) for globalEnemyHpMultiplier
 */
let enemyHpPercent = 100;

let game = null;
let lastStartingGold = 1000; // track so we can re-use it upon restarts

async function startGameWithGold(startingGold) {
  lastStartingGold = startingGold;

  // If there's an old "You lost" or "You win" visible, hide it
  const loseMessage = document.getElementById("loseMessage");
  const winMessage = document.getElementById("winMessage");
  if (loseMessage) loseMessage.style.display = "none";
  if (winMessage) winMessage.style.display = "none";

  const canvas = document.getElementById("gameCanvas");
  const enemyStatsDiv = document.getElementById("enemyStats");
  const towerSelectPanel = document.getElementById("towerSelectPanel");
  const debugTableContainer = document.getElementById("debugTableContainer");

  // Create new Game
  game = new Game(
    canvas,
    enemyStatsDiv,
    towerSelectPanel,
    debugTableContainer
  );

  // Ensure we reset lives and gameOver flags
  game.lives = 20;
  game.maxLives = 20;
  game.gameOver = false;
  if (game.waveManager) {
    game.waveManager.waveIndex = 0;
    game.waveManager.waveActive = false;
  }

  // UI Manager
  const uiManager = new UIManager(
    game,
    enemyStatsDiv,
    towerSelectPanel,
    debugTableContainer,
    loseMessage,
    winMessage
  );
  uiManager.initDebugTable();
  game.uiManager = uiManager;

  // Double from old baseline => (enemyHpPercent / 100)
  game.globalEnemyHpMultiplier = enemyHpPercent / 100;

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
  game.enemyManager.setLoadedEnemyAssets(loadedEnemies);

  // Configure level data
  game.setLevelData(level1Data, loadedBackground);

  // Set gold
  game.gold = startingGold;

  // Start
  game.start();

  // Update current game label
  const currentGameLabel = document.getElementById("currentGameLabel");
  if (currentGameLabel) {
    currentGameLabel.textContent = `Current game: Starting gold: ${startingGold}, Enemy HP: ${enemyHpPercent}%`;
  }
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
  if (enemyHpSegment) {
    enemyHpSegment.innerHTML = "";
    hpOptions.forEach(value => {
      const btn = document.createElement("button");
      btn.textContent = value + "%";
      btn.classList.add("enemyHpOption");
      // highlight if it's the current
      if (value === enemyHpPercent) {
        btn.style.backgroundColor = "#444";
      }
      btn.addEventListener("click", () => {
        enemyHpPercent = value;
        // Clear all highlights
        document.querySelectorAll(".enemyHpOption").forEach(b => {
          b.style.backgroundColor = "";
        });
        // Highlight the new selection
        btn.style.backgroundColor = "#444";
        // Also update currentGameLabel if we want
        const currentGameLabel = document.getElementById("currentGameLabel");
        if (currentGameLabel) {
          currentGameLabel.textContent = `Current game: Starting gold: ${startGoldInput.value}, Enemy HP: ${enemyHpPercent}%`;
        }
      });
      enemyHpSegment.appendChild(btn);
    });
  }

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

  // Wire up the lose/win message buttons
  const loseRestartBtn = document.getElementById("loseRestartBtn");
  const loseSettingsBtn = document.getElementById("loseSettingsBtn");
  const winRestartBtn  = document.getElementById("winRestartBtn");
  const winSettingsBtn = document.getElementById("winSettingsBtn");

  if (loseRestartBtn) {
    loseRestartBtn.addEventListener("click", async () => {
      document.getElementById("loseMessage").style.display = "none";
      await startGameWithGold(lastStartingGold);
    });
  }
  if (loseSettingsBtn) {
    loseSettingsBtn.addEventListener("click", () => {
      settingsDialog.style.zIndex = "10001";
      document.getElementById("loseMessage").style.zIndex = "10000";
      settingsDialog.style.display = "block";
    });
  }
  if (winRestartBtn) {
    winRestartBtn.addEventListener("click", async () => {
      document.getElementById("winMessage").style.display = "none";
      await startGameWithGold(lastStartingGold);
    });
  }
  if (winSettingsBtn) {
    winSettingsBtn.addEventListener("click", () => {
      settingsDialog.style.zIndex = "10001";
      document.getElementById("winMessage").style.zIndex = "10000";
      settingsDialog.style.display = "block";
    });
  }

  // If "Restart" is clicked from the settings dialog while a gameOver is showing:
  // We handle that in the restartGameButton click above, which hides loseMessage/winMessage
  restartGameButton.addEventListener("click", () => {
    const loseMessage = document.getElementById("loseMessage");
    const winMessage = document.getElementById("winMessage");
    if (loseMessage) loseMessage.style.display = "none";
    if (winMessage) winMessage.style.display = "none";
  });
});
EOF


########################################
# Overwrite js/uiManager.js
########################################
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

      // Listen for mouse move to update cursor
      this.game.canvas.addEventListener("mousemove", (e) => this.handleMouseMove(e));
    }
  
    initDebugTable() {
      this.debugTable.innerHTML = "";
      const towerData = this.game.towerManager.getTowerData();
      if (!towerData.length) return;
  
      const thead = document.createElement("thead");
      const headerRow = document.createElement("tr");
      headerRow.innerHTML = `
        <th></th>
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
  
    // Tower click area is the actual drawn radius
    getTowerAt(mx, my) {
      return this.game.towerManager.towers.find(t => {
        const drawRadius = 24 + t.level * 4;
        const dx = mx - t.x;
        const dy = my - t.y;
        return (dx*dx + dy*dy) <= (drawRadius*drawRadius);
      });
    }

    // Unoccupied tower spot clickable area = radius 20
    getTowerSpotAt(mx, my) {
      return this.game.towerSpots.find(s => {
        if (s.occupied) return false;
        const dx = mx - s.x;
        const dy = my - s.y;
        return (dx*dx + dy*dy) <= (20*20);
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
      const tower = this.getTowerAt(mx, my);
      if (tower) {
        return { type: "tower", tower };
      }
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
        // clicked empty space
        this.selectedEnemy = null;
        this.hideEnemyStats();
        this.hideTowerPanel();
        return;
      }
  
      if (entity.type === "towerSpot") {
        this.showNewTowerPanel(entity.spot, rect);
        return;
      }
      if (entity.type === "tower") {
        this.showExistingTowerPanel(entity.tower, rect);
        return;
      }
      if (entity.type === "enemy") {
        this.selectedEnemy = entity.enemy;
        this.showEnemyStats(entity.enemy);
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

      // Sell Tower button near top, smaller
      const sellBtn = document.createElement("button");
      sellBtn.textContent = "Sell Tower";
      sellBtn.style.display = "block";
      sellBtn.style.margin = "3px auto 6px auto";
      sellBtn.style.fontSize = "0.85em";
      sellBtn.style.padding = "2px 5px";
      sellBtn.addEventListener("click", () => {
        this.game.towerManager.sellTower(tower);
        this.hideTowerPanel();
      });
      this.towerSelectPanel.appendChild(sellBtn);
  
      // Round fireRate to 1 decimal place
      const currentFireRate = Math.round(tower.fireRate * 10) / 10;

      const currStats = document.createElement("div");
      currStats.innerHTML = `
        Level: ${tower.level}<br>
        Damage: ${tower.damage}<br>
        Fire Rate: ${currentFireRate.toFixed(1)}s
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

            // If we want the next level's rate to be (base - 0.2) or something:
            // For consistency, just do tower.fireRate * ??? or something.
            // We'll just do a simple 0.2 improvement for now:
            const nextRate = Math.round(Math.max(0.1, tower.fireRate - 0.2) * 10)/10;

            const nextStats = document.createElement("div");
            nextStats.innerHTML = `
              <hr>
              <strong>Next Level ${nextLevel}:</strong><br>
              Damage: ${nextDamage}<br>
              Fire Rate: ${nextRate.toFixed(1)}s<br>
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

        // Round fireRate to 1 decimal for display
        const displayRate = Math.round(def.fireRate * 10) / 10;

        const statsEl = document.createElement("div");
        statsEl.innerHTML = `DMG: ${def.upgrades[0].damage}<br>Rate: ${displayRate.toFixed(1)}s`;
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
      // Mark game over so it doesn't keep updating
      this.game.gameOver = true;
    }

    /**
     * Called by waveManager on final wave completion if we still have >0 lives
     */
    showWinDialog(finalLives, maxLives) {
      this.winMessageDiv.style.display = "block";
      // Mark game over
      this.game.gameOver = true;

      const starsDiv = this.winMessageDiv.querySelector("#winStars");
      let starCount = 1;
      if (finalLives >= 18) {
        starCount = 3;
      } else if (finalLives >= 10) {
        starCount = 2;
      }
      const starSymbols = [];
      for(let i=1; i<=3; i++){
        if (i <= starCount) starSymbols.push("★");
        else starSymbols.push("☆");
      }
      if(starsDiv) starsDiv.innerHTML = starSymbols.join(" ");
    }

    // Update mouse cursor to pointer if over tower or enemy
    handleMouseMove(e) {
      const rect = this.game.canvas.getBoundingClientRect();
      const mx = e.clientX - rect.left;
      const my = e.clientY - rect.top;
  
      const entity = this.getEntityUnderMouse(mx, my);
      if (entity && (entity.type === "tower" || entity.type === "enemy")) {
        this.game.canvas.style.cursor = "pointer";
      } else if (entity && entity.type === "towerSpot") {
        // Could also set to "pointer" if you want an indication for building
        this.game.canvas.style.cursor = "pointer";
      } else {
        this.game.canvas.style.cursor = "default";
      }
    }
}
EOF

########################################
# Commit and push
########################################
git add .
git commit -m "Settings dialog changes (heading, 2-col layout, smaller table text), enemy HP label, smaller HP toggle buttons, limit enemy image to 80px, round tower fire rate, fix 'You lost' reappearing by resetting game states on restart."
git push