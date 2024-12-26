import { Hero } from "./heroManager.js";

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
      this.selectedHero = null; // for hero selection
      this.selectedTower = null; // if we need to track

      // Listen for mouse move to update cursor
      this.game.canvas.addEventListener("mousemove", (e) => this.handleMouseMove(e));
    }
  
    initDebugTable() {
      this.debugTable.innerHTML = "";
      const towerData = this.game.towerManager.getTowerData();
      if (!towerData.length) return;
  
      // We have 3 tower types: point, splash, barracks
      // Let's create a row with 3 columns for each type
      const thead = document.createElement("thead");
      const headerRow = document.createElement("tr");
      headerRow.innerHTML = `
        <th style="min-width: 120px;"></th>
        <th style="text-align: right;">POINT</th>
        <th style="text-align: right;">SPLASH</th>
        <th style="text-align: right;">MELEE</th>
      `;
      thead.appendChild(headerRow);
      this.debugTable.appendChild(thead);
  
      const tbody = document.createElement("tbody");
  
      // Build arrays
      const pointDef = towerData.find(d => d.type === "point");
      const splashDef = towerData.find(d => d.type === "splash");
      const meleeDef = towerData.find(d => d.type === "barracks");
  
      // Base Price row
      const basePriceRow = document.createElement("tr");
      basePriceRow.innerHTML = `
        <td><strong>Base Price</strong></td>
        <td style="text-align: right;">$${pointDef.basePrice}</td>
        <td style="text-align: right;">$${splashDef.basePrice}</td>
        <td style="text-align: right;">$${meleeDef.basePrice}</td>
      `;
      tbody.appendChild(basePriceRow);

      // For point & splash, we show damage. For melee, show soldier HP/dmg in a combined row
      const maxRows = Math.max(pointDef.upgrades.length, splashDef.upgrades.length, meleeDef.upgrades.length);
      for (let i = 0; i < maxRows; i++) {
        const rowDamage = document.createElement("tr");
        const lvl = i + 1;

        // point
        let pointTxt = "-";
        if (pointDef.upgrades[i]) {
          pointTxt = `DMG: ${pointDef.upgrades[i].damage}`;
        }
        // splash
        let splashTxt = "-";
        if (splashDef.upgrades[i]) {
          splashTxt = `DMG: ${splashDef.upgrades[i].damage}`;
        }
        // melee
        let meleeTxt = "-";
        if (meleeDef.upgrades[i]) {
          const upg = meleeDef.upgrades[i];
          meleeTxt = `HP: ${upg.soldierHp}, DMG: ${upg.soldierDmg}`;
        }
        
        rowDamage.innerHTML = `
          <td>Level ${lvl} Stats</td>
          <td style="text-align: right;">${pointTxt}</td>
          <td style="text-align: right;">${splashTxt}</td>
          <td style="text-align: right;">${meleeTxt}</td>
        `;
        tbody.appendChild(rowDamage);

        if (lvl > 1) {
          const rowCost = document.createElement("tr");
          const pointCost = pointDef.upgrades[i] ? pointDef.upgrades[i].upgradeCost : "-";
          const splashCost = splashDef.upgrades[i] ? splashDef.upgrades[i].upgradeCost : "-";
          const meleeCost = meleeDef.upgrades[i] ? meleeDef.upgrades[i].upgradeCost : "-";
          rowCost.innerHTML = `
            <td>Level ${lvl} Upgrade Cost</td>
            <td style="text-align: right;">$${pointCost}</td>
            <td style="text-align: right;">$${splashCost}</td>
            <td style="text-align: right;">$${meleeCost}</td>
          `;
          tbody.appendChild(rowCost);
        }
      }

      this.debugTable.appendChild(tbody);
    }
  
    getTowerAt(mx, my) {
      return this.game.towerManager.towers.find(t => {
        if (t.type === "barracks") {
          // approximate radius 28 for drawing
          const dx = mx - t.x;
          const dy = my - t.y;
          return (dx*dx + dy*dy) <= (28*28);
        } else {
          // For point / splash
          const drawRadius = 24 + t.level * 4;
          const dx = mx - t.x;
          const dy = my - t.y;
          return (dx*dx + dy*dy) <= (drawRadius*drawRadius);
        }
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

    handleCanvasClick(mx, my, rect) {
      // Check if we clicked a hero
      const hero = this.game.heroManager.getHeroAt(mx, my);
      if (hero) {
        // select the hero
        this.selectedHero = hero;
        this.selectedEnemy = null;
        this.hideTowerPanel();
        this.hideEnemyStats();
        return;
      }

      // if we had a hero selected, then clicking the map sets the hero's target
      if (this.selectedHero) {
        // Move hero
        this.selectedHero.targetX = mx;
        this.selectedHero.targetY = my;
        // Deselect hero so we only do one move command
        this.selectedHero = null;
        return;
      }

      // Otherwise, check tower
      const tower = this.getTowerAt(mx, my);
      if (tower) {
        this.showExistingTowerPanel(tower, rect);
        return;
      }

      // Check tower spot if we didn't click a tower
      const spot = this.getTowerSpotAt(mx, my);
      if (spot) {
        this.showNewTowerPanel(spot, rect);
        return;
      }

      // Check enemy
      const enemy = this.getEnemyAt(mx, my);
      if (enemy) {
        this.selectedEnemy = enemy;
        this.showEnemyStats(enemy);
        this.hideTowerPanel();
        return;
      }

      // clicked empty space
      this.selectedEnemy = null;
      this.selectedHero = null;
      this.hideEnemyStats();
      this.hideTowerPanel();
    }

    // Reuse existing logic from prior code, simplified
    getTowerSpotAt(mx, my) {
      return this.game.towerSpots.find(s => {
        if (s.occupied) return false;
        const dx = mx - s.x;
        const dy = my - s.y;
        return (dx*dx + dy*dy) <= (20*20);
      });
    }

    showExistingTowerPanel(tower, rect) {
      this.towerSelectPanel.innerHTML = "";
      this.towerSelectPanel.style.background = "rgba(0,0,0,0.7)";
      this.towerSelectPanel.style.border = "1px solid #999";
      this.towerSelectPanel.style.borderRadius = "3px";
      this.towerSelectPanel.style.padding = "5px";
      this.towerSelectPanel.style.textAlign = "center";

      const title = document.createElement("div");
      title.style.fontWeight = "bold";
      title.textContent = `${tower.type.toUpperCase()} Tower`;
      this.towerSelectPanel.appendChild(title);

      // Sell Tower
      const sellBtn = document.createElement("button");
      sellBtn.textContent = "Sell Tower";
      sellBtn.style.display = "block";
      sellBtn.style.margin = "4px auto";
      sellBtn.addEventListener("click", () => {
        this.game.towerManager.sellTower(tower);
        this.hideTowerPanel();
      });
      this.towerSelectPanel.appendChild(sellBtn);

      // If not barracks, show standard stats
      if (tower.type !== "barracks") {
        const currStats = document.createElement("div");
        currStats.style.margin = "4px 0";
        currStats.innerHTML = `
          Level: ${tower.level}<br>
          Damage: ${tower.damage}<br>
          Fire Rate: ${tower.fireRate.toFixed(1)}s
        `;
        this.towerSelectPanel.appendChild(currStats);

        // Next-level info if not max
        if (tower.level < tower.maxLevel) {
          const def = this.game.towerManager.getTowerData().find(d => d.type === tower.type);
          if (def) {
            const nextDef = def.upgrades[tower.level];
            if (nextDef) {
              const nextDamage = nextDef.damage;
              const cost = nextDef.upgradeCost;
              const nextStats = document.createElement("div");
              nextStats.style.margin = "4px 0";
              nextStats.innerHTML = `
                <strong>Next Lvl ${tower.level+1}:</strong><br>
                Damage: ${nextDamage}<br>
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
      } else {
        // Barracks tower
        const currStats = document.createElement("div");
        currStats.style.margin = "4px 0";
        currStats.innerHTML = `
          Level: ${tower.level}<br>
          Soldier HP: ${tower.soldierHp}<br>
          Soldier DMG: ${tower.soldierDmg}
        `;
        this.towerSelectPanel.appendChild(currStats);

        // If the tower doesn't have unitGroup yet, create it
        if (!tower.unitGroup) {
          this.game.towerManager.createBarracksUnits(tower);
        }

        // Next-level info if not max
        if (tower.level < tower.maxLevel) {
          const def = this.game.towerManager.getTowerData().find(d => d.type === "barracks");
          if (def) {
            const nextDef = def.upgrades[tower.level];
            if (nextDef) {
              const cost = nextDef.upgradeCost;
              const nextStats = document.createElement("div");
              nextStats.style.margin = "4px 0";
              nextStats.innerHTML = `
                <strong>Next Lvl ${tower.level+1}:</strong><br>
                Soldier HP: ${nextDef.soldierHp}, DMG: ${nextDef.soldierDmg}<br>
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
          maxed.textContent = "Barracks is at max level.";
          this.towerSelectPanel.appendChild(maxed);
        }

        // Also add a "Set Rally" button
        const rallyBtn = document.createElement("button");
        rallyBtn.textContent = "Set Rally Point";
        rallyBtn.style.display = "block";
        rallyBtn.style.margin = "6px auto";
        rallyBtn.addEventListener("click", () => {
          // For simplicity, let user click anywhere on the map next to set the rally
          // We'll store the tower in a local var, then handle the next map click
          this.selectedTower = tower;
          this.hideTowerPanel();
          // show a small text, or you can rely on user knowledge
          alert("Click the desired rally point on the map.");
        });
        this.towerSelectPanel.appendChild(rallyBtn);
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
      this.towerSelectPanel.style.background = "rgba(0,0,0,0.8)";
      this.towerSelectPanel.style.border = "1px solid #999";
      this.towerSelectPanel.style.borderRadius = "3px";
      this.towerSelectPanel.style.padding = "5px";
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

        // Quick stats
        let statsEl = document.createElement("div");
        if (def.type === "barracks") {
          statsEl.innerHTML = `Soldier HP: ${def.upgrades[0].soldierHp}, DMG: ${def.upgrades[0].soldierDmg}`;
        } else {
          statsEl.innerHTML = `DMG: ${def.upgrades[0].damage}<br>Rate: ${def.fireRate.toFixed(1)}s`;
        }
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

            // if it's a barracks, create the units
            if (def.type === "barracks") {
              this.game.towerManager.createBarracksUnits(newTower);
            }

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
      if (enemy.image) this.enemyImage.src = enemy.image.src;
      this.enemyNameEl.textContent = enemy.name;
      this.enemyHpEl.textContent   = `${enemy.hp.toFixed(1)}/${enemy.baseHp.toFixed(1)}`;
      this.enemySpeedEl.textContent= enemy.speed.toFixed(1);
      this.enemyGoldEl.textContent = enemy.gold;
    }
  
    hideEnemyStats() {
      this.enemyStatsDiv.style.display = "none";
    }

    showLoseDialog() {
      this.loseMessageDiv.style.display = "block";
      this.game.gameOver = true;
    }

    showWinDialog(finalLives, maxLives) {
      this.winMessageDiv.style.display = "block";
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

    handleMouseMove(e) {
      const rect = this.game.canvas.getBoundingClientRect();
      const mx = e.clientX - rect.left;
      const my = e.clientY - rect.top;
  
      // If we are setting a rally point
      if (this.selectedTower && this.selectedTower.type === "barracks") {
        // if user clicks, we’ll set the rally
        // but we do that in handleCanvasClick or a separate approach.
      }

      // If hero was selected, show pointer for next click, else default
      let cursorStyle = "default";

      // check hero under mouse
      const hero = this.game.heroManager.getHeroAt(mx, my);
      if (hero) {
        cursorStyle = "pointer";
      } else {
        // check tower
        const tower = this.getTowerAt(mx, my);
        if (tower) {
          cursorStyle = "pointer";
        } else {
          // check enemy
          const enemy = this.getEnemyAt(mx, my);
          if (enemy) {
            cursorStyle = "pointer";
          } else {
            // check tower spot
            const spot = this.getTowerSpotAt(mx, my);
            if (spot) {
              cursorStyle = "pointer";
            }
          }
        }
      }

      this.game.canvas.style.cursor = cursorStyle;
    }
}
