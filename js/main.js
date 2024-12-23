import { Game } from "./game.js";
import { level1Data } from "./maps/level1.js";
import { UIManager } from "./uiManager.js";

let game = null;

// Helper for image loading
function preloadImage(src) {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.src = src;
    img.onload = () => resolve(img);
    img.onerror = reject;
  });
}

function preloadEnemies(types) {
  return Promise.all(
    types.map(async (type) => {
      const img = await preloadImage(type.src);
      const maxDim = 30;
      const scale = maxDim / Math.max(img.naturalWidth, img.naturalHeight);
      const w = Math.round(img.naturalWidth * scale);
      const h = Math.round(img.naturalHeight * scale);

      return {
        ...type,
        image: img,
        width: w,
        height: h,
        speed: 40,
      };
    })
  );
}

async function preloadBackground(src) {
  return preloadImage(src);
}

// Reusable function to start (or restart) the game with chosen gold
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

  // Preload enemies
  const enemyTypes = [
    { name: "drone",         src: "assets/enemies/drone.png" },
    { name: "leaf_blower",   src: "assets/enemies/leaf_blower.png" },
    { name: "trench_digger", src: "assets/enemies/trench_digger.png" },
    { name: "trench_walker", src: "assets/enemies/trench_walker.png" },
  ];
  const loadedTypes = await preloadEnemies(enemyTypes);

  // Preload background
  const bg = await preloadBackground(level1Data.background);

  // Configure game
  game.setEnemyTypes(loadedTypes);
  game.setLevelData(level1Data, bg);

  // Override starting gold here
  game.gold = startingGold;

  // Start
  game.start();
}

window.addEventListener("load", async () => {
  const startGoldInput = document.getElementById("startingGoldInput");
  const restartGameButton = document.getElementById("restartGameButton");

  // 1) Default (1000 in index.html) or user-supplied
  await startGameWithGold(parseInt(startGoldInput.value) || 1000);

  // 2) On "Restart Game", re-init with new gold
  restartGameButton.addEventListener("click", async () => {
    const desiredGold = parseInt(startGoldInput.value) || 0;
    await startGameWithGold(desiredGold);
  });
});