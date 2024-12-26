// test Dec 25 11:56 am
import { Game } from "./game.js";
import { level1Data } from "./maps/level1.js";
import { UIManager } from "./uiManager.js";
import { loadAllAssets } from "./assetLoader.js";

/**
 * Global parameters the user can set before starting the game:
 * - enemyHpPercent: 80% to 120%, default 100
 */
let enemyHpPercent = 100;

let game = null;

/**
 * Reusable function to start (or restart) the game with chosen gold.
 */
async function startGameWithGold(startingGold) {
  const canvas = document.getElementById("gameCanvas");
  const pauseBtn = document.getElementById("pauseButton");
  const sendWaveBtn = document.getElementById("sendWaveButton");
  const enemyStatsDiv = document.getElementById("enemyStats");
  const towerSelectPanel = document.getElementById("towerSelectPanel");
  const debugTableContainer = document.getElementById("debugTableContainer");
  const debugTable = document.getElementById("debugTable");
  const loseMessage = document.getElementById("loseMessage");
  const winMessage = document.getElementById("winMessage");

  // Clear any end-game messages
  loseMessage.style.display = "none";
  winMessage.style.display = "none";
  winMessage.querySelector("#winStars").innerHTML = "";

  // Create new Game
  game = new Game(
    canvas,
    sendWaveBtn,
    enemyStatsDiv,
    towerSelectPanel,
    debugTableContainer
  );

  // UI Manager
  const uiManager = new UIManager(game, enemyStatsDiv, towerSelectPanel, debugTable, loseMessage, winMessage);
  uiManager.initDebugTable();
  game.uiManager = uiManager;

  // This factor (0.8 -> 1.2) is applied on top of each enemy's normal HP
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

  // Provide loaded enemy assets to the EnemyManager
  game.enemyManager.setLoadedEnemyAssets(loadedEnemies);

  // Configure level data
  game.setLevelData(level1Data, loadedBackground);

  // Override starting gold
  game.gold = startingGold;

  // Start
  game.start();

  // Update the "current game" label
  const currentGameLabel = document.getElementById("currentGameLabel");
  currentGameLabel.textContent = `Current game: Starting gold: ${startingGold}, Enemy HP: ${enemyHpPercent}%`;
}

window.addEventListener("load", async () => {
  const startGoldInput = document.getElementById("startingGoldInput");
  const restartGameButton = document.getElementById("restartGameButton");
  const enemyHpButton = document.getElementById("enemyHpButton");

  // 1) Default or user-supplied gold
  await startGameWithGold(parseInt(startGoldInput.value) || 1000);

  // 2) On "Restart Game", re-init
  restartGameButton.addEventListener("click", async () => {
    const desiredGold = parseInt(startGoldInput.value) || 0;
    await startGameWithGold(desiredGold);
  });

  // 3) Enemy HP toggle (cycles 80->85->90-> ... ->120->80 etc.)
  const possibleHpValues = [];
  for(let v=80; v<=120; v+=5) {
    possibleHpValues.push(v);
  }
  let hpIndex = possibleHpValues.indexOf(100);
  enemyHpButton.addEventListener("click", () => {
    hpIndex = (hpIndex + 1) % possibleHpValues.length;
    enemyHpPercent = possibleHpValues[hpIndex];
    enemyHpButton.textContent = `Enemy HP: ${enemyHpPercent}%`;
  });
});
