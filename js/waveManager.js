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
    // If game is over, no updates
    if (this.game.gameOver) return;

    // If no active wave, see if there's another wave
    if (!this.waveActive && this.waveIndex < this.waves.length) {
      this.timeUntilNextWave -= deltaSec;
      if (this.timeUntilNextWave <= 0) {
        this.startWave(this.waveIndex);
      }
    }

    // Check if current wave is finished
    if (this.waveActive) {
      const waveInfo = this.waves[this.waveIndex];
      const allSpawned = waveInfo.enemyGroups.every(g => g.spawnedCount >= g.count);
      if (allSpawned && this.game.enemies.length === 0) {
        // wave done
        this.waveActive = false;
        this.waveIndex++;
        this.timeUntilNextWave = 0;

        // If waveIndex == waves.length => all waves done => Victory
        if (this.waveIndex >= this.waves.length && !this.game.gameOver) {
          this.game.endGame("You Win!");
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
        if (this.game.gameOver) {
          clearInterval(timer);
          return;
        }
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
