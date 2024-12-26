#!/usr/bin/env bash

# --- Create/Overwrite js/data/towerConfig.js ---
cat << 'EOF' > js/data/towerConfig.js
/**
 * towerConfig.js
 * 
 * We extracted the tower definitions from towerManager.js to reduce redundancy
 * and allow for easy extension or balancing of tower stats without changing logic code.
 */

export const TOWER_DEFINITIONS = [
  {
    type: "point",
    basePrice: 80,
    range: 169,
    splashRadius: 0,
    fireRate: 1.5 * 0.8, // originally 1.5, but we apply a 20% speed-up => 1.2
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
    fireRate: 1.5 * 0.8, // 1.2
    upgrades: [
      { level: 1, damage: 8,  upgradeCost: 0   },
      { level: 2, damage: 12, upgradeCost: 50  },
      { level: 3, damage: 16, upgradeCost: 100 },
      { level: 4, damage: 20, upgradeCost: 150 },
    ],
  },
];
EOF

# --- Create/Overwrite js/maps/level2.js ---
cat << 'EOF' > js/maps/level2.js
export const level2Data = {
  // For now, same background as level1
  background: "assets/maps/level1.png",
  mapWidth: 3530,
  mapHeight: 2365,
  path: [
    { x: 420,  y: 0    },
    { x: 800,  y: 860  },
    { x: 1300, y: 1550 },
    { x: 1500, y: 1750 },
    { x: 1950, y: 1920 },
    { x: 3530, y: 1360 },
  ],
  towerSpots: [
    { x: 1020, y: 660  },
    { x: 620,  y: 1280 },
    { x: 1340, y: 1080 },
    { x: 1020, y: 1660 },
    { x: 1800, y: 1560 },
    { x: 2080, y: 2150 },
    { x: 3250, y: 1150 },
  ],
  waves: [
    // We’ll just replicate the same wave definitions for demonstration
    {
      enemyGroups: [
        { type: "drone", count: 5, spawnInterval: 800, hpMultiplier: 1.0 },
      ],
    },
    {
      enemyGroups: [
        { type: "drone", count: 3, spawnInterval: 700, hpMultiplier: 1.1 },
        { type: "leaf_blower", count: 2, spawnInterval: 1200, hpMultiplier: 1.1 },
      ],
    },
    {
      enemyGroups: [
        { type: "leaf_blower", count: 4, spawnInterval: 1000, hpMultiplier: 1.2 },
        { type: "drone", count: 3, spawnInterval: 700, hpMultiplier: 1.2 },
      ],
    },
    {
      enemyGroups: [
        { type: "trench_digger", count: 4, spawnInterval: 900, hpMultiplier: 1.3 },
        { type: "drone", count: 4, spawnInterval: 600, hpMultiplier: 1.3 },
      ],
    },
    {
      enemyGroups: [
        { type: "trench_digger", count: 5, spawnInterval: 800, hpMultiplier: 1.4 },
        { type: "leaf_blower", count: 4, spawnInterval: 1200, hpMultiplier: 1.4 },
      ],
    },
    {
      enemyGroups: [
        { type: "trench_walker", count: 3, spawnInterval: 1200, hpMultiplier: 1.5 },
        { type: "drone", count: 4, spawnInterval: 600, hpMultiplier: 1.5 },
      ],
    },
    {
      enemyGroups: [
        { type: "trench_walker", count: 4, spawnInterval: 1200, hpMultiplier: 1.6 },
        { type: "leaf_blower", count: 3, spawnInterval: 900, hpMultiplier: 1.6 },
      ],
    },
    {
      enemyGroups: [
        { type: "drone", count: 6, spawnInterval: 600, hpMultiplier: 1.7 },
        { type: "leaf_blower", count: 4, spawnInterval: 900, hpMultiplier: 1.7 },
        { type: "trench_digger", count: 2, spawnInterval: 800, hpMultiplier: 1.7 },
      ],
    },
    {
      enemyGroups: [
        { type: "trench_digger", count: 5, spawnInterval: 700, hpMultiplier: 1.8 },
        { type: "trench_walker", count: 3, spawnInterval: 1300, hpMultiplier: 1.8 },
      ],
    },
    {
      enemyGroups: [
        { type: "trench_walker", count: 6, spawnInterval: 1000, hpMultiplier: 1.9 },
        { type: "leaf_blower", count: 5, spawnInterval: 1000, hpMultiplier: 1.9 },
      ],
    },
  ],
};
EOF

