import { awardStars } from "./main.js";

export class WaveManager {
  constructor(game) {
    this.game = game;
    this.waveIndex = 0;
    this.waveActive = false;
    this.timeUntilNextWave = 0;
    this.waves = [];
  }

  loadWavesFromLevel(levelData) {
    this.waves = (levelData && levelData.waves) || [];
    console.log("Waves loaded (reloaded):", this.waves);
  }

  update(deltaSec) {
    if (!this.waveActive && this.waveIndex < this.waves.length) {
      this.timeUntilNextWave -= deltaSec;
      if (this.timeUntilNextWave <= 0) {
        this.startWave(this.waveIndex);
      }
    }

    if (this.waveActive) {
      const waveInfo = this.waves[this.waveIndex];
      const allSpawned = waveInfo.enemyGroups.every(g => g.spawnedCount >= g.count);
      if (allSpawned && this.game.enemies.length === 0) {
        // wave done
        this.waveActive = false;
        this.waveIndex++;

        if (this.waveIndex >= this.waves.length) {
          // last wave done
          if (this.game.lives > 0 && this.game.uiManager) {
            this.game.paused = true;
            this.game.uiManager.showWinDialog(this.game.lives, this.game.maxLives);
            // Suppose we do a star rating calculation
            // e.g. if you have >= 18 lives => 3 stars, >=10 => 2 stars, else 1 star
            let starCount = 1;
            if (this.game.lives >= 18) starCount = 3;
            else if (this.game.lives >= 10) starCount = 2;
            awardStars(starCount);
          }
        } else {
          this.timeUntilNextWave = 0;
        }
      }
    }
  }

  startWave(index) {
    this.waveActive = true;
    const waveInfo = this.waves[index];
    waveInfo.enemyGroups.forEach(group => {
      group.spawnedCount = 0;
      const timer = setInterval(() => {
        if (group.spawnedCount >= group.count) {
          clearInterval(timer);
          return;
        }
        this.spawnEnemyGroup(group);
        group.spawnedCount++;
      }, group.spawnInterval);
    });
  }

  spawnEnemyGroup(group) {
    this.game.enemyManager.spawnEnemy(group.type, group.hpMultiplier);
  }

  sendWaveEarly() {
    if (!this.waveActive && this.waveIndex < this.waves.length) {
      this.startWave(this.waveIndex);
    }
  }
}
