#!/bin/bash

################################################################################
# Create NEW FILE: js/heroManager.js
################################################################################
cat << 'EOF' > js/heroManager.js
/**
 * heroManager.js
 * 
 * Manages one or more Heroes (melee or archer).
 * Each hero has:
 *  - HP
 *  - Attack stats (for melee or ranged; simplified here)
 *  - Engagement logic if it's a melee hero
 *  - Manual movement commands
 */
import { MeleeFighter } from "./unitManager.js";

export class Hero {
  constructor(config) {
    // Common stats
    this.name = config.name || "Hero";
    this.x = config.x || 400;
    this.y = config.y || 300;
    this.radius = config.radius || 20;    // for selection & drawing
    this.maxHp = config.maxHp || 100;     // total HP
    this.hp = this.maxHp;
    this.damage = config.damage || 10;    // per attack
    this.attackInterval = config.attackInterval || 1.0; // seconds
    this.range = config.range || 20;      // how close to engage for melee
    this.isMelee = config.isMelee || true; // if false => might do ranged logic
    // For revival
    this.dead = false;
    this.respawnTimer = 0;
    this.respawnTime = 10; // seconds greyed out

    this.targetX = this.x; // if moving to a user-clicked destination
    this.targetY = this.y;
    this.speed = config.speed || 80; // movement speed

    // Engagement
    this.currentEnemy = null;
    this.attackCooldown = 0;

    // Simple offset for archer? (not fully implemented, but you could if you want)
  }

  update(deltaSec, game) {
    // If dead, handle respawn timer
    if (this.dead) {
      this.respawnTimer -= deltaSec;
      if (this.respawnTimer <= 0) {
        // Revive
        this.dead = false;
        this.hp = this.maxHp;
        // On revival, reappear at your last commanded position
        // (or you could do something else if you prefer)
      }
      return;
    }

    // If alive, move toward targetX/targetY (if we're not currently engaged)
    // If we are engaged, we remain locked in place for the fight.
    if (!this.currentEnemy) {
      this.moveToDestination(deltaSec);
    }

    // If melee, check engagement
    if (this.isMelee && !this.currentEnemy) {
      // see if there's an enemy within range
      const enemy = game.enemies.find(e => {
        // measure center to center
        const dx = e.x - this.x;
        const dy = e.y - this.y;
        const dist = Math.sqrt(dx*dx + dy*dy);
        return dist <= this.range + e.width/2; 
      });
      if (enemy) {
        // engage
        this.currentEnemy = enemy;
      }
    }

    // If engaged, fight
    if (this.currentEnemy) {
      // check if enemy is gone or dead
      if (this.currentEnemy.dead || !game.enemies.includes(this.currentEnemy)) {
        this.currentEnemy = null;
        // maybe move back to original position? 
        // If we want that, the hero won't remain where the fight ended.
        // We'll do the "hero stays put" approach for now.
        return;
      }

      // Attack cooldown
      this.attackCooldown -= deltaSec;
      if (this.attackCooldown <= 0) {
        this.attackCooldown = this.attackInterval;
        // We do random or fixed damage
        const dmg = this.damage; 
        this.currentEnemy.hp -= dmg;
        if (this.currentEnemy.hp <= 0) {
          // kill the enemy
          this.currentEnemy.hp = 0;
          this.currentEnemy.dead = true;
          // enemy awarding gold, etc. is done in enemyManager

          // hero can return to last position
          // but let's simply let them remain where they are for the moment:
          this.currentEnemy = null;
        }
      }
    }
  }

  draw(ctx) {
    // if dead, draw grey circle
    if (this.dead) {
      ctx.fillStyle = "grey";
    } else {
      ctx.fillStyle = this.isMelee ? "darkslateblue" : "darkolivegreen";
    }
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.radius, 0, Math.PI*2);
    ctx.fill();