# --- Create/Overwrite js/mainScreen.js ---
cat << 'EOF' > js/mainScreen.js
/**
 * mainScreen.js
 *
 * Controls the "Main Screen" UI, including:
 * - Game slot selection (persisted in localStorage)
 * - Display of level 1 and level 2 (level 2 is locked until >=1 star on level1)
 * - Dotted line between level1 and level2
 * - Placeholders for tower upgrades, heroes, items
 * - Hero selection (2 heroes: "Melee Hero" & "Archer Hero")
 */

const MAX_SLOTS = 3;

// We'll store data in localStorage under keys like "kr_slot1", "kr_slot2", etc.
// Each slot data might look like:
// {
//   currentStars: { level1: 3, level2: 2 }, // or 0 if not yet done
//   selectedHero: "melee" or "archer"
// }

function loadSlotData(slotIndex) {
  const key = "kr_slot" + slotIndex;
  const raw = localStorage.getItem(key);
  if (raw) {
    return JSON.parse(raw);
  } else {
    return {
      currentStars: {},
      selectedHero: null,
    };
  }
}

function saveSlotData(slotIndex, data) {
  localStorage.setItem("kr_slot" + slotIndex, JSON.stringify(data));
}

// ----------- PUBLIC API -----------
export function initMainScreen() {
  const slotButtonsContainer = document.getElementById("slotButtonsContainer");
  if (!slotButtonsContainer) return;

  // Build slot buttons
  for (let i = 1; i <= MAX_SLOTS; i++) {
    const btn = document.createElement("button");
    btn.textContent = "Slot " + i;
    btn.addEventListener("click", () => {
      // set active slot in localStorage for quick reference
      localStorage.setItem("kr_activeSlot", String(i));
      updateMainScreenDisplay();
    });
    slotButtonsContainer.appendChild(btn);
  }

  // Hook up hero selection dialog
  const heroesButton = document.getElementById("heroesButton");
  const heroDialog = document.getElementById("heroDialog");
  const heroDialogClose = document.getElementById("heroDialogClose");
  const meleeHeroBtn = document.getElementById("meleeHeroBtn");
  const archerHeroBtn = document.getElementById("archerHeroBtn");

  if (heroesButton) {
    heroesButton.addEventListener("click", () => {
      heroDialog.style.display = "block";
    });
  }
  if (heroDialogClose) {
    heroDialogClose.addEventListener("click", () => {
      heroDialog.style.display = "none";
    });
  }
  if (meleeHeroBtn) {
    meleeHeroBtn.addEventListener("click", () => setSelectedHero("melee"));
  }
  if (archerHeroBtn) {
    archerHeroBtn.addEventListener("click", () => setSelectedHero("archer"));
  }

  // Hook up level buttons
  const level1Btn = document.getElementById("level1Btn");
  const level2Btn = document.getElementById("level2Btn");
  if (level1Btn) {
    level1Btn.addEventListener("click", () => chooseLevel("level1"));
  }
  if (level2Btn) {
    level2Btn.addEventListener("click", () => chooseLevel("level2"));
  }

  // Initial update
  updateMainScreenDisplay();
}

// Let main.js call this after a level is completed
export function unlockStars(levelId, starCount) {
  const slotIndex = localStorage.getItem("kr_activeSlot") || "1";
  const slotData = loadSlotData(slotIndex);
  const oldStars = slotData.currentStars[levelId] || 0;
  // Only keep the maximum
  if (starCount > oldStars) {
    slotData.currentStars[levelId] = starCount;
  }
  saveSlotData(slotIndex, slotData);
  updateMainScreenDisplay();
}

