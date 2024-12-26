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
