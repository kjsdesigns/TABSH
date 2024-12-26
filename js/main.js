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