function setSelectedHero(heroType) {
  const slotIndex = localStorage.getItem("kr_activeSlot") || "1";
  const slotData = loadSlotData(slotIndex);
  slotData.selectedHero = heroType;
  saveSlotData(slotIndex, slotData);

  const heroDialog = document.getElementById("heroDialog");
  if (heroDialog) heroDialog.style.display = "none";
  updateMainScreenDisplay();
}

function updateMainScreenDisplay() {
  const slotIndex = localStorage.getItem("kr_activeSlot") || "1";
  const slotData = loadSlotData(slotIndex);

  // Show the current slot
  const currentSlotLabel = document.getElementById("currentSlotLabel");
  if (currentSlotLabel) {
    currentSlotLabel.textContent = "Current Slot: " + slotIndex;
  }

  // Show star counts
  const level1Stars = slotData.currentStars["level1"] || 0;
  const level2Stars = slotData.currentStars["level2"] || 0;
  const level1StarDisplay = document.getElementById("level1StarDisplay");
  const level2StarDisplay = document.getElementById("level2StarDisplay");
  if (level1StarDisplay) {
    level1StarDisplay.textContent = "Stars: " + level1Stars;
  }
  if (level2StarDisplay) {
    level2StarDisplay.textContent = "Stars: " + level2Stars;
  }

  // Lock/unlock level 2 if level1Stars >= 1
  const level2Btn = document.getElementById("level2Btn");
  const dottedLineElem = document.getElementById("dottedLine");
  if (level2Btn && dottedLineElem) {
    if (level1Stars >= 1) {
      level2Btn.disabled = false;
      dottedLineElem.style.opacity = "1";
    } else {
      level2Btn.disabled = true;
      dottedLineElem.style.opacity = "0.3";
    }
  }

  // Show selected hero
  const selectedHeroLabel = document.getElementById("selectedHeroLabel");
  if (selectedHeroLabel) {
    selectedHeroLabel.textContent = "Hero: " + (slotData.selectedHero || "None");
  }
}

// Called when user chooses a level from main screen
function chooseLevel(levelId) {
  localStorage.setItem("kr_chosenLevel", levelId);
  // Hide main screen, show game container
  const mainScreen = document.getElementById("mainScreen");
  const gameContainer = document.getElementById("gameContainer");
  if (mainScreen && gameContainer) {
    mainScreen.style.display = "none";
    gameContainer.style.display = "block";
  }
  // Now main.js will read localStorage for chosen level and start the game
  // We can just dispatch an event or let main.js poll on next StartGame
  // For simplicity, we can force main.js to re-init the game:
  if (window.startGameFromMainScreen) {
    window.startGameFromMainScreen();
  }
}
EOF

# --- Create/Overwrite js/heroManager.js ---
cat << 'EOF' > js/heroManager.js
/**
 * heroManager.js
 * 
 * Basic approach for a single hero:
 * - Hero is placed near path[0]
 * - Moves toward nearest enemy within range, or stands idle if none
 * - Attack is a placeholder
 */

export class HeroManager {
  constructor(game, heroType) {
    this.game = game;
    this.heroType = heroType || "melee";
    // Basic hero stats, vary by type
    if (this.heroType === "archer") {
      this.range = 150;
      this.damage = 10;
      this.speed = 100; // moves faster
    } else {
      // melee
      this.range = 50;
      this.damage = 15;
      this.speed = 70;
    }
    this.x = 0;
    this.y = 0;
    this.w = 24;
    this.h = 24;

    // Quick approach: place hero at path start
    if (game.path && game.path.length > 0) {
      this.x = game.path[0].x;
      this.y = game.path[0].y;
    }

    this.targetEnemy = null;
    this.attackCooldown = 0;
    this.attackRate = 1.5; // 1 attack every 1.5 seconds
  }