    // small HP bar
    if (!this.dead && this.hp < this.maxHp) {
      const barW = 40;
      const pct = this.hp / this.maxHp;
      ctx.fillStyle = "red";
      ctx.fillRect(this.x - barW/2, this.y - this.radius - 12, barW, 5);
      ctx.fillStyle = "lime";
      ctx.fillRect(this.x - barW/2, this.y - this.radius - 12, barW * pct, 5);
    }
  }

  moveToDestination(deltaSec) {
    const dx = this.targetX - this.x;
    const dy = this.targetY - this.y;
    const dist = Math.sqrt(dx*dx + dy*dy);
    if (dist < 2) {
      // close enough, stop
      this.x = this.targetX;
      this.y = this.targetY;
      return;
    }
    const step = this.speed * deltaSec;
    if (step >= dist) {
      this.x = this.targetX;
      this.y = this.targetY;
    } else {
      this.x += (dx / dist) * step;
      this.y += (dy / dist) * step;
    }
  }

  // Called when hero takes damage
  takeDamage(amount) {
    if (this.dead) return;
    this.hp -= amount;
    if (this.hp <= 0) {
      this.dead = true;
      this.hp = 0;
      this.respawnTimer = this.respawnTime;
      this.currentEnemy = null;
    }
  }
}

export class HeroManager {
  constructor(game) {
    this.game = game;
    this.heroes = [];
  }

  addHero(config) {
    const hero = new Hero(config);
    this.heroes.push(hero);
    return hero;
  }

  update(deltaSec) {
    this.heroes.forEach(hero => {
      hero.update(deltaSec, this.game);
    });
  }

  draw(ctx) {
    this.heroes.forEach(hero => {
      hero.draw(ctx);
    });
  }

  // Get hero at click
  getHeroAt(mx, my) {
    return this.heroes.find(h => {
      const dx = mx - h.x;
      const dy = my - h.y;
      const dist = Math.sqrt(dx*dx + dy*dy);
      return dist <= h.radius;
    });
  }
}
EOF

################################################################################
# Create NEW FILE: js/unitManager.js
################################################################################
cat << 'EOF' > js/unitManager.js
/**
 * unitManager.js
 * 
 * Houses common melee “fighter” logic plus the specialized code for
 * tower-spawned melee units (barracks). 
 */

export class MeleeFighter {
  constructor(config) {
    this.x = config.x || 0;
    this.y = config.y || 0;
    this.radius = config.radius || 8; // smaller than hero
    this.maxHp = config.maxHp || 50;
    this.hp = this.maxHp;
    this.damage = config.damage || 5;
    this.attackInterval = config.attackInterval || 1.0;
    this.attackCooldown = 0;
    this.dead = false;
    this.respawnTimer = 0;
    this.respawnTime = 10;

    // The gather/rally point we return to after a fight or after revival
    this.rallyX = config.rallyX || this.x;
    this.rallyY = config.rallyY || this.y;

    // Movement speed
    this.speed = config.speed || 60;

    // Engagement
    this.engagementRange = config.engagementRange || 10;
    this.currentEnemy = null;
  }

  update(deltaSec, game) {
    // Handle death & revival
    if (this.dead) {
      this.respawnTimer -= deltaSec;
      if (this.respawnTimer <= 0) {
        this.dead = false;
        this.hp = this.maxHp;
        // On revival, we remain at the same spot, but must walk to rally
        // (some designs might let you instantly reappear at rally)
      }
      return;
    }

    // If not engaged, move to rally if not already there
    if (!this.currentEnemy) {
      this.moveToRally(deltaSec);
      // Attempt to engage an enemy if in range
      const enemy = game.enemies.find(e => {
        const dx = e.x - this.x;
        const dy = e.y - this.y;
        const dist = Math.sqrt(dx*dx + dy*dy);
        return dist <= (this.engagementRange + e.width/2);
      });
      if (enemy) {
        this.currentEnemy = enemy;
      }
    } else {
      // engaged with an enemy
      if (this.currentEnemy.dead || !game.enemies.includes(this.currentEnemy)) {
        // enemy is gone
        this.currentEnemy = null;
        return;
      }
      // fight
      this.attackCooldown -= deltaSec;
      if (this.attackCooldown <= 0) {
        this.attackCooldown = this.attackInterval;
        // deal damage
        this.currentEnemy.hp -= this.damage;
        if (this.currentEnemy.hp <= 0) {
          this.currentEnemy.dead = true;
          game.gold += this.currentEnemy.gold || 0; // or let enemyManager handle it
          this.currentEnemy = null;
          // go back to rally
        }
      }
    }
  }

