export class UIManager {
    constructor(
      game,
      enemyStatsDiv,
      towerSelectPanel,
      debugTable,
      loseMessageDiv,
      winMessageDiv
    ) {
      this.game = game;
      this.enemyStatsDiv = enemyStatsDiv;
      this.towerSelectPanel = towerSelectPanel;
      this.debugTable = debugTable;
      this.loseMessageDiv = loseMessageDiv;
      this.winMessageDiv = winMessageDiv;
  
      // Elements inside enemyStatsDiv
      this.enemyImage    = document.getElementById("enemyImage");
      this.enemyNameEl   = document.getElementById("enemyName");
      this.enemyHpEl     = document.getElementById("enemyHp");
      this.enemySpeedEl  = document.getElementById("enemySpeed");
      this.enemyGoldEl   = document.getElementById("enemyGold");
  
      this.selectedEnemy = null;
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
  
      // Base Price row
      const basePriceRow = document.createElement("tr");
      basePriceRow.innerHTML = `
        <td><strong>Base Price</strong></td>
        <td>$${towerData[0].basePrice}</td>
        <td>$${towerData[1].basePrice}</td>
      `;
      tbody.appendChild(basePriceRow);
  
      // Upgrades
      const maxUpgrades = Math.max(
        towerData[0].upgrades.length,
        towerData[1].upgrades.length
      );
  
      for (let i = 0; i < maxUpgrades; i++) {
        const lvl = i + 1;
  
        // damage row
        const rowDamage = document.createElement("tr");
        rowDamage.innerHTML = `
          <td>Level ${lvl} Damage</td>
          <td>${towerData[0].upgrades[i] ? towerData[0].upgrades[i].damage : "-"}</td>
          <td>${towerData[1].upgrades[i] ? towerData[1].upgrades[i].damage : "-"}</td>
        `;
        tbody.appendChild(rowDamage);
  
        // upgrade cost row (except lvl 1)
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
  
    // Increase detectionDist to 200 (was 100)
    getTowerSpotAt(mx, my, detectionDist = 200) {
      return this.game.towerSpots.find(s => {
        const dx = mx - s.x;
        const dy = my - s.y;
        return dx * dx + dy * dy < detectionDist * detectionDist;
      });
    }
  
    getEnemyAt(mx, my) {
      return this.game.enemies.find(e => {
        const left   = e.x - e.width / 2;
        const right  = e.x + e.width / 2;
        const top    = e.y - e.height / 2;
        const bottom = e.y + e.height / 2;
        return (mx >= left && mx <= right && my >= top && my <= bottom);
      });
    }
  
    getEntityUnderMouse(mx, my) {
      const spot = this.getTowerSpotAt(mx, my);
      if (spot) {
        return { type: "towerSpot", spot };
      }
      const enemy = this.getEnemyAt(mx, my);
      if (enemy) {
        return { type: "enemy", enemy };
      }
      return null;
    }
  
    handleCanvasClick(mx, my, rect) {
      const entity = this.getEntityUnderMouse(mx, my);
  
      if (!entity) {
        // clicked empty space, hide panels
        this.selectedEnemy = null;
        this.hideEnemyStats();
        this.hideTowerPanel();
        return;
      }
  
      if (entity.type === "towerSpot") {
        const spot = entity.spot;
        const existingTower = this.game.towerManager.towers.find(t => t.spot === spot);
        if (existingTower) {
          this.showExistingTowerPanel(existingTower, rect);
        } else {
          this.showNewTowerPanel(spot, rect);
        }
        return;
      }
  
      if (entity.type === "enemy") {
        const clickedEnemy = entity.enemy;
        this.selectedEnemy = clickedEnemy;
        this.showEnemyStats(clickedEnemy);
        this.hideTowerPanel();
      }
    }
  
    showExistingTowerPanel(tower, rect) {
      this.towerSelectPanel.innerHTML = "";
      this.towerSelectPanel.style.background = "none";
      this.towerSelectPanel.style.border = "none";
      this.towerSelectPanel.style.borderRadius = "0";
      this.towerSelectPanel.style.textAlign = "center";
  
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
  
      // Next-level info if not maxed
      if (tower.level < tower.maxLevel) {
        const nextLevel = tower.level + 1;
        const def = this.game.towerManager.getTowerData().find(d => d.type === tower.type);
        if (def) {
          const nextDef = def.upgrades[tower.level]; // tower.level=1 => index=1
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

      // Add Sell Tower button
      const sellBtn = document.createElement("button");
      sellBtn.style.display = "block";
      sellBtn.style.margin = "6px auto 0 auto";
      sellBtn.textContent = "Sell Tower";
      sellBtn.addEventListener("click", () => {
        this.game.towerManager.sellTower(tower);
        this.hideTowerPanel();
      });
      this.towerSelectPanel.appendChild(sellBtn);
  
      // Show, measure, then position
      this.towerSelectPanel.style.display = "block";
      const panelW = this.towerSelectPanel.offsetWidth;
      const panelH = this.towerSelectPanel.offsetHeight;
  
      const towerScreenX = tower.x + rect.left;
      const towerScreenY = tower.y + rect.top;
      this.towerSelectPanel.style.left = (towerScreenX - panelW / 2) + "px";
      this.towerSelectPanel.style.top  = (towerScreenY - panelH) + "px";
    }
  
    showNewTowerPanel(spot, rect) {
      this.towerSelectPanel.innerHTML = "";
      this.towerSelectPanel.style.background = "none";
      this.towerSelectPanel.style.border = "none";
      this.towerSelectPanel.style.borderRadius = "0";
      this.towerSelectPanel.style.textAlign = "center";
  
      const container = document.createElement("div");
      container.style.display = "flex";
      container.style.gap = "10px";
      container.style.justifyContent = "center";
      container.style.alignItems = "flex-start";
  
      const towerDefs = this.game.towerManager.getTowerData();
      towerDefs.forEach(def => {
        const towerDiv = document.createElement("div");
        towerDiv.style.background = "rgba(0,0,0,0.7)";
        towerDiv.style.border = "1px solid #999";
        towerDiv.style.padding = "4px";
        towerDiv.style.borderRadius = "4px";
        towerDiv.style.minWidth = "80px";
  
        const nameEl = document.createElement("div");
        nameEl.style.fontWeight = "bold";
        nameEl.textContent = def.type.toUpperCase();
        towerDiv.appendChild(nameEl);
  
        const statsEl = document.createElement("div");
        statsEl.innerHTML = `DMG: ${def.upgrades[0].damage}<br>Rate: ${def.fireRate}s`;
        towerDiv.appendChild(statsEl);
  
        const buildBtn = document.createElement("button");
        buildBtn.textContent = `$${def.basePrice}`;
        buildBtn.addEventListener("click", () => {
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
        towerDiv.appendChild(buildBtn);
  
        container.appendChild(towerDiv);
      });
  
      this.towerSelectPanel.appendChild(container);
  
      this.towerSelectPanel.style.display = "block";
      const panelW = this.towerSelectPanel.offsetWidth;
      const panelH = this.towerSelectPanel.offsetHeight;
  
      const spotScreenX = spot.x + rect.left;
      const spotScreenY = spot.y + rect.top;
      this.towerSelectPanel.style.left = (spotScreenX - panelW / 2) + "px";
      this.towerSelectPanel.style.top  = (spotScreenY - panelH) + "px";
    }
  
    hideTowerPanel() {
      this.towerSelectPanel.style.display = "none";
    }
  
    showEnemyStats(enemy) {
      this.enemyStatsDiv.style.display = "block";
      this.enemyImage.src          = enemy.image.src;
      this.enemyNameEl.textContent = enemy.name;
      this.enemyHpEl.textContent   = `${enemy.hp.toFixed(1)}/${enemy.baseHp.toFixed(1)}`;
      this.enemySpeedEl.textContent= enemy.speed.toFixed(1);
      this.enemyGoldEl.textContent = enemy.gold;
    }
  
    hideEnemyStats() {
      this.enemyStatsDiv.style.display = "none";
    }

    /**
     * Called by enemyManager when lives <= 0
     */
    showLoseDialog() {
      this.loseMessageDiv.style.display = "block";
    }

    /**
     * Called by waveManager on final wave completion if we still have >0 lives
     * Display 1, 2, or 3 stars based on how many lives remain
     */
    showWinDialog(finalLives, maxLives) {
      this.winMessageDiv.style.display = "block";
      const starsDiv = this.winMessageDiv.querySelector("#winStars");

      let starCount = 1;
      if (finalLives >= 18) {
        starCount = 3;
      } else if (finalLives >= 10) {
        starCount = 2;
      }

      const starSymbols = [];
      for(let i=1; i<=3; i++){
        if (i <= starCount) {
          // lit star
          starSymbols.push("★");
        } else {
          // dull star
          starSymbols.push("☆");
        }
      }
      if(starsDiv) {
        starsDiv.innerHTML = starSymbols.join(" ");
      }
    }

    handleMouseMove(e) {
      const rect = this.game.canvas.getBoundingClientRect();
      const mx = e.clientX - rect.left;
      const my = e.clientY - rect.top;
  
      const entity = this.getEntityUnderMouse(mx, my);
      this.game.canvas.style.cursor = entity ? "pointer" : "default";
    }
}