  update(deltaSec) {
    if (!this.game.enemies.length) {
      // no enemies => stand still
      this.targetEnemy = null;
      return;
    }

    // find or confirm target
    if (!this.targetEnemy || this.targetEnemy.dead) {
      this.targetEnemy = this.findClosestEnemy();
    }

    // if we have a target
    if (this.targetEnemy) {
      // move to it if not in range
      const ex = this.targetEnemy.x;
      const ey = this.targetEnemy.y;
      const dx = ex - this.x;
      const dy = ey - this.y;
      const dist = Math.sqrt(dx*dx + dy*dy);

      if (dist > this.range) {
        // approach
        const step = this.speed * deltaSec;
        if (dist <= step) {
          this.x = ex;
          this.y = ey;
        } else {
          this.x += (dx/dist) * step;
          this.y += (dy/dist) * step;
        }
      } else {
        // in range => attack
        this.attackCooldown -= deltaSec;
        if (this.attackCooldown <= 0) {
          this.targetEnemy.hp -= this.damage;
          this.attackCooldown = this.attackRate;
        }
      }
    }
  }

  findClosestEnemy() {
    let bestEnemy = null;
    let bestDist = 999999;
    this.game.enemies.forEach(e => {
      if (!e.dead) {
        const dx = e.x - this.x;
        const dy = e.y - this.y;
        const dist = Math.sqrt(dx*dx + dy*dy);
        if (dist < bestDist) {
          bestDist = dist;
          bestEnemy = e;
        }
      }
    });
    return bestEnemy;
  }

  draw(ctx) {
    // For now, a simple placeholder circle
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.w / 2, 0, Math.PI * 2);
    ctx.fillStyle = (this.heroType === "archer") ? "orange" : "purple";
    ctx.fill();

    // For debugging, can show a range circle
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.range, 0, Math.PI * 2);
    ctx.strokeStyle = "rgba(255,255,0,0.3)";
    ctx.stroke();
  }
}
EOF