  draw(ctx) {
    if (this.dead) {
      ctx.fillStyle = "grey";
    } else {
      ctx.fillStyle = "brown";
    }
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.radius, 0, Math.PI*2);
    ctx.fill();
    // HP bar
    if (!this.dead && this.hp < this.maxHp) {
      const barW = 20;
      const pct = this.hp / this.maxHp;
      ctx.fillStyle = "red";
      ctx.fillRect(this.x - barW/2, this.y - this.radius - 6, barW, 3);
      ctx.fillStyle = "lime";
      ctx.fillRect(this.x - barW/2, this.y - this.radius - 6, barW * pct, 3);
    }
  }

  moveToRally(deltaSec) {
    const dx = this.rallyX - this.x;
    const dy = this.rallyY - this.y;
    const dist = Math.sqrt(dx*dx + dy*dy);
    if (dist <= 2) return; // close enough
    const step = this.speed * deltaSec;
    if (step >= dist) {
      this.x = this.rallyX;
      this.y = this.rallyY;
    } else {
      this.x += (dx / dist) * step;
      this.y += (dy / dist) * step;
    }
  }

  takeDamage(amount) {
    if (this.dead) return;
    this.hp -= amount;
    if (this.hp <= 0) {
      this.hp = 0;
      this.dead = true;
      this.respawnTimer = this.respawnTime;
      this.currentEnemy = null;
    }
  }
}

/**
 * Manages a group of melee fighters belonging to a single "barracks" tower.
 */
export class TowerUnitGroup {
  constructor(game, x, y, soldierConfig, count = 3) {
    this.game = game;
    this.units = [];
    // Place them in a small triangle around x,y
    // For example, offset them so they don't overlap
    // each circle ~15px diameter, with 15px between
    // We'll keep it simple:
    //   u1 at (x, y-10), u2 at (x-10, y+10), u3 at (x+10, y+10)
    // Adjust soldierConfig slightly for each
    const offsets = [
      { dx: 0,  dy: -10 },
      { dx: -12, dy: 10 },
      { dx: 12,  dy: 10 },
    ];
    for (let i = 0; i < count; i++) {
      const base = Object.assign({}, soldierConfig);
      base.x = x + offsets[i].dx;
      base.y = y + offsets[i].dy;
      this.units.push(new MeleeFighter(base));
    }
  }

  setRallyPoint(rx, ry) {
    this.units.forEach(u => {
      u.rallyX = rx;
      u.rallyY = ry;
    });
  }

  update(deltaSec) {
    this.units.forEach(u => {
      u.update(deltaSec, this.game);
    });
  }

  draw(ctx) {
    this.units.forEach(u => {
      u.draw(ctx);
    });
  }
}
EOF

################################################################################
# OVERWRITE js/towerManager.js
################################################################################
cat << 'EOF' > js/towerManager.js
import { TowerUnitGroup } from "./unitManager.js";

export class TowerManager {
  constructor(game) {
    this.game = game;
    this.towers = [];
    this.projectiles = [];

    // Existing tower definitions + new "barracks" (melee) tower
    this.towerTypes = [
      {
        type: "point",
        basePrice: 80,
        range: 169,
        splashRadius: 0,
        fireRate: 1.2,
        upgrades: [
          { level: 1, damage: 10, upgradeCost: 0   },
          { level: 2, damage: 15, upgradeCost: 50  },
          { level: 3, damage: 20, upgradeCost: 100 },
          { level: 4, damage: 25, upgradeCost: 150 },
        ],
      },
      {
        type: "splash",
        basePrice: 80,
        range: 104,
        splashRadius: 50,
        fireRate: 1.2,
        upgrades: [
          { level: 1, damage: 8,  upgradeCost: 0   },
          { level: 2, damage: 12, upgradeCost: 50  },
          { level: 3, damage: 16, upgradeCost: 100 },
          { level: 4, damage: 20, upgradeCost: 150 },
        ],
      },
      {
        type: "barracks",
        basePrice: 100,
        // these won't fire projectiles, so range/splash/fireRate are not used for shooting
        // but we do store them to display in the table
        range: 0,
        splashRadius: 0,
        fireRate: 0,
        upgrades: [
          // We'll store soldier HP & damage in here for each level
          { level: 1, soldierHp: 50,  soldierDmg: 5,  upgradeCost: 0   },
          { level: 2, soldierHp: 70,  soldierDmg: 7,  upgradeCost: 60  },
          { level: 3, soldierHp: 90,  soldierDmg: 9,  upgradeCost: 120 },
          { level: 4, soldierHp: 120, soldierDmg: 12, upgradeCost: 180 },
        ],
      },
    ];
  }

