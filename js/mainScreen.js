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