# --- Overwrite index.html ---
cat << 'EOF' > index.html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>My Tower Defense</title>
    <link rel="stylesheet" type="text/css" href="css/style.css">
    <style>
      /* Additional styles for main screen layout */
      #mainScreen {
        display: block;
        position: relative;
        width: 100%;
        height: 90vh;
        background: #222;
        color: #fff;
        padding: 10px;
      }

      #slotButtonsContainer {
        margin-bottom: 10px;
      }

      .levelButton {
        width: 120px;
        height: 120px;
        border-radius: 60px;
        text-align: center;
        vertical-align: middle;
        line-height: 120px;
        font-size: 1.2em;
        cursor: pointer;
        background: #444;
        color: #fff;
        border: 2px solid #999;
        margin-right: 30px;
      }
      .levelButton:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }

      /* Show a dotted line from level1 to level2 */
      #dottedLine {
        position: absolute;
        width: 100px;
        height: 2px;
        background: repeating-linear-gradient(to right, #fff 0, #fff 10px, transparent 10px, transparent 20px);
        top: 250px;
        left: 330px;
        transform: rotate(10deg);
        transform-origin: 0 0;
        opacity: 0.3;
      }

      /* Bottom-right placeholders */
      #bottomRightButtons {
        position: absolute;
        bottom: 20px;
        right: 20px;
        display: flex;
        flex-direction: column;
        gap: 8px;
      }
      .placeholderBtn {
        padding: 6px 10px;
        background: #333;
        border: 1px solid #555;
        color: #fff;
        cursor: pointer;
      }

      /* Hero selection dialog */
      #heroDialog {
        display: none;
        position: fixed;
        top: 50%;
        left: 50%;
        width: 400px;
        background: rgba(0,0,0,0.85);
        border: 2px solid #999;
        border-radius: 8px;
        transform: translate(-50%, -50%);
        z-index: 9999;
        padding: 10px;
      }
      #heroDialogClose {
        float: right;
        cursor: pointer;
        margin-bottom: 10px;
      }
      #heroDialog h2 {
        margin: 0 0 10px 0;
      }
      .heroChoice {
        margin: 5px 0;
      }
    </style>
  </head>
  <body>
    <!-- MAIN SCREEN -->
    <div id="mainScreen">
      <div id="slotButtonsContainer"></div>
      <div id="currentSlotLabel"></div>
      <div id="selectedHeroLabel"></div>

      <!-- LEVEL SELECT UI -->
      <div style="margin-top:30px;">
        <!-- Level 1 button -->
        <button id="level1Btn" class="levelButton" style="position:absolute; top:200px; left:200px;">
          L1
        </button>
        <div id="level1StarDisplay" style="position:absolute; top:330px; left:200px; color:#ff0;"></div>

        <div id="dottedLine"></div>

        <!-- Level 2 button -->
        <button id="level2Btn" class="levelButton" style="position:absolute; top:220px; left:420px;">
          L2
        </button>
        <div id="level2StarDisplay" style="position:absolute; top:350px; left:420px; color:#ff0;"></div>
      </div>

      <!-- BOTTOM-RIGHT Placeholders -->
      <div id="bottomRightButtons">
        <button id="upgradeButton" class="placeholderBtn">Tower Upgrades</button>
        <button id="heroesButton" class="placeholderBtn">Heroes</button>
        <button id="itemsButton" class="placeholderBtn">Items</button>
      </div>

      <!-- Hero Selection Dialog -->
      <div id="heroDialog">
        <div id="heroDialogClose">&#10006;</div>
        <h2>Select Your Hero</h2>
        <div class="heroChoice">
          <button id="meleeHeroBtn">Melee Hero</button>
        </div>
        <div class="heroChoice">
          <button id="archerHeroBtn">Archer Hero</button>
        </div>
      </div>
    </div>

    <!-- GAME SCREEN (hidden by default, same as original) -->
    <div id="gameContainer" style="display:none;">
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

    <!-- Settings dialog (hidden by default, 2-column layout) -->
    <div id="settingsDialog">
      <div id="settingsDialogClose">&#10006;</div>
      <h2 id="settingsHeading">Settings</h2>
      <div id="settingsDialogContent">
        <!-- LEFT column: current game info, enemy HP label & toggles, gold, restart -->
        <div id="settingsLeftColumn">
          <div id="currentGameLabel" class="smallInfoLabel"></div>
          <hr style="margin: 6px 0;" />
          <div id="enemyHpRow">
            <label id="enemyHpLabel">Enemy HP</label>
            <div id="enemyHpSegment"></div>
          </div>
          <div id="startingGoldRow">
            <label id="startingGoldLabel" for="startingGoldInput">Starting gold</label>
            <input type="number" id="startingGoldInput" value="1000" />
          </div>
          <button id="restartGameButton" class="actionButton" style="margin-top: 10px;">
            Restart Game
          </button>
          <!-- NEW: back to main screen -->
          <button id="backToMainButton" class="actionButton" style="margin-top: 10px;">
            Back to Main
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

    <!-- Original main.js replaced with the new approach below -->
    <script type="module" src="./js/mainScreen.js"></script>
    <script type="module" src="./js/main.js"></script>
  </body>
</html>
EOF

# --- Overwrite js/main.js ---
cat << 'EOF' > js/main.js
import { Game } from "./game.js";
import { level1Data } from "./maps/level1.js";
import { level2Data } from "./maps/level2.js";
import { UIManager } from "./uiManager.js";
import { loadAllAssets } from "./assetLoader.js";
import { initMainScreen, unlockStars } from "./mainScreen.js";

/**
 * main.js
 *
 * Adjusted to:
 * 1) Initialize the main screen.
 * 2) Check localStorage for chosen level & hero whenever we actually start a game.
 * 3) When a level finishes, use unlockStars() from mainScreen.js to store star rating.
 */

