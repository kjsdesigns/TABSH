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