  getTowerData() {
    return this.towerTypes;
  }

  createTower(towerTypeName) {
    const def = this.towerTypes.find(t => t.type === towerTypeName);
    if (!def) return null;
    // For normal towers (point or splash) we do the old approach
    if (towerTypeName !== "barracks") {
      const firstLvl = def.upgrades[0];
      return {
        type: def.type,
        level: 1,
        range: def.range,
        damage: firstLvl.damage || 0,
        splashRadius: def.splashRadius,
        fireRate: def.fireRate,
        fireCooldown: 0,
        upgradeCost: def.upgrades[1] ? def.upgrades[1].upgradeCost : 0,
        maxLevel: def.upgrades.length,
        x: 0,
        y: 0,
        spot: null,
        goldSpent: def.basePrice,
      };
    }

    // For barracks
    return {
      type: def.type,
      level: 1,
      soldierHp: def.upgrades[0].soldierHp,
      soldierDmg: def.upgrades[0].soldierDmg,
      maxLevel: def.upgrades.length,
      upgradeCost: def.upgrades[1] ? def.upgrades[1].upgradeCost : 0,
      x: 0,
      y: 0,
      spot: null,
      goldSpent: def.basePrice,
      // We’ll store a reference to a TowerUnitGroup
      unitGroup: null,
    };
  }

  update(deltaSec) {
    // If gameOver, skip
    if (this.game.gameOver) return;

    // Update normal towers (point, splash) - fire logic
    this.towers.forEach(tower => {
      if (tower.type === "barracks") return; // skip projectile logic
      tower.fireCooldown -= deltaSec;
      if (tower.fireCooldown <= 0) {
        this.fireTower(tower);
        tower.fireCooldown = tower.fireRate;
      }
    });

    // Move projectiles
    this.projectiles.forEach(proj => {
      const step = proj.speed * deltaSec;
      const dx = proj.targetX - proj.x;
      const dy = proj.targetY - proj.y;
      const dist = Math.sqrt(dx*dx + dy*dy);

      if (dist <= step) {
        proj.x = proj.targetX;
        proj.y = proj.targetY;
        proj.hit = true;
      } else {
        proj.x += (dx / dist) * step;
        proj.y += (dy / dist) * step;
      }
    });

    // Handle collisions
    this.projectiles.forEach(proj => {
      if (proj.hit) {
        if (proj.splashRadius > 0) {
          // Splash damage
          const enemiesHit = this.game.enemies.filter(e => {
            const ex = e.x + e.width / 2;
            const ey = e.y + e.height / 2;
            const dx = proj.targetX - ex;
            const dy = proj.targetY - ey;
            return dx*dx + dy*dy <= proj.splashRadius * proj.splashRadius;
          });
          enemiesHit.forEach(e => {
            if (e === proj.mainTarget) e.hp -= proj.damage;
            else e.hp -= proj.damage / 2;
          });
        } else {
          // Single target
          if (proj.mainTarget) {
            proj.mainTarget.hp -= proj.damage;
          }
        }
      }
    });

    // Clean up projectiles
    this.projectiles = this.projectiles.filter(p => !p.hit);

    // Update any Barracks units
    this.towers.forEach(tower => {
      if (tower.type === "barracks" && tower.unitGroup) {
        tower.unitGroup.update(deltaSec);
      }
    });
  }

  fireTower(tower) {
    // existing logic for point / splash
    const enemiesInRange = this.game.enemies.filter(e => {
      const ex = e.x + e.width / 2;
      const ey = e.y + e.height / 2;
      const dx = ex - tower.x;
      const dy = ey - tower.y;
      return (dx*dx + dy*dy) <= (tower.range * tower.range);
    });
    if (!enemiesInRange.length) return;

    // Lock onto first enemy
    const target = enemiesInRange[0];
    const ex = target.x + target.width / 2;
    const ey = target.y + target.height / 2;
    this.projectiles.push({
      x: tower.x,
      y: tower.y,
      w: 4,
      h: 4,
      speed: 300,
      damage: tower.damage,
      splashRadius: tower.splashRadius,
      mainTarget: target,
      targetX: ex,
      targetY: ey,
      hit: false,
    });
  }