let enemyHpPercent = 100;
let game = null;
let lastStartingGold = 1000;
let currentLevelData = null;
let currentLevelName = null; // "level1" or "level2"
let currentHeroType = null;  // "melee" or "archer" or null

// Called by mainScreen after the user chooses a level
window.startGameFromMainScreen = async function() {
  const chosenLevel = localStorage.getItem("kr_chosenLevel") || "level1";
  currentLevelName = chosenLevel;

  // Check hero
  const slotIndex = localStorage.getItem("kr_activeSlot") || "1";
  const slotDataRaw = localStorage.getItem("kr_slot" + slotIndex);
  let slotData = null;
  try {
    slotData = JSON.parse(slotDataRaw);
  } catch(e) {
    slotData = { selectedHero: null };
  }
  currentHeroType = slotData.selectedHero || null;

  if (chosenLevel === "level2") {
    currentLevelData = level2Data;
  } else {
    currentLevelData = level1Data;
  }

  // Start the game
  const startGoldInput = document.getElementById("startingGoldInput");
  const desiredGold = parseInt(startGoldInput.value) || 1000;
  await startGameWithGold(desiredGold);
};

async function startGameWithGold(startingGold) {
  lastStartingGold = startingGold;

  // Hide lose/win
  const loseMessage = document.getElementById("loseMessage");
  const winMessage = document.getElementById("winMessage");
  if (loseMessage) loseMessage.style.display = "none";
  if (winMessage) winMessage.style.display = "none";

  const canvas = document.getElementById("gameCanvas");
  const enemyStatsDiv = document.getElementById("enemyStats");
  const towerSelectPanel = document.getElementById("towerSelectPanel");
  const debugTableContainer = document.getElementById("debugTableContainer");

  game = new Game(canvas, enemyStatsDiv, towerSelectPanel, debugTableContainer);

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

  // Enemy HP multiplier
  game.globalEnemyHpMultiplier = enemyHpPercent / 100;

  // Load images / assets
  const enemyTypes = [
    { name: "drone",         src: "assets/enemies/drone.png" },
    { name: "leaf_blower",   src: "assets/enemies/leaf_blower.png" },
    { name: "trench_digger", src: "assets/enemies/trench_digger.png" },
    { name: "trench_walker", src: "assets/enemies/trench_walker.png" },
  ];

  const { loadedEnemies, loadedBackground } = await loadAllAssets(
    enemyTypes,
    currentLevelData.background
  );
  game.enemyManager.setLoadedEnemyAssets(loadedEnemies);
  game.setLevelData(currentLevelData, loadedBackground);

  // If we have a heroType, set up a hero
  if (currentHeroType) {
    // Let the HeroManager be created in game
    game.createHero(currentHeroType);
  }

  game.gold = startingGold;
  game.start();

  // Update label
  const currentGameLabel = document.getElementById("currentGameLabel");
  if (currentGameLabel) {
    currentGameLabel.innerHTML = `Current game:<br>Level: ${currentLevelName}, Starting gold: ${startingGold}, Enemy HP: ${enemyHpPercent}%`;
  }
}

