export class WaveManager {
  constructor(game) {
    this.game = game;

    this.waveIndex = 0;
    this.waveActive = false;

    // No forced timeBetweenWaves
    this.timeUntilNextWave = 0;

    // We'll load waves later, once level data is set
    this.waves = [];
  }

  // Called after setLevelData() in Game
  loadWavesFromLevel(levelData) {
    this.waves = (levelData && levelData.waves) || [];
    console.log("Waves loaded (reloaded):", this.waves);
  }

  update(deltaSec) {
    // If wave not active, see if there's a wave to start
    if (!this.waveActive && this.waveIndex < this.waves.length) {
      this.timeUntilNextWave -= deltaSec;
      if (this.timeUntilNextWave <= 0) {
        this.startWave(this.waveIndex);
      }
    }

    // Check if wave is done
    if (this.waveActive) {
      const waveInfo = this.waves[this.waveIndex];
      // If all groups are fully spawned and no enemies left, wave is done
      const allSpawned =
        waveInfo.enemyGroups.every(g => g.spawnedCount >= g.count);
      if (allSpawned && this.game.enemies.length === 0) {
        // wave done
        this.waveActive = false;
        this.waveIndex++;

        // No downtime between waves in your setup
        this.timeUntilNextWave = 0;
      }
    }
  }

  startWave(index) {
    this.waveActive = true;
    const waveInfo = this.waves[index];

    // For each group, spawn them in parallel
    waveInfo.enemyGroups.forEach((group) => {
      group.spawnedCount = 0; // track how many have spawned
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
    // Find the matching enemy type
    const eType = this.game.enemyTypes.find(e => e.name === group.type)
                   || this.game.enemyTypes[0]; // fallback if not found

    // Calculate HP from multiplier
    const hp = Math.floor(eType.baseHp * group.hpMultiplier);

    // The actual spawn
    if (!this.game.path.length) return;
    const firstWP = this.game.path[0];
    this.game.enemies.push({
      ...eType,
      x: firstWP.x - eType.width / 2,
      y: firstWP.y - eType.height / 2,
      hp,
      baseHp: eType.baseHp, // for showing HP bar fraction
      waypointIndex: 1,
      dead: false,
    });
  }

  // Pressing "Send Next Wave Early" => if no wave is active, start next wave
  sendWaveEarly() {
    if (!this.waveActive && this.waveIndex < this.waves.length) {
      this.startWave(this.waveIndex);
    }
  }
}