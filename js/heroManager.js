/**
 * heroManager.js
 * 
 * Basic approach for a single hero:
 * - Hero is placed near path[0]
 * - Moves toward nearest enemy within range, or stands idle if none
 * - Attack is a placeholder
 */

export class HeroManager {
  constructor(game, heroType) {
    this.game = game;
    this.heroType = heroType || "melee";
    // Basic hero stats, vary by type
    if (this.heroType === "archer") {
      this.range = 150;
      this.damage = 10;
      this.speed = 100; // moves faster
    } else {
      // melee
      this.range = 50;
      this.damage = 15;
      this.speed = 70;
    }
    this.x = 0;
    this.y = 0;
    this.w = 24;
    this.h = 24;

    // Quick approach: place hero at path start
    if (game.path && game.path.length > 0) {
      this.x = game.path[0].x;
      this.y = game.path[0].y;
    }

    this.targetEnemy = null;
    this.attackCooldown = 0;
    this.attackRate = 1.5; // 1 attack every 1.5 seconds
  }

  update(deltaSec) {
    if (!this.game.enemies.length) {
      // no enemies => stand still
      this.targetEnemy = null;
      return;
    }

    // find or confirm target
    if (!this.targetEnemy || this.targetEnemy.dead) {
      this.targetEnemy = this.findClosestEnemy();
    }

    // if we have a target
    if (this.targetEnemy) {
      // move to it if not in range
      const ex = this.targetEnemy.x;
      const ey = this.targetEnemy.y;
      const dx = ex - this.x;
      const dy = ey - this.y;
      const dist = Math.sqrt(dx*dx + dy*dy);

      if (dist > this.range) {
        // approach
        const step = this.speed * deltaSec;
        if (dist <= step) {
          this.x = ex;
          this.y = ey;
        } else {
          this.x += (dx/dist) * step;
          this.y += (dy/dist) * step;
        }
      } else {
        // in range => attack
        this.attackCooldown -= deltaSec;
        if (this.attackCooldown <= 0) {
          this.targetEnemy.hp -= this.damage;
          this.attackCooldown = this.attackRate;
        }
      }
    }
  }

  findClosestEnemy() {
    let bestEnemy = null;
    let bestDist = 999999;
    this.game.enemies.forEach(e => {
      if (!e.dead) {
        const dx = e.x - this.x;
        const dy = e.y - this.y;
        const dist = Math.sqrt(dx*dx + dy*dy);
        if (dist < bestDist) {
          bestDist = dist;
          bestEnemy = e;
        }
      }
    });
    return bestEnemy;
  }

  draw(ctx) {
    // For now, a simple placeholder circle
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.w / 2, 0, Math.PI * 2);
    ctx.fillStyle = (this.heroType === "archer") ? "orange" : "purple";
    ctx.fill();

    // For debugging, can show a range circle
    ctx.beginPath();
    ctx.arc(this.x, this.y, this.range, 0, Math.PI * 2);
    ctx.strokeStyle = "rgba(255,255,0,0.3)";
    ctx.stroke();
  }
}
