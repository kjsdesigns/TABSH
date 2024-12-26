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

      // Listen for mouse move to update cursor
      this.game.canvas.addEventListener("mousemove", (e) => this.handleMouseMove(e));
    }
  
    initDebugTable() {
      this.debugTable.innerHTML = "";
      const towerData = this.game.towerManager.getTowerData();
      if (!towerData.length) return;
  
      const thead = document.createElement("thead");
      const headerRow = document.createElement("tr");
      // Remove the word "Tower" from each header, and right-align columns 2 & 3
      headerRow.innerHTML = `
        <th style="min-width: 120px;"></th>
        <th style="text-align: right;">${towerData[0].type.toUpperCase()}</th>
        <th style="text-align: right;">${towerData[1].type.toUpperCase()}</th>
      `;
      thead.appendChild(headerRow);
      this.debugTable.appendChild(thead);
  
      const tbody = document.createElement("tbody");
  
      // Base Price row
      const basePriceRow = document.createElement("tr");
      basePriceRow.innerHTML = `
        <td><strong>Base Price</strong></td>
        <td style="text-align: right;">$${towerData[0].basePrice}</td>
        <td style="text-align: right;">$${towerData[1].basePrice}</td>
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
          <td style="text-align: right;">${towerData[0].upgrades[i] ? towerData[0].upgrades[i].damage : "-"}</td>
          <td style="text-align: right;">${towerData[1].upgrades[i] ? towerData[1].upgrades[i].damage : "-"}</td>
        `;
        tbody.appendChild(rowDamage);
  
        // upgrade cost row (except lvl 1)
        if (lvl > 1) {
          const rowCost = document.createElement("tr");
          rowCost.innerHTML = `
            <td>Level ${lvl} Upgrade Cost</td>
            <td style="text-align: right;">$${towerData[0].upgrades[i] ? towerData[0].upgrades[i].upgradeCost : "-"}</td>
            <td style="text-align: right;">$${towerData[1].upgrades[i] ? towerData[1].upgrades[i].upgradeCost : "-"}</td>
          `;
          tbody.appendChild(rowCost);
        }
      }
  
      this.debugTable.appendChild(tbody);
    }
  
    // Tower click area is the actual drawn radius
    getTowerAt(mx, my) {
      return this.game.towerManager.towers.find(t => {
        const drawRadius = 24 + t.level * 4;
        const dx = mx - t.x;
        const dy = my - t.y;
        return (dx*dx + dy*dy) <= (drawRadius*drawRadius);
      });
    }

    // Unoccupied tower spot clickable area = radius 20
    getTowerSpotAt(mx, my) {
      return this.game.towerSpots.find(s => {
        if (s.occupied) return false;
        const dx = mx - s.x;
        const dy = my - s.y;
        return (dx*dx + dy*dy) <= (20*20);
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
      const tower = this.getTowerAt(mx, my);
      if (tower) {
        return { type: "tower", tower };
      }
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
        // clicked empty space
        this.selectedEnemy = null;
        this.hideEnemyStats();
        this.hideTowerPanel();
        return;
      }
  
      if (entity.type === "towerSpot") {
        this.showNewTowerPanel(entity.spot, rect);
        return;
      }
      if (entity.type === "tower") {
        this.showExistingTowerPanel(entity.tower, rect);
        return;
      }
      if (entity.type === "enemy") {
        this.selectedEnemy = entity.enemy;
        this.showEnemyStats(entity.enemy);
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

      // Sell Tower button near top, smaller
      const sellBtn = document.createElement("button");
      sellBtn.textContent = "Sell Tower";
      sellBtn.style.display = "block";
      sellBtn.style.margin = "3px auto 6px auto";
      sellBtn.style.fontSize = "0.85em";
      sellBtn.style.padding = "2px 5px";
      sellBtn.addEventListener("click", () => {
        this.game.towerManager.sellTower(tower);
        this.hideTowerPanel();
      });
      this.towerSelectPanel.appendChild(sellBtn);
  
      // Round fireRate to 1 decimal place
      const currentFireRate = Math.round(tower.fireRate * 10) / 10;

      const currStats = document.createElement("div");
      currStats.innerHTML = `
        Level: ${tower.level}<br>
        Damage: ${tower.damage}<br>
        Fire Rate: ${currentFireRate.toFixed(1)}s
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

            // If we want the next level's rate to be (base - 0.2) or something:
            // We'll do a simple 0.2 improvement for now, then round to 1 decimal
            const nextRate = Math.round(Math.max(0.1, tower.fireRate - 0.2) * 10)/10;

            const nextStats = document.createElement("div");
            nextStats.innerHTML = `
              <hr>
              <strong>Next Level ${nextLevel}:</strong><br>
              Damage: ${nextDamage}<br>
              Fire Rate: ${nextRate.toFixed(1)}s<br>
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

        // Round fireRate to 1 decimal for display
        const displayRate = Math.round(def.fireRate * 10) / 10;

        const statsEl = document.createElement("div");
        statsEl.innerHTML = `DMG: ${def.upgrades[0].damage}<br>Rate: ${displayRate.toFixed(1)}s`;
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
      // Mark game over so it doesn't keep updating
      this.game.gameOver = true;
    }

    /**
     * Called by waveManager on final wave completion if we still have >0 lives
     */
    showWinDialog(finalLives, maxLives) {
      this.winMessageDiv.style.display = "block";
      // Mark game over
      this.game.gameOver = true;

      const starsDiv = this.winMessageDiv.querySelector("#winStars");
      let starCount = 1;
      if (finalLives >= 18) {
        starCount = 3;
      } else if (finalLives >= 10) {
        starCount = 2;
      }
      const starSymbols = [];
      for(let i=1; i<=3; i++){
        if (i <= starCount) starSymbols.push("★");
        else starSymbols.push("☆");
      }
      if(starsDiv) starsDiv.innerHTML = starSymbols.join(" ");
    }

    // Update mouse cursor to pointer if over tower or enemy
    handleMouseMove(e) {
      const rect = this.game.canvas.getBoundingClientRect();
      const mx = e.clientX - rect.left;
      const my = e.clientY - rect.top;
  
      const entity = this.getEntityUnderMouse(mx, my);
      if (entity && (entity.type === "tower" || entity.type === "enemy")) {
        this.game.canvas.style.cursor = "pointer";
      } else if (entity && entity.type === "towerSpot") {
        // Could also set to "pointer" if you want an indication for building
        this.game.canvas.style.cursor = "pointer";
      } else {
        this.game.canvas.style.cursor = "default";
      }
    }
}