  upgradeTower(tower) {
    const def = this.towerTypes.find(t => t.type === tower.type);
    if (!def) return;
    if (tower.level >= def.upgrades.length) return; // maxed

    const nextLvlIndex = tower.level;
    const nextLvl = def.upgrades[nextLvlIndex];
    if (!nextLvl) return;

    if (this.game.gold < nextLvl.upgradeCost) return;

    // Spend gold
    this.game.gold -= nextLvl.upgradeCost;
    tower.goldSpent += nextLvl.upgradeCost;
    tower.level++;

    if (tower.type === "barracks") {
      tower.soldierHp = nextLvl.soldierHp;
      tower.soldierDmg = nextLvl.soldierDmg;
      tower.upgradeCost = def.upgrades[tower.level]
        ? def.upgrades[tower.level].upgradeCost
        : 0;

      // also update existing unitGroup’s stats
      if (tower.unitGroup) {
        tower.unitGroup.units.forEach(u => {
          u.maxHp = tower.soldierHp;
          if (u.hp > u.maxHp) {
            u.hp = u.maxHp; // clamp if needed
          }
          u.damage = tower.soldierDmg;
        });
      }
    } else {
      // normal tower
      tower.damage = nextLvl.damage;
      tower.upgradeCost = def.upgrades[tower.level]
        ? def.upgrades[tower.level].upgradeCost
        : 0;
    }
  }

  sellTower(tower) {
    // 80% of goldSpent
    const refund = Math.floor(tower.goldSpent * 0.8);
    this.game.gold += refund;

    // remove from array
    this.towers = this.towers.filter(t => t !== tower);

    // free the spot
    if (tower.spot) tower.spot.occupied = false;
  }

  drawTowers(ctx) {
    this.towers.forEach(t => {
      if (t.type === "point") {
        // draw normal
        this.drawGenericTower(ctx, t, "blue");
      } else if (t.type === "splash") {
        this.drawGenericTower(ctx, t, "red");
      } else if (t.type === "barracks") {
        // draw a simple building
        ctx.fillStyle = "saddlebrown";
        ctx.beginPath();
        ctx.arc(t.x, t.y, 28, 0, Math.PI*2);
        ctx.fill();
        ctx.strokeStyle = "#fff";
        ctx.stroke();
        // draw its soldier group
        if (t.unitGroup) {
          t.unitGroup.draw(ctx);
        }
      }
    });
  }

  drawGenericTower(ctx, tower, color) {
    const drawRadius = 24 + tower.level * 4;
    ctx.beginPath();
    ctx.arc(tower.x, tower.y, drawRadius, 0, Math.PI * 2);
    ctx.fillStyle = color;
    ctx.fill();
    ctx.strokeStyle = "#fff";
    ctx.stroke();

    // optional range circle
    ctx.beginPath();
    ctx.arc(tower.x, tower.y, tower.range, 0, Math.PI*2);
    ctx.strokeStyle = "rgba(255,255,255,0.3)";
    ctx.stroke();
  }

  drawProjectiles(ctx) {
    ctx.fillStyle = "yellow";
    this.projectiles.forEach(proj => {
      ctx.fillRect(proj.x - 2, proj.y - 2, proj.w, proj.h);
    });
  }

  // Called when a barracks tower is placed or after we set a gather point
  createBarracksUnits(tower) {
    // If we already have unitGroup, remove it or reuse it
    // For now, let's just create it once on tower creation
    const soldierConfig = {
      radius: 7,
      maxHp: tower.soldierHp,
      damage: tower.soldierDmg,
      // random or fixed engagement range
      engagementRange: 10,
      speed: 50,
    };
    tower.unitGroup = new TowerUnitGroup(
      this.game,
      tower.x,
      tower.y,
      soldierConfig,
      3
    );
  }
}
EOF

################################################################################
# OVERWRITE js/uiManager.js
################################################################################
cat << 'EOF' > js/uiManager.js
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
EOF

################################################################################
# OVERWRITE js/game.js
################################################################################
cat << 'EOF' > js/game.js
import { EnemyManager } from "./enemyManager.js";
import { TowerManager } from "./towerManager.js";
import { WaveManager }  from "./waveManager.js";
import { HeroManager }  from "./heroManager.js";

