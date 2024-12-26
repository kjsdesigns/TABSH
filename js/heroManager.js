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