// On load, just init the main screen
window.addEventListener("load", async () => {
  initMainScreen();

  // Hook up "Restart game" from settings
  const restartGameButton = document.getElementById("restartGameButton");
  if (restartGameButton) {
    restartGameButton.addEventListener("click", async () => {
      const goldInput = document.getElementById("startingGoldInput");
      const gold = parseInt(goldInput.value) || 1000;
      await startGameWithGold(gold);
    });
  }

  // "Back to main" button
  const backToMainButton = document.getElementById("backToMainButton");
  if (backToMainButton) {
    backToMainButton.addEventListener("click", () => {
      // Hide game, show main
      const mainScreen = document.getElementById("mainScreen");
      const gameContainer = document.getElementById("gameContainer");
      if (mainScreen && gameContainer) {
        gameContainer.style.display = "none";
        mainScreen.style.display = "block";
      }
    });
  }

  // Settings dialog references
  const settingsDialog = document.getElementById("settingsDialog");
  const settingsButton = document.getElementById("settingsButton");
  const settingsDialogClose = document.getElementById("settingsDialogClose");
  if (settingsButton) {
    settingsButton.addEventListener("click", () => {
      const style = settingsDialog.style.display;
      settingsDialog.style.display = (style === "none" || style === "") ? "block" : "none";
    });
  }
  if (settingsDialogClose) {
    settingsDialogClose.addEventListener("click", () => {
      settingsDialog.style.display = "none";
    });
  }

  // Enemy HP segmented options
  const enemyHpSegment = document.getElementById("enemyHpSegment");
  if (enemyHpSegment) {
    enemyHpSegment.innerHTML = "";
    const hpOptions = [];
    for (let v = 80; v <= 120; v += 5) {
      hpOptions.push(v);
    }
    hpOptions.forEach(value => {
      const btn = document.createElement("button");
      btn.textContent = value + "%";
      btn.classList.add("enemyHpOption");
      if (value === enemyHpPercent) {
        btn.style.backgroundColor = "#444";
      }
      btn.addEventListener("click", () => {
        document.querySelectorAll(".enemyHpOption").forEach(b => {
          b.style.backgroundColor = "";
        });
        enemyHpPercent = value;
        btn.style.backgroundColor = "#444";
      });
      enemyHpSegment.appendChild(btn);
    });
  }

  // If user restarts from lose/win
  const loseRestartBtn = document.getElementById("loseRestartBtn");
  if (loseRestartBtn) {
    loseRestartBtn.addEventListener("click", async () => {
      document.getElementById("loseMessage").style.display = "none";
      const goldInput = document.getElementById("startingGoldInput");
      await startGameWithGold(parseInt(goldInput.value) || 1000);
    });
  }
  const loseSettingsBtn = document.getElementById("loseSettingsBtn");
  if (loseSettingsBtn) {
    loseSettingsBtn.addEventListener("click", () => {
      settingsDialog.style.zIndex = "10001";
      document.getElementById("loseMessage").style.zIndex = "10000";
      settingsDialog.style.display = "block";
    });
  }
  const winRestartBtn = document.getElementById("winRestartBtn");
  if (winRestartBtn) {
    winRestartBtn.addEventListener("click", async () => {
      document.getElementById("winMessage").style.display = "none";
      const goldInput = document.getElementById("startingGoldInput");
      await startGameWithGold(parseInt(goldInput.value) || 1000);
    });
  }
  const winSettingsBtn = document.getElementById("winSettingsBtn");
  if (winSettingsBtn) {
    winSettingsBtn.addEventListener("click", () => {
      settingsDialog.style.zIndex = "10001";
      document.getElementById("winMessage").style.zIndex = "10000";
      settingsDialog.style.display = "block";
    });
  }

});
 
// We'll expose a function for awarding stars:
export function awardStars(starCount) {
  // starCount can be 1,2,3
  if (!currentLevelName) return;
  unlockStars(currentLevelName, starCount);
}
EOF

# --- Overwrite js/towerManager.js ---
cat << 'EOF' > js/towerManager.js
import { TOWER_DEFINITIONS } from "./data/towerConfig.js";

export class TowerManager {
  constructor(game) {
    this.game = game;
    this.towers = [];
    this.projectiles = [];

    // We no longer embed tower data here; we import from TOWER_DEFINITIONS
    this.towerTypes = TOWER_DEFINITIONS;
  }

  getTowerData() {
    return this.towerTypes;
  }

