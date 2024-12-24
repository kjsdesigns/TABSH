export class EnemyManager {
  constructor(game) {
    this.game = game;
  }

  update(deltaSec) {
    // Move enemies, handle death
    this.game.enemies.forEach(e => {
      this.updateEnemy(e, deltaSec);
      if (e.hp <= 0) {
        this.game.gold += e.gold || 0;
        e.dead = true;
        // If this was the selected enemy, clear selection
        if (this.game.uiManager && this.game.uiManager.selectedEnemy === e) {
          this.game.uiManager.selectedEnemy = null;
          this.game.uiManager.hideEnemyStats();
        }
      }
    });

    // Remove dead enemies
    this.game.enemies = this.game.enemies.filter(e => {
      // If the enemy is "dead," remove it immediately
      if (e.dead) return false;

      // If the enemy is off-screen (beyond the right side?), lose a life
      // We'll assume the path leads to the right edge.
      // You can adjust if your path ends somewhere else.
      if (e.x > this.game.width + e.width) {
        this.game.lives -= 1;
        if (this.game.lives <= 0) {
          this.game.lives = 0; 
          this.game.paused = true;
          alert("Game Over");
        }
        return false;
      }

      // Otherwise, keep the enemy
      return true;
    });
  }

  updateEnemy(enemy, deltaSec) {
    const path = this.game.path;
    const nextWP = path[enemy.waypointIndex];
    if (!nextWP) {
      // No next WP => just keep moving off-screen
      enemy.x += enemy.speed * deltaSec;
      return;
    }

    // Move toward next waypoint, which is now the center
    const tx = nextWP.x;
    const ty = nextWP.y;
    const dx = tx - enemy.x;
    const dy = ty - enemy.y;
    const dist = Math.sqrt(dx * dx + dy * dy);
    const step = enemy.speed * deltaSec;

    if (dist <= step) {
      enemy.x = tx;
      enemy.y = ty;
      enemy.waypointIndex++;
    } else {
      enemy.x += (dx / dist) * step;
      enemy.y += (dy / dist) * step;
    }
  }

  drawEnemy(ctx, enemy) {
    // Instead of drawing at (enemy.x, enemy.y) top-left,
    // we draw so that (enemy.x, enemy.y) is the center
    this.drawImageSafely(
      ctx,
      enemy.image,
      enemy.x - enemy.width / 2,
      enemy.y - enemy.height / 2,
      enemy.width,
      enemy.height
    );

    // HP bar if not full
    if (enemy.hp < enemy.baseHp) {
      const barW = enemy.width;
      const barH = 4;
      const pct  = Math.max(0, enemy.hp / enemy.baseHp);

      // We also offset the bar by half so it aligns with the center
      const barX = enemy.x - barW / 2;
      const barY = enemy.y - enemy.height / 2 - 6;

      ctx.fillStyle = "red";
      ctx.fillRect(barX, barY, barW, barH);

      ctx.fillStyle = "lime";
      ctx.fillRect(barX, barY, barW * pct, barH);
    }
  }

  drawImageSafely(ctx, image, x, y, w, h) {
    if (image.complete && image.naturalHeight !== 0) {
      ctx.drawImage(image, x, y, w, h);
    } else {
      console.warn("Image not loaded or invalid:", image);
    }
  }
}