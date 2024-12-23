export class UIManager {
    constructor(game, enemyStatsDiv, towerSelectPanel, debugTable) {
      this.game = game;
      this.enemyStatsDiv = enemyStatsDiv;
      this.towerSelectPanel = towerSelectPanel;
      this.debugTable = debugTable;
  
      // Elements inside enemyStatsDiv
      this.enemyImage = document.getElementById("enemyImage");
      this.enemyNameEl = document.getElementById("enemyName");
      this.enemyHpEl = document.getElementById("enemyHp");
      this.enemySpeedEl = document.getElementById("enemySpeed");
      this.enemyGoldEl = document.getElementById("enemyGold");
  
      this.selectedEnemy = null;
    }
  
    updateLivesCounter(lives) {
      const livesCounter = document.getElementById("livesCounter");
      if (livesCounter) {
        livesCounter.textContent = `Lives: ${lives}`;
      }
    }
  
    initDebugTable() {
      this.debugTable.innerHTML = "";
  
      const towerData = this.game.towerManager.getTowerData();
      if (!towerData.length) return;
  
      const thead = document.createElement("thead");
      const headerRow = document.createElement("tr");
      headerRow.innerHTML = `
        <th style="min-width: 120px;"></th>
        <th>${towerData[0].type.toUpperCase()} Tower</th>
        <th>${towerData[1].type.toUpperCase()} Tower</th>
      `;
      thead.appendChild(headerRow);
      this.debugTable.appendChild(thead);
  
      const tbody = document.createElement("tbody");
  
      const basePriceRow = document.createElement("tr");
      basePriceRow.innerHTML = `
        <td><strong>Base Price</strong></td>
        <td>$${towerData[0].basePrice}</td>
        <td>$${towerData[1].basePrice}</td>
      `;
      tbody.appendChild(basePriceRow);
  
      const maxUpgrades = Math.max(
        towerData[0].upgrades.length,
        towerData[1].upgrades.length
      );
  
      for (let i = 0; i < maxUpgrades; i++) {
        const lvl = i + 1;
  
        const rowDamage = document.createElement("tr");
        rowDamage.innerHTML = `
          <td>Level ${lvl} Damage</td>
          <td>${towerData[0].upgrades[i] ? towerData[0].upgrades[i].damage : "-"}</td>
          <td>${towerData[1].upgrades[i] ? towerData[1].upgrades[i].damage : "-"}</td>
        `;
        tbody.appendChild(rowDamage);
  
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
  
    handleCanvasClick(mx, my, rect) {
      const spot = this.game.towerSpots.find((s) => {
        const dx = mx - s.x;
        const dy = my - s.y;
        return dx * dx + dy * dy < 100;
      });
      if (spot) {
        const existingTower = this.game.towerManager.towers.find(
          (t) => t.spot === spot
        );
        if (existingTower) {
          this.showExistingTowerPanel(
            existingTower,
            mx + rect.left,
            my + rect.top
          );
        } else {
          this.showNewTowerPanel(spot, mx + rect.left, my + rect.top);
        }
        return;
      }
  
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
  
      if (!spot) {
        this.hideTowerPanel();
      }
    }
  
    showNewTowerPanel(spot, screenX, screenY) {
      this.towerSelectPanel.innerHTML = "";
  
      const towerDefs = this.game.towerManager.getTowerData();
  
      towerDefs.forEach((def) => {
        const div = document.createElement("div");
        div.className = "towerOption";
        div.textContent = `${def.type.toUpperCase()} - $${def.basePrice}, DMG:${def.upgrades[0].damage}, Rate:${def.fireRate}s`;
        div.addEventListener("click", () => {
          if (this.game.gold >= def.basePrice && !spot.occupied) {
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
  
    positionTowerPanel(screenX, screenY) {
      this.towerSelectPanel.style.left = screenX + 10 + "px";
      this.towerSelectPanel.style.top = screenY - 50 + "px";
      this.towerSelectPanel.style.display = "block";
    }
  
    hideTowerPanel() {
      this.towerSelectPanel.style.display = "none";
    }
  
    showEnemyStats(enemy) {
      this.enemyStatsDiv.style.display = "block";
      this.enemyImage.src = enemy.src;
      this.enemyNameEl.textContent = enemy.name;
      this.enemyHpEl.textContent = `${enemy.hp}/${enemy.baseHp}`;
      this.enemySpeedEl.textContent = enemy.speed;
      this.enemyGoldEl.textContent = enemy.gold;
    }
  
    hideEnemyStats() {
      this.enemyStatsDiv.style.display = "none";
    }
  }