  createTower(towerTypeName) {
    const def = this.towerTypes.find(t => t.type === towerTypeName);
    if (!def) return null;

    const firstLvl = def.upgrades[0];
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
      goldSpent: def.basePrice,
    };
  }

  update(deltaSec) {
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
    if (tower.level >= def.upgrades.length) return;

    const nextLvlIndex = tower.level;
    const nextLvl = def.upgrades[nextLvlIndex];
    if (!nextLvl) return;
    if (this.game.gold < nextLvl.upgradeCost) return;

    // Spend gold
    this.game.gold -= nextLvl.upgradeCost;
    tower.goldSpent += nextLvl.upgradeCost;
    tower.level++;

    tower.damage = nextLvl.damage;
    tower.upgradeCost = def.upgrades[tower.level]
      ? def.upgrades[tower.level].upgradeCost
      : 0;
  }

  sellTower(tower) {
    const refund = Math.floor(tower.goldSpent * 0.8);
    this.game.gold += refund;
    this.towers = this.towers.filter(t => t !== tower);
    if (tower.spot) tower.spot.occupied = false;
  }

  drawTowers(ctx) {
    this.towers.forEach(t => {
      const drawRadius = 24 + t.level * 4;
      ctx.beginPath();
      ctx.arc(t.x, t.y, drawRadius, 0, Math.PI * 2);
      ctx.fillStyle = (t.type === "point") ? "blue" : "red";
      ctx.fill();
      ctx.strokeStyle = "#fff";
      ctx.stroke();

      // optional range circle
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

# --- Overwrite js/game.js ---
cat << 'EOF' > js/game.js
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

    // hero manager is created dynamically if hero is chosen
    this.heroManager = null;

    this.lastTime = 0;
    this.debugMode = true;

    // Pause/Resume
    const pauseBtn = document.getElementById("pauseButton");
    pauseBtn.innerHTML = "&#9658;";
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

    // Speed toggle
    const speedBtn = document.getElementById("speedToggleButton");
    speedBtn.addEventListener("click", () => {
      this.speedIndex = (this.speedIndex + 1) % this.speedOptions.length;
      this.gameSpeed = this.speedOptions[this.speedIndex];
      speedBtn.textContent = this.gameSpeed + "x";
    });

    // canvas click
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

  createHero(heroType) {
    this.heroManager = new HeroManager(this, heroType);
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
      if (this.heroManager) {
        this.heroManager.update(deltaSec);
      }
    }
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

    // Hero
    if (this.heroManager) {
      this.heroManager.draw(this.ctx);
    }

    // Tower spots (debug)
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

# --- Overwrite js/waveManager.js ---
cat << 'EOF' > js/waveManager.js
import { awardStars } from "./main.js";

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
    if (!this.waveActive && this.waveIndex < this.waves.length) {
      this.timeUntilNextWave -= deltaSec;
      if (this.timeUntilNextWave <= 0) {
        this.startWave(this.waveIndex);
      }
    }

    if (this.waveActive) {
      const waveInfo = this.waves[this.waveIndex];
      const allSpawned = waveInfo.enemyGroups.every(g => g.spawnedCount >= g.count);
      if (allSpawned && this.game.enemies.length === 0) {
        // wave done
        this.waveActive = false;
        this.waveIndex++;

        if (this.waveIndex >= this.waves.length) {
          // last wave done
          if (this.game.lives > 0 && this.game.uiManager) {
            this.game.paused = true;
            this.game.uiManager.showWinDialog(this.game.lives, this.game.maxLives);
            // Suppose we do a star rating calculation
            // e.g. if you have >= 18 lives => 3 stars, >=10 => 2 stars, else 1 star
            let starCount = 1;
            if (this.game.lives >= 18) starCount = 3;
            else if (this.game.lives >= 10) starCount = 2;
            awardStars(starCount);
          }
        } else {
          this.timeUntilNextWave = 0;
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

# 2) Commit and push
git add .
git commit -m "Add second level, main screen (slots/heroes), hero logic, refactor tower data, and redundancy fixes"
git push
EOF

echo "Script generation complete. Copy and run this script in your project root to apply changes."