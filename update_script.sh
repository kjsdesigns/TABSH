#!/usr/bin/env bash

# Create directories if needed (following your updated instructions)
mkdir -p js/data

######################################
# Overwrite index.html
######################################
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
          <!-- existing back to main -->
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
        <button id="loseSettingsBtn" class="actionButton" style="margin-right: 10px;">Settings</button>
        <!-- New: back to main -->
        <button id="loseMainBtn" class="actionButton">Back to main</button>
      </div>
    </div>

    <!-- Win message -->
    <div id="winMessage">
      <h1 style="font-size: 3em; margin: 0;">You win!</h1>
      <div id="winStars" style="font-size: 4em; color: gold; margin-top: 10px;"></div>
      <div style="margin-top: 10px;">
        <button id="winRestartBtn" class="actionButton" style="margin-right: 10px;">Restart</button>
        <button id="winSettingsBtn" class="actionButton" style="margin-right: 10px;">Settings</button>
        <!-- New: back to main -->
        <button id="winMainBtn" class="actionButton">Back to main</button>
      </div>
    </div>

    <!-- Scripts -->
    <script type="module" src="./js/mainScreen.js"></script>
    <script type="module" src="./js/main.js"></script>
  </body>
</html>
EOF

######################################
# Overwrite js/main.js
######################################
cat << 'EOF' > js/main.js
import { Game } from "./game.js";
import { level1Data } from "./maps/level1.js";
import { level2Data } from "./maps/level2.js";
import { UIManager } from "./uiManager.js";
import { loadAllAssets } from "./assetLoader.js";
import { initMainScreen, unlockStars } from "./mainScreen.js";

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

  // "Restart game" from settings
  const restartGameButton = document.getElementById("restartGameButton");
  if (restartGameButton) {
    restartGameButton.addEventListener("click", async () => {
      const goldInput = document.getElementById("startingGoldInput");
      const gold = parseInt(goldInput.value) || 1000;
      await startGameWithGold(gold);
    });
  }

  // "Back to main" button in settings
  const backToMainButton = document.getElementById("backToMainButton");
  if (backToMainButton) {
    backToMainButton.addEventListener("click", () => {
      // Hide game, show main
      const loseMessage = document.getElementById("loseMessage");
      const winMessage = document.getElementById("winMessage");
      if (loseMessage) loseMessage.style.display = "none";
      if (winMessage) winMessage.style.display = "none";

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

  // "Back to main" in lose dialog
  const loseMainBtn = document.getElementById("loseMainBtn");
  if (loseMainBtn) {
    loseMainBtn.addEventListener("click", () => {
      document.getElementById("loseMessage").style.display = "none";
      const mainScreen = document.getElementById("mainScreen");
      const gameContainer = document.getElementById("gameContainer");
      if (mainScreen && gameContainer) {
        gameContainer.style.display = "none";
        mainScreen.style.display = "block";
      }
    });
  }

  // Win logic
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

  // "Back to main" in win dialog
  const winMainBtn = document.getElementById("winMainBtn");
  if (winMainBtn) {
    winMainBtn.addEventListener("click", () => {
      document.getElementById("winMessage").style.display = "none";
      const mainScreen = document.getElementById("mainScreen");
      const gameContainer = document.getElementById("gameContainer");
      if (mainScreen && gameContainer) {
        gameContainer.style.display = "none";
        mainScreen.style.display = "block";
      }
    });
  }
});
 
// We'll expose a function for awarding stars:
export function awardStars(starCount) {
  if (!currentLevelName) return;
  unlockStars(currentLevelName, starCount);
}
EOF

# Now commit and push
git add .
git commit -m "Add back-to-main buttons in lose/win dialogs and hide dialogs on click"
git push