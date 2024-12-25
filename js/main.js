// test Dec 25 11:56 am
import { Game } from "./game.js";
import { level1Data } from "./maps/level1.js";
import { UIManager } from "./uiManager.js";
import { loadAllAssets } from "./assetLoader.js";

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
  const debugToggle = document.getElementById("debugToggle");
  const debugTableContainer = document.getElementById("debugTableContainer");
  const debugTable = document.getElementById("debugTable");

  // Create new Game
  game = new Game(
    canvas,
    sendWaveBtn,
    enemyStatsDiv,
    towerSelectPanel,
    debugToggle,
    debugTableContainer
  );

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

  // Override starting gold
  game.gold = startingGold;

  // Start
  game.start();
}

window.addEventListener("load", async () => {
  const startGoldInput = document.getElementById("startingGoldInput");
  const restartGameButton = document.getElementById("restartGameButton");

  // 1) Default or user-supplied gold
  await startGameWithGold(parseInt(startGoldInput.value) || 1000);

  // 2) On "Restart Game", re-init
  restartGameButton.addEventListener("click", async () => {
    const desiredGold = parseInt(startGoldInput.value) || 0;
    await startGameWithGold(desiredGold);
  });
});