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
    this.game.enemies = this.game.enemies.filter(e => !e.dead && e.x < this.game.width + e.width);
  }

  updateEnemy(enemy, deltaSec) {
    const path = this.game.path;
    const nextWP = path[enemy.waypointIndex];
    if (!nextWP) {
      // No next WP => keep moving off-screen horizontally
      enemy.x += enemy.speed * deltaSec;
      return;
    }

    // Move toward next waypoint
    const tx = nextWP.x - enemy.width / 2;
    const ty = nextWP.y - enemy.height / 2;
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
    // Safe image draw
    this.drawImageSafely(ctx, enemy.image, enemy.x, enemy.y, enemy.width, enemy.height);

    // HP bar if not full
    if (enemy.hp < enemy.baseHp) {
      const barW = enemy.width;
      const barH = 4;
      const pct  = Math.max(0, enemy.hp / enemy.baseHp);

      ctx.fillStyle = "red";
      ctx.fillRect(enemy.x, enemy.y - 6, barW, barH);

      ctx.fillStyle = "lime";
      ctx.fillRect(enemy.x, enemy.y - 6, barW * pct, barH);
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