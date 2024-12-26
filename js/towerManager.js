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
