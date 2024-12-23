export class TowerManager {
  constructor(game) {
    this.game = game;
    this.towers = [];
    this.projectiles = [];

    // Single data definition for tower types
    this.towerTypes = [
      {
        type: "point",
        basePrice: 80,
        // old range: 100 -> +30% => ~130
        range: 130,
        splashRadius: 0,
        fireRate: 1.5,
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
        // old range: 80 -> +30% => ~104
        range: 104,
        splashRadius: 50,
        fireRate: 1.5,
        upgrades: [
          { level: 1, damage: 8,  upgradeCost: 0   },
          { level: 2, damage: 12, upgradeCost: 50  },
          { level: 3, damage: 16, upgradeCost: 100 },
          { level: 4, damage: 20, upgradeCost: 150 },
        ],
      },
    ];
  }

  /** Return full tower definition so UIManager can build the debug table */
  getTowerData() {
    return this.towerTypes;
  }

  /** Create a tower from our definition (level 1) */
  createTower(towerTypeName) {
    const def = this.towerTypes.find(t => t.type === towerTypeName);
    if (!def) return null;

    const firstLvl = def.upgrades[0];
    return {
      type: def.type,
      level: 1,
      range: def.range,
      damage: firstLvl.damage,
      splashRadius: def.splashRadius,
      fireRate: def.fireRate,
      fireCooldown: 0,
      upgradeCost: def.upgrades[1] ? def.upgrades[1].upgradeCost : 0,
      maxLevel: def.upgrades.length,
      x: 0,
      y: 0,
      spot: null,
    };
  }

  update(deltaSec) {
    // Fire towers
    this.towers.forEach(tower => {
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
      const dist = Math.sqrt(dx * dx + dy * dy);

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

    // Clean up projectiles that have hit
    this.projectiles = this.projectiles.filter(p => !p.hit);
  }

  fireTower(tower) {
    // Find enemies in range
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

    // 4x4 projectile
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

    // Check gold
    if (this.game.gold < nextLvl.upgradeCost) return;

    // Spend gold
    this.game.gold -= nextLvl.upgradeCost;
    tower.level++;

    // Adjust tower stats
    tower.damage = nextLvl.damage;
    tower.upgradeCost = def.upgrades[tower.level]
      ? def.upgrades[tower.level].upgradeCost
      : 0;
  }

  drawTowers(ctx) {
    this.towers.forEach(t => {
      ctx.beginPath();
      ctx.arc(t.x, t.y, 12 + t.level * 2, 0, Math.PI * 2);
      ctx.fillStyle = (t.type === "point") ? "blue" : "red";
      ctx.fill();
      ctx.strokeStyle = "#fff";
      ctx.stroke();

      // Optional range circle
      ctx.beginPath();
      ctx.arc(t.x, t.y, t.range, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(255,255,255,0.3)";
      ctx.stroke();
    });
  }

  drawProjectiles(ctx) {
    ctx.fillStyle = "yellow";
    this.projectiles.forEach(proj => {
      ctx.fillRect(proj.x - 2, proj.y - 2, proj.w, proj.h);
    });
  }
}