import { Game } from "./game.js";
import { level1Data } from "./maps/level1.js";
import { UIManager } from "./uiManager.js";
import { loadAllAssets } from "./assetLoader.js";

/**
 * Global parameters the user can set before starting the game:
 * - enemyHpPercent: default 100 => now we use it as is (no 0.5 factor),
 *   effectively doubling HP from the previous code.
 */
let enemyHpPercent = 100;

let game = null;

/** Keep track of the last known startingGold so we can "Restart" easily. */
let lastStartingGold = 1000;

async function startGameWithGold(startingGold) {
  lastStartingGold = startingGold;

  const canvas = document.getElementById("gameCanvas");
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

  // Doubling from the old baseline => just use (enemyHpPercent / 100)
  game.globalEnemyHpMultiplier = (enemyHpPercent / 100);

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
  if (enemyHpSegment) enemyHpSegment.innerHTML = "";
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
    if (enemyHpSegment) enemyHpSegment.appendChild(btn);
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

  // Because we now have separate "Restart" + "Settings" in the game-over dialogs, wire them up here:
  const loseRestartBtn = document.getElementById("loseRestartBtn");
  const loseSettingsBtn = document.getElementById("loseSettingsBtn");
  const winRestartBtn  = document.getElementById("winRestartBtn");
  const winSettingsBtn = document.getElementById("winSettingsBtn");

  if (loseRestartBtn) {
    loseRestartBtn.addEventListener("click", async () => {
      // Hide lose dialog, restart game with existing gold
      document.getElementById("loseMessage").style.display = "none";
      await startGameWithGold(lastStartingGold);
    });
  }
  if (loseSettingsBtn) {
    loseSettingsBtn.addEventListener("click", () => {
      // Show settings, keep lose dialog behind it
      settingsDialog.style.zIndex = "10001";
      document.getElementById("loseMessage").style.zIndex = "10000";
      settingsDialog.style.display = "block";
    });
  }
  if (winRestartBtn) {
    winRestartBtn.addEventListener("click", async () => {
      // Hide win dialog, restart game
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
  // We can handle that the same as normal (the standard "Restart Game" button).
  // Once "Restart Game" is clicked, we hide both lose/win dialogs:
  restartGameButton.addEventListener("click", () => {
    document.getElementById("loseMessage").style.display = "none";
    document.getElementById("winMessage").style.display = "none";
  });
});
