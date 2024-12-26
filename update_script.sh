#!/usr/bin/env bash

# OVERVIEW
# 1) Make the "Starting gold" label match the "Enemy HP" label size.
# 2) Make left column equal width to right column (50/50).
# 3) Insert a hard return between "Current game:" and the actual settings text so it appears on two lines.
# 4) Reduce the font size of the right column (tower stats) by 25%.

# We'll accomplish this by updating:
# - index.html (to add an ID to the starting gold label and ensure consistent DOM structure).
# - css/style.css (to apply column widths, label font sizes, and 75% font-size to the right column).
# - js/main.js (to insert a <br> after "Current game:" in the currentGameLabel).

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

    <!-- Settings dialog (hidden by default, 2-column layout) -->
    <div id="settingsDialog">
      <div id="settingsDialogClose">&#10006;</div>
      <h2 id="settingsHeading">Settings</h2>
      <div id="settingsDialogContent">
        <!-- LEFT column: current game info, enemy HP label & toggles, gold, restart -->
        <div id="settingsLeftColumn">
          <div id="currentGameLabel" class="smallInfoLabel"></div>
          <hr style="margin: 6px 0;" />

          <!-- "Enemy HP" label + segmented buttons -->
          <div id="enemyHpRow">
            <label id="enemyHpLabel">Enemy HP</label>
            <div id="enemyHpSegment"></div>
          </div>

          <!-- Starting gold + input -->
          <div id="startingGoldRow">
            <!-- Give this label an ID so we can style it the same as #enemyHpLabel -->
            <label id="startingGoldLabel" for="startingGoldInput">Starting gold</label>
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
    padding: 6px 10px;
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

/* Each column is 50% width so they are equal */
#settingsLeftColumn, #settingsRightColumn {
    width: 50%;
    box-sizing: border-box; /* ensure padding doesn't break the 50% layout */
}

/* Make the "Enemy HP" and "Starting gold" label consistent in styling */
#enemyHpLabel,
#startingGoldLabel {
    font-size: 12px;
    margin: 0;
    padding: 0;
}

/* The segmented HP buttons: smaller text, less padding */
.enemyHpOption {
    font-size: 10px;     
    padding: 3px 2px;    
    margin-right: 2px;
}

/* Debug table container + smaller text in table (by default 10px) */
#debugTableContainer {
    margin-top: 0;
    /* We'll reduce the entire right column's font size by 25% -> 0.75 scale */
    font-size: 0.75em;
}

#debugTable {
    border-collapse: collapse;
    border: 1px solid #999;
    width: 100%;
}

#debugTable th,
#debugTable td {
    padding: 4px 8px;
    border: 1px solid #666;
}

/* small label */
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

  // Update current game label with a hard return after "Current game:"
  const currentGameLabel = document.getElementById("currentGameLabel");
  if (currentGameLabel) {
    currentGameLabel.innerHTML = `Current game:<br>Starting gold: ${startingGold}, Enemy HP: ${enemyHpPercent}%`;
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
      // If it's the current selection, highlight
      if (value === enemyHpPercent) {
        btn.style.backgroundColor = "#444";
      }
      btn.addEventListener("click", () => {
        // Clear old highlights
        document.querySelectorAll(".enemyHpOption").forEach(b => {
          b.style.backgroundColor = "";
        });
        // Mark new selection
        enemyHpPercent = value;
        btn.style.backgroundColor = "#444";
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
# Commit and push
########################################
git add .
git commit -m "Match label sizes, make columns 50/50, add line break in current game label, reduce right column font-size by 25%."
git push