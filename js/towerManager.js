import { TOWER_DEFINITIONS } from "./data/towerConfig.js";

export class TowerManager {
  constructor(game) {
    this.game = game;
    this.towers = [];
    this.projectiles = [];

    // We no longer embed tower data here; we import from TOWER_DEFINITIONS
    this.towerTypes = TOWER_DEFINITIONS;
  }

  getTowerData() {
    return this.towerTypes;
  }

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
      goldSpent: def.basePrice,
    };
  }

  update(deltaSec) {
    if (this.game.gameOver) return;

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
    if (tower.level >= def.upgrades.length) return;

    const nextLvlIndex = tower.level;
    const nextLvl = def.upgrades[nextLvlIndex];
    if (!nextLvl) return;
    if (this.game.gold < nextLvl.upgradeCost) return;

    // Spend gold
    this.game.gold -= nextLvl.upgradeCost;
    tower.goldSpent += nextLvl.upgradeCost;
    tower.level++;

    tower.damage = nextLvl.damage;
    tower.upgradeCost = def.upgrades[tower.level]
      ? def.upgrades[tower.level].upgradeCost
      : 0;
  }

  sellTower(tower) {
    const refund = Math.floor(tower.goldSpent * 0.8);
    this.game.gold += refund;
    this.towers = this.towers.filter(t => t !== tower);
    if (tower.spot) tower.spot.occupied = false;
  }

  drawTowers(ctx) {
    this.towers.forEach(t => {
      const drawRadius = 24 + t.level * 4;
      ctx.beginPath();
      ctx.arc(t.x, t.y, drawRadius, 0, Math.PI * 2);
      ctx.fillStyle = (t.type === "point") ? "blue" : "red";
      ctx.fill();
      ctx.strokeStyle = "#fff";
      ctx.stroke();

      // optional range circle
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
