class WaveManager:
    def __init__(self, game):
        self.game = game
        self.wave_index = 0
        self.wave_active = False
        self.time_until_next_wave = 0.0
        self.waves = []

    def load_waves_from_level(self, levelData):
        self.waves = levelData.get("waves", [])
        print("Waves loaded:", self.waves)

    def update(self, delta_sec):
        # If wave not active, see if there's another wave to start
        if not self.wave_active and self.wave_index < len(self.waves):
            self.time_until_next_wave -= delta_sec
            if self.time_until_next_wave <= 0:
                self.start_wave(self.wave_index)

        # If wave is active, update spawn timers
        if self.wave_active:
            wave_info = self.waves[self.wave_index]
            for group in wave_info["enemyGroups"]:
                if group.get("spawnedCount", 0) < group["count"]:
                    group.setdefault("timerAcc", 0.0)
                    if "spawnIntervalSec" not in group:
                        group["spawnIntervalSec"] = group["spawnInterval"] / 1000.0

                    group["timerAcc"] += delta_sec
                    if group["timerAcc"] >= group["spawnIntervalSec"]:
                        group["timerAcc"] -= group["spawnIntervalSec"]
                        self.game.enemy_manager.spawn_enemy(
                            group["type"],
                            group["hpMultiplier"]
                        )
                        group["spawnedCount"] = group.get("spawnedCount", 0) + 1

            # Check if wave is done
            all_spawned = True
            for group in wave_info["enemyGroups"]:
                if group.get("spawnedCount", 0) < group["count"]:
                    all_spawned = False
                    break

            if all_spawned and len(self.game.enemies) == 0:
                self.wave_active = False
                self.wave_index += 1
                self.time_until_next_wave = 0

    def start_wave(self, index):
        self.wave_active = True
        wave_info = self.waves[index]
        for group in wave_info["enemyGroups"]:
            group["spawnedCount"] = 0
            group["timerAcc"] = 0.0
            group["spawnIntervalSec"] = group["spawnInterval"] / 1000.0

    def send_wave_early(self):
        if not self.wave_active and self.wave_index < len(self.waves):
            self.start_wave(self.wave_index)
