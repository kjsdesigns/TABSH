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
