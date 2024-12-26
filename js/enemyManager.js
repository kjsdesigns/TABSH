export class EnemyManager {
  constructor(game) {
    this.game = game;

    // Halved all base HP (50% of original)
    this.enemyBaseData = {
      drone: {
        baseHp: 15,
        gold: 5,
        baseSpeed: 80,
      },
      leaf_blower: {
        baseHp: 30,
        gold: 8,
        baseSpeed: 60,
      },
      trench_digger: {
        baseHp: 50,
        gold: 12,
        baseSpeed: 30,
      },
      trench_walker: {
        baseHp: 75,
        gold: 15,
        baseSpeed: 25,
      },
    };

    // Holds the loaded images, widths, heights, etc. from assetLoader.js
    this.loadedEnemyAssets = [];
  }

  setLoadedEnemyAssets(loadedEnemies) {
    this.loadedEnemyAssets = loadedEnemies;
  }

  spawnEnemy(type, hpMultiplier = 1) {
    const baseData = this.enemyBaseData[type] || this.enemyBaseData["drone"];
    const asset = this.loadedEnemyAssets.find(e => e.name === type)
      || this.loadedEnemyAssets[0];

    // 20% global HP reduction, then apply wave multiplier
    const finalHp = baseData.baseHp * 0.8 * hpMultiplier;

    // Random speed ~ ±20% around baseSpeed
    const speedFactor = 0.8 + Math.random() * 0.4;
    const finalSpeed = baseData.baseSpeed * speedFactor;

    const path = this.game.path;
    if (!path || path.length === 0) {
      console.warn("No path defined in Game; cannot spawn enemy properly.");
      return;
    }
    const firstWP = path[0];

    const enemy = {
      name: type,
      image: asset.image,
      width: asset.width,
      height: asset.height,
      x: firstWP.x,
      y: firstWP.y,
      hp: finalHp,
      baseHp: finalHp,
      speed: finalSpeed,
      gold: baseData.gold,
      waypointIndex: 1,
      dead: false,
    };

    this.game.enemies.push(enemy);
  }

  update(deltaSec) {
    // If gameOver, do not update enemies
    if (this.game.gameOver) return;

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

    // Remove dead or off-screen enemies
    this.game.enemies = this.game.enemies.filter(e => {
      if (e.dead) return false;
      if (e.x > this.game.width + e.width) {
        this.game.lives -= 1;
        if (this.game.lives <= 0 && !this.game.gameOver) {
          this.game.lives = 0; 
          this.game.endGame("Game Over");
        }
        return false;
      }
      return true;
    });
  }

  updateEnemy(enemy, deltaSec) {
    const path = this.game.path;
    const nextWP = path[enemy.waypointIndex];
    if (!nextWP) {
      // No next WP => just move off-screen
      enemy.x += enemy.speed * deltaSec;
      return;
    }

    // Move toward next waypoint
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
    this.drawImageSafely(
      ctx,
      enemy.image,
      enemy.x - enemy.width / 2,
      enemy.y - enemy.height / 2,
      enemy.width,
      enemy.height
    );

    // HP bar
    if (enemy.hp < enemy.baseHp) {
      const barW = enemy.width;
      const barH = 4;
      const pct  = Math.max(0, enemy.hp / enemy.baseHp);

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
