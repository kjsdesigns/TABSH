export class UIManager {
    constructor(game, enemyStatsDiv, towerSelectPanel, debugTable) {
      this.game = game;
      this.enemyStatsDiv = enemyStatsDiv;
      this.towerSelectPanel = towerSelectPanel;
      this.debugTable = debugTable;
  
      // Elements inside enemyStatsDiv
      this.enemyImage    = document.getElementById("enemyImage");
      this.enemyNameEl   = document.getElementById("enemyName");
      this.enemyHpEl     = document.getElementById("enemyHp");
      this.enemySpeedEl  = document.getElementById("enemySpeed");
      this.enemyGoldEl   = document.getElementById("enemyGold");
  
      this.selectedEnemy = null;
    }
  
    /**
     * Build the debug table from TowerManager data
     */
    initDebugTable() {
      // Clear existing
      this.debugTable.innerHTML = "";
  
      // Grab data from TowerManager
      const towerData = this.game.towerManager.getTowerData();
      if (!towerData.length) return;
  
      // Build a header row: 3 columns
      const thead = document.createElement("thead");
      const headerRow = document.createElement("tr");
      headerRow.innerHTML = `
        <th style="min-width: 120px;"></th>
        <th>${towerData[0].type.toUpperCase()} Tower</th>
        <th>${towerData[1].type.toUpperCase()} Tower</th>
      `;
      thead.appendChild(headerRow);
      this.debugTable.appendChild(thead);
  
      // Body
      const tbody = document.createElement("tbody");
  
      // Base Price row
      const basePriceRow = document.createElement("tr");
      basePriceRow.innerHTML = `
        <td><strong>Base Price</strong></td>
        <td>$${towerData[0].basePrice}</td>
        <td>$${towerData[1].basePrice}</td>
      `;
      tbody.appendChild(basePriceRow);
  
      // Upgrades
      // We'll assume each tower definition has the same number of upgrades
      const maxUpgrades = Math.max(
        towerData[0].upgrades.length,
        towerData[1].upgrades.length
      );
  
      for (let i = 0; i < maxUpgrades; i++) {
        const lvl = i + 1;
  
        // 1) Row for damage at level
        const rowDamage = document.createElement("tr");
        rowDamage.innerHTML = `
          <td>Level ${lvl} Damage</td>
          <td>${towerData[0].upgrades[i] ? towerData[0].upgrades[i].damage : "-"}</td>
          <td>${towerData[1].upgrades[i] ? towerData[1].upgrades[i].damage : "-"}</td>
        `;
        tbody.appendChild(rowDamage);
  
        // 2) Row for upgrade cost (except level 1 which has no upgrade cost)
        if (lvl > 1) {
          const rowCost = document.createElement("tr");
          rowCost.innerHTML = `
            <td>Level ${lvl} Upgrade Cost</td>
            <td>$${towerData[0].upgrades[i] ? towerData[0].upgrades[i].upgradeCost : "-"}</td>
            <td>$${towerData[1].upgrades[i] ? towerData[1].upgrades[i].upgradeCost : "-"}</td>
          `;
          tbody.appendChild(rowCost);
        }
      }
  
      this.debugTable.appendChild(tbody);
    }
  
    /**
     * Handle canvas clicks for tower creation/upgrade or enemy selection
     */
    handleCanvasClick(mx, my, rect) {
      // Check for tower spot
      const spot = this.game.towerSpots.find(s => {
        const dx = mx - s.x;
        const dy = my - s.y;
        return dx*dx + dy*dy < 100;
      });
      if (spot) {
        // Does it already have a tower?
        const existingTower = this.game.towerManager.towers.find(t => t.spot === spot);
        if (existingTower) {
          // Show existing tower panel
          this.showExistingTowerPanel(existingTower, mx + rect.left, my + rect.top);
        } else {
          // Show tower creation panel
          this.showNewTowerPanel(spot, mx + rect.left, my + rect.top);
        }
        return;
      }
  
      // Otherwise, maybe clicked an enemy
      let clickedEnemy = null;
      for (const enemy of this.game.enemies) {
        if (
          mx >= enemy.x &&
          mx <= enemy.x + enemy.width &&
          my >= enemy.y &&
          my <= enemy.y + enemy.height
        ) {
          clickedEnemy = enemy;
          break;
        }
      }
      this.selectedEnemy = clickedEnemy;
      if (clickedEnemy) {
        this.showEnemyStats(clickedEnemy);
      } else {
        this.hideEnemyStats();
      }
  
      // Hide tower panel if not clicking a tower spot
      if (!spot) {
        this.hideTowerPanel();
      }
    }
  
    showNewTowerPanel(spot, screenX, screenY) {
      this.towerSelectPanel.innerHTML = "";
  
      // We'll fetch from towerManager, e.g. two tower types
      const towerDefs = this.game.towerManager.getTowerData();
  
      // Show each tower type as an option
      towerDefs.forEach(def => {
        const div = document.createElement("div");
        div.className = "towerOption";
        div.textContent = `${def.type.toUpperCase()} - $${def.basePrice}, DMG:${def.upgrades[0].damage}, Rate:${def.fireRate}s`;
        div.addEventListener("click", () => {
          if (this.game.gold >= def.basePrice && !spot.occupied) {
            // Spend gold, create the tower
            this.game.gold -= def.basePrice;
            const newTower = this.game.towerManager.createTower(def.type);
            newTower.x = spot.x;
            newTower.y = spot.y;
            newTower.spot = spot;
            spot.occupied = true;
            this.game.towerManager.towers.push(newTower);
          }
          this.hideTowerPanel();
        });
        this.towerSelectPanel.appendChild(div);
      });
  
      this.positionTowerPanel(screenX, screenY);
    }
  
    showExistingTowerPanel(tower, screenX, screenY) {
      this.towerSelectPanel.innerHTML = "";
  
      const title = document.createElement("div");
      title.style.fontWeight = "bold";
      title.textContent = `${tower.type.toUpperCase()} Tower`;
      this.towerSelectPanel.appendChild(title);
  
      const currStats = document.createElement("div");
      currStats.innerHTML = `
        Level: ${tower.level}<br>
        Damage: ${tower.damage}<br>
        Fire Rate: ${tower.fireRate.toFixed(2)}s
      `;
      this.towerSelectPanel.appendChild(currStats);
  
      if (tower.level < tower.maxLevel) {
        const nextLevel = tower.level + 1;
        // We'll find the tower definition so we can figure out next damage/cost
        const def = this.game.towerManager.getTowerData().find(d => d.type === tower.type);
        if (def) {
          const nextDef = def.upgrades[tower.level]; // e.g. tower.level=1 => index=1
          if (nextDef) {
            const nextDamage = nextDef.damage;
            const cost = nextDef.upgradeCost;
            const nextRate = Math.max(0.8, tower.fireRate - 0.2).toFixed(2);
  
            const nextStats = document.createElement("div");
            nextStats.innerHTML = `
              <hr>
              <strong>Next Level ${nextLevel}:</strong><br>
              Damage: ${nextDamage}<br>
              Fire Rate: ${nextRate}s<br>
              Upgrade Cost: $${cost}
            `;
            this.towerSelectPanel.appendChild(nextStats);
  
            const upgradeBtn = document.createElement("button");
            upgradeBtn.textContent = "Upgrade";
            upgradeBtn.disabled = (this.game.gold < cost);
            upgradeBtn.addEventListener("click", () => {
              this.game.towerManager.upgradeTower(tower);
              this.hideTowerPanel();
            });
            this.towerSelectPanel.appendChild(upgradeBtn);
          }
        }
      } else {
        const maxed = document.createElement("div");
        maxed.style.marginTop = "6px";
        maxed.textContent = "Tower is at max level.";
        this.towerSelectPanel.appendChild(maxed);
      }
  
      this.positionTowerPanel(screenX, screenY);
    }
  
    positionTowerPanel(screenX, screenY) {
      this.towerSelectPanel.style.left = (screenX + 10) + "px";
      this.towerSelectPanel.style.top = (screenY - 50) + "px";
      this.towerSelectPanel.style.display = "block";
    }
  
    hideTowerPanel() {
      this.towerSelectPanel.style.display = "none";
    }
  
    showEnemyStats(enemy) {
      this.enemyStatsDiv.style.display = "block";
      this.enemyImage.src         = enemy.src;
      this.enemyNameEl.textContent  = enemy.name;
      this.enemyHpEl.textContent    = `${enemy.hp}/${enemy.baseHp}`;
      this.enemySpeedEl.textContent = enemy.speed;
      this.enemyGoldEl.textContent  = enemy.gold;
    }
  
    hideEnemyStats() {
      this.enemyStatsDiv.style.display = "none";
    }
  }