export class Game {
  constructor(
    canvas,
    enemyStatsDiv,
    towerSelectPanel,
    debugTableContainer
  ) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d");
    this.width = canvas.width;
    this.height = canvas.height;

    this.gold = 200;
    this.lives = 20;
    this.maxLives = 20;

    this.speedOptions = [1, 2, 4, 0.5];
    this.speedIndex = 0;
    this.gameSpeed = this.speedOptions[this.speedIndex];

    this.isFirstStart = true;
    this.paused = true;

    this.levelData = null;
    this.backgroundImg = null;
    this.path = [];
    this.towerSpots = [];
    this.enemies = [];

    this.globalEnemyHpMultiplier = 1.0;

    this.enemyManager = new EnemyManager(this);
    this.towerManager = new TowerManager(this);
    this.waveManager  = new WaveManager(this);
    this.heroManager  = new HeroManager(this);

    this.lastTime = 0;
    this.debugMode = true;

    const pauseBtn = document.getElementById("pauseButton");
    pauseBtn.innerHTML = "&#9658;"; // "▶"
    pauseBtn.addEventListener("click", () => {
      if (this.isFirstStart) {
        this.isFirstStart = false;
        this.paused = false;
        pauseBtn.innerHTML = "&#10073;&#10073;"; 
        return;
      }
      this.paused = !this.paused;
      pauseBtn.innerHTML = this.paused ? "&#9658;" : "&#10073;&#10073;";
    });

    const speedBtn = document.getElementById("speedToggleButton");
    speedBtn.addEventListener("click", () => {
      this.speedIndex = (this.speedIndex + 1) % this.speedOptions.length;
      this.gameSpeed = this.speedOptions[this.speedIndex];
      speedBtn.textContent = `${this.gameSpeed}x`;
    });

    this.canvas.addEventListener("click", (e) => this.handleCanvasClick(e));
  }

  setLevelData(data, bgImg) {
    this.levelData = data;
    this.backgroundImg = bgImg;

    const scaleX = this.width / data.mapWidth;
    const scaleY = this.height / data.mapHeight;

    this.path = data.path.map(pt => ({
      x: pt.x * scaleX,
      y: pt.y * scaleY,
    }));
    this.towerSpots = data.towerSpots.map(s => ({
      x: s.x * scaleX,
      y: s.y * scaleY,
      occupied: false,
    }));
    this.waveManager.loadWavesFromLevel(data);
  }

  start() {
    requestAnimationFrame((ts) => this.gameLoop(ts));
  }

  gameLoop(timestamp) {
    const delta = (timestamp - this.lastTime) || 0;
    this.lastTime = timestamp;
    let deltaSec = delta / 1000;
    deltaSec *= this.gameSpeed;

    if (!this.paused) {
      this.waveManager.update(deltaSec);
      this.enemyManager.update(deltaSec);
      this.towerManager.update(deltaSec);
      this.heroManager.update(deltaSec);
      // also handle collisions where enemies can fight with heroes
      // a simple approach is to do it in heroManager or enemyManager
      // but if we want to do “both sides deal damage,” we can do it there
    }

    this.draw();
    requestAnimationFrame((ts) => this.gameLoop(ts));
  }

  handleCanvasClick(e) {
    const rect = this.canvas.getBoundingClientRect();
    const mx = e.clientX - rect.left;
    const my = e.clientY - rect.top;
    if (this.uiManager && this.uiManager.handleCanvasClick) {
      // The UI manager is responsible for deciding if we clicked a hero, tower, enemy, spot, etc.
      this.uiManager.handleCanvasClick(mx, my, rect);

      // Also check if we’re setting a new rally for a selected tower (barracks)
      if (this.uiManager.selectedTower && this.uiManager.selectedTower.type === "barracks") {
        // We assume user wanted to set rally here
        const tower = this.uiManager.selectedTower;
        if (tower.unitGroup) {
          tower.unitGroup.setRallyPoint(mx, my);
        }
        // done
        this.uiManager.selectedTower = null;
      }
    }
  }

  draw() {
    if (this.backgroundImg) {
      this.ctx.drawImage(this.backgroundImg, 0, 0, this.width, this.height);
    } else {
      this.ctx.clearRect(0, 0, this.width, this.height);
    }

    // Enemies
    this.enemies.forEach(enemy => {
      this.enemyManager.drawEnemy(this.ctx, enemy);
    });

    // Projectiles
    this.towerManager.drawProjectiles(this.ctx);

    // Towers (and their units)
    this.towerManager.drawTowers(this.ctx);

    // Heroes
    this.heroManager.draw(this.ctx);

    // Path debug
    if (this.debugMode) {
      this.ctx.fillStyle = "yellow";
      this.path.forEach((wp, i) => {
        this.ctx.beginPath();
        this.ctx.arc(wp.x, wp.y, 5, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.fillStyle = "white";
        this.ctx.fillText(`P${i}`, wp.x - 10, wp.y - 10);
        this.ctx.fillStyle = "yellow";
      });
    }

    // Tower spots debug
    if (this.debugMode) {
      this.ctx.fillStyle = "rgba(0,255,0,0.5)";
      this.towerSpots.forEach((spot, i) => {
        this.ctx.beginPath();
        this.ctx.arc(spot.x, spot.y, 20, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.fillStyle = "white";
        this.ctx.fillText(`T${i}`, spot.x-10, spot.y-25);
        this.ctx.fillStyle = "rgba(0,255,0,0.5)";
      });
    }

    // HUD
    this.ctx.fillStyle = "white";
    this.ctx.fillText(`Gold: ${this.gold}`, 10, 50);
    this.ctx.fillText(`Wave: ${this.waveManager.waveIndex + 1}/${this.waveManager.waves.length}`, 10, 70);
    this.ctx.fillText(`Lives: ${this.lives}/${this.maxLives}`, 10, 90);

    if (!this.waveManager.waveActive && this.waveManager.waveIndex < this.waveManager.waves.length) {
      this.ctx.fillText("Next wave is ready", 10, 110);
    }
  }
}
EOF

################################################################################
# OVERWRITE js/main.js
################################################################################
cat << 'EOF' > js/main.js
import { Game } from "./game.js";
import { level1Data } from "./maps/level1.js";
import { UIManager } from "./uiManager.js";
import { loadAllAssets } from "./assetLoader.js";

// We now have heroManager in game.js, but we also import everything in game

let enemyHpPercent = 100;
let game = null;
let lastStartingGold = 1000;

async function startGameWithGold(startingGold) {
  lastStartingGold = startingGold;
  const loseMessage = document.getElementById("loseMessage");
  const winMessage  = document.getElementById("winMessage");
  if (loseMessage) loseMessage.style.display = "none";
  if (winMessage)  winMessage.style.display = "none";

  const canvas = document.getElementById("gameCanvas");
  const enemyStatsDiv = document.getElementById("enemyStats");
  const towerSelectPanel = document.getElementById("towerSelectPanel");
  const debugTableContainer = document.getElementById("debugTableContainer");

  game = new Game(canvas, enemyStatsDiv, towerSelectPanel, debugTableContainer);
  game.lives = 20;
  game.maxLives = 20;
  game.gameOver = false;
  if (game.waveManager) {
    game.waveManager.waveIndex = 0;
    game.waveManager.waveActive = false;
  }

  const uiManager = new UIManager(
    game,
    enemyStatsDiv,
    towerSelectPanel,
    debugTableContainer,
    loseMessage,
    winMessage
  );
  uiManager.initDebugTable();
  game.uiManager = uiManager;

  game.globalEnemyHpMultiplier = enemyHpPercent / 100;

  const enemyTypes = [
    { name: "drone",         src: "assets/enemies/drone.png" },
    { name: "leaf_blower",   src: "assets/enemies/leaf_blower.png" },
    { name: "trench_digger", src: "assets/enemies/trench_digger.png" },
    { name: "trench_walker", src: "assets/enemies/trench_walker.png" },
  ];
  const { loadedEnemies, loadedBackground } = await loadAllAssets(
    enemyTypes,
    level1Data.background
  );
  game.enemyManager.setLoadedEnemyAssets(loadedEnemies);
  game.setLevelData(level1Data, loadedBackground);
  game.gold = startingGold;

  // Add one melee hero and one archer hero for demonstration
  // (You can expand to choose in a hero select screen, etc.)
  game.heroManager.addHero({
    name: "Knight Hero",
    x: 100,
    y: 100,
    maxHp: 200,
    damage: 15,
    isMelee: true,
    range: 20,        // Must be close
    speed: 80,
    attackInterval: 1.0
  });
  game.heroManager.addHero({
    name: "Archer Hero",
    x: 150,
    y: 150,
    maxHp: 120,
    damage: 10,
    isMelee: false,   // Not fully implemented ranged logic in this sample
    range: 40,        // a bit larger range if we wanted to do a real ranged system
    speed: 90,
    attackInterval: 1.2
  });

  game.start();
  const currentGameLabel = document.getElementById("currentGameLabel");
  if (currentGameLabel) {
    currentGameLabel.innerHTML = `Current game:<br>Starting gold: ${startingGold}, Enemy HP: ${enemyHpPercent}%`;
  }
}

window.addEventListener("load", async () => {
  const startGoldInput = document.getElementById("startingGoldInput");
  const restartGameButton = document.getElementById("restartGameButton");

  const settingsDialog       = document.getElementById("settingsDialog");
  const settingsButton       = document.getElementById("settingsButton");
  const settingsDialogClose  = document.getElementById("settingsDialogClose");

  const hpOptions = [];
  for (let v = 80; v <= 120; v += 5) {
    hpOptions.push(v);
  }
  const enemyHpSegment = document.getElementById("enemyHpSegment");
  if (enemyHpSegment) {
    enemyHpSegment.innerHTML = "";
    hpOptions.forEach(value => {
      const btn = document.createElement("button");
      btn.textContent = value + "%";
      btn.classList.add("enemyHpOption");
      if (value === enemyHpPercent) {
        btn.style.backgroundColor = "#444";
      }
      btn.addEventListener("click", () => {
        document.querySelectorAll(".enemyHpOption").forEach(b => {
          b.style.backgroundColor = "";
        });
        enemyHpPercent = value;
        btn.style.backgroundColor = "#444";
      });
      enemyHpSegment.appendChild(btn);
    });
  }

  await startGameWithGold(parseInt(startGoldInput.value) || 1000);

  restartGameButton.addEventListener("click", async () => {
    const desiredGold = parseInt(startGoldInput.value) || 0;
    await startGameWithGold(desiredGold);
  });

  settingsButton.addEventListener("click", () => {
    const style = settingsDialog.style.display;
    settingsDialog.style.display = (style === "none" || style === "") ? "block" : "none";
  });
  settingsDialogClose.addEventListener("click", () => {
    settingsDialog.style.display = "none";
  });

  const loseRestartBtn = document.getElementById("loseRestartBtn");
  const loseSettingsBtn = document.getElementById("loseSettingsBtn");
  const winRestartBtn  = document.getElementById("winRestartBtn");
  const winSettingsBtn = document.getElementById("winSettingsBtn");
  if (loseRestartBtn) {
    loseRestartBtn.addEventListener("click", async () => {
      document.getElementById("loseMessage").style.display = "none";
      await startGameWithGold(lastStartingGold);
    });
  }
  if (loseSettingsBtn) {
    loseSettingsBtn.addEventListener("click", () => {
      settingsDialog.style.zIndex = "10001";
      document.getElementById("loseMessage").style.zIndex = "10000";
      settingsDialog.style.display = "block";
    });
  }
  if (winRestartBtn) {
    winRestartBtn.addEventListener("click", async () => {
      document.getElementById("winMessage").style.display = "none";
      await startGameWithGold(lastStartingGold);
    });
  }
  if (winSettingsBtn) {
    winSettingsBtn.addEventListener("click", () => {
      settingsDialog.style.zIndex = "10001";
      document.getElementById("winMessage").style.zIndex = "10000";
      settingsDialog.style.display = "block";
    });
  }

  restartGameButton.addEventListener("click", () => {
    const loseMessage = document.getElementById("loseMessage");
    const winMessage = document.getElementById("winMessage");
    if (loseMessage) loseMessage.style.display = "none";
    if (winMessage)  winMessage.style.display = "none";
  });
});
EOF

################################################################################
# Finally, commit and push
################################################################################
git add .
git commit -m "Implement melee towers, hero logic, death/revival, manual hero movement, and debug table updates"
git push