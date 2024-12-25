import pygame
import os

from wave_manager import WaveManager
from enemy_manager import EnemyManager
from tower_manager import TowerManager
from ui_manager import UIManager

class Game:
    def __init__(self, width, height):
        self.width = width
        self.height = height

        # Speed handling (like JS: [1,2,4,0.5])
        self.speedOptions = [1, 2, 4, 0.5]
        self.speedIndex = 0
        self.gameSpeed = self.speedOptions[self.speedIndex]

        # Flow
        self.is_first_start = True
        self.paused = True

        # Stats
        self.startingGold = 1000  # This is the default starting gold (used on Restart)
        self.gold = self.startingGold
        self.lives = 20

        # Debug
        self.debug_mode = True

        # Enemies, towers, spots, path
        self.enemies = []
        self.tower_spots = []
        self.path = []
        self.background_img = None

        # Managers
        self.wave_manager = WaveManager(self)
        self.enemy_manager = EnemyManager(self)
        self.tower_manager = TowerManager(self)
        self.ui_manager = UIManager(self)

        # Load level data
        self.load_level_data()

    def load_level_data(self):
        level1Data = {
            "background": "assets/maps/level1.png",
            "mapWidth": 3530,
            "mapHeight": 2365,
            "path": [
                {"x": 420,  "y": 0},
                {"x": 800,  "y": 860},
                {"x": 1300, "y": 1550},
                {"x": 1500, "y": 1750},
                {"x": 1950, "y": 1920},
                {"x": 3530, "y": 1360},
            ],
            "towerSpots": [
                {"x": 1020, "y": 660},
                {"x": 620,  "y": 1280},
                {"x": 1340, "y": 1080},
                {"x": 1020, "y": 1660},
                {"x": 1800, "y": 1560},
                {"x": 2080, "y": 2150},
                {"x": 3250, "y": 1150},
            ],
            "waves": [
                {
                  "enemyGroups": [
                    {"type": "drone", "count": 5, "spawnInterval": 800, "hpMultiplier": 1.0},
                  ],
                },
                {
                  "enemyGroups": [
                    {"type": "drone", "count": 3, "spawnInterval": 700, "hpMultiplier": 1.1},
                    {"type": "leaf_blower", "count": 2, "spawnInterval": 1200, "hpMultiplier": 1.1},
                  ],
                },
                {
                  "enemyGroups": [
                    {"type": "leaf_blower", "count": 4, "spawnInterval": 1000, "hpMultiplier": 1.2},
                    {"type": "drone", "count": 3, "spawnInterval": 700, "hpMultiplier": 1.2},
                  ],
                },
                {
                  "enemyGroups": [
                    {"type": "trench_digger", "count": 4, "spawnInterval": 900, "hpMultiplier": 1.3},
                    {"type": "drone", "count": 4, "spawnInterval": 600, "hpMultiplier": 1.3},
                  ],
                },
                {
                  "enemyGroups": [
                    {"type": "trench_digger", "count": 5, "spawnInterval": 800, "hpMultiplier": 1.4},
                    {"type": "leaf_blower", "count": 4, "spawnInterval": 1200, "hpMultiplier": 1.4},
                  ],
                },
                {
                  "enemyGroups": [
                    {"type": "trench_walker", "count": 3, "spawnInterval": 1200, "hpMultiplier": 1.5},
                    {"type": "drone", "count": 4, "spawnInterval": 600, "hpMultiplier": 1.5},
                  ],
                },
                {
                  "enemyGroups": [
                    {"type": "trench_walker", "count": 4, "spawnInterval": 1200, "hpMultiplier": 1.6},
                    {"type": "leaf_blower", "count": 3, "spawnInterval": 900, "hpMultiplier": 1.6},
                  ],
                },
                {
                  "enemyGroups": [
                    {"type": "drone", "count": 6, "spawnInterval": 600, "hpMultiplier": 1.7},
                    {"type": "leaf_blower", "count": 4, "spawnInterval": 900, "hpMultiplier": 1.7},
                    {"type": "trench_digger", "count": 2, "spawnInterval": 800, "hpMultiplier": 1.7},
                  ],
                },
                {
                  "enemyGroups": [
                    {"type": "trench_digger", "count": 5, "spawnInterval": 700, "hpMultiplier": 1.8},
                    {"type": "trench_walker", "count": 3, "spawnInterval": 1300, "hpMultiplier": 1.8},
                  ],
                },
                {
                  "enemyGroups": [
                    {"type": "trench_walker", "count": 6, "spawnInterval": 1000, "hpMultiplier": 1.9},
                    {"type": "leaf_blower", "count": 5, "spawnInterval": 1000, "hpMultiplier": 1.9},
                  ],
                },
            ],
        }

        bg_path = level1Data["background"]
        if os.path.exists(bg_path):
            self.background_img = pygame.image.load(bg_path)
        else:
            print("Warning: background image not found at", bg_path)

        map_w = level1Data["mapWidth"]
        map_h = level1Data["mapHeight"]
        scale_x = self.width / map_w
        scale_y = self.height / map_h

        # Build scaled path
        self.path = []
        for pt in level1Data["path"]:
            self.path.append((int(pt["x"] * scale_x), int(pt["y"] * scale_y)))

        # Tower spots
        self.tower_spots = []
        for s in level1Data["towerSpots"]:
            self.tower_spots.append({
                "x": int(s["x"] * scale_x),
                "y": int(s["y"] * scale_y),
                "occupied": False
            })

        # Waves
        self.wave_manager.load_waves_from_level(level1Data)

    def update(self, delta_sec):
        # Multiply by game speed if not paused
        if not self.paused:
            delta_sec *= self.gameSpeed
            self.wave_manager.update(delta_sec)
            self.enemy_manager.update(delta_sec)
            self.tower_manager.update(delta_sec)

    def draw(self, screen):
        if self.background_img:
            scaled_bg = pygame.transform.scale(self.background_img, (self.width, self.height))
            screen.blit(scaled_bg, (0, 0))
        else:
            screen.fill((0, 0, 0))

        # Enemies
        for e in self.enemies:
            self.enemy_manager.draw_enemy(screen, e)

        # Projectiles
        self.tower_manager.draw_projectiles(screen)

        # Towers
        self.tower_manager.draw_towers(screen)

        # Debug spots + path
        if self.debug_mode:
            for i, spot in enumerate(self.tower_spots):
                pygame.draw.circle(screen, (0,255,0), (spot["x"], spot["y"]), 10)
                fontD = pygame.font.SysFont(None, 16)
                lbl = fontD.render(f"T{i}", True, (255,255,255))
                screen.blit(lbl, (spot["x"] - 12, spot["y"] - 20))

            for i, wp in enumerate(self.path):
                pygame.draw.circle(screen, (255,255,0), wp, 5)
                fontD = pygame.font.SysFont(None, 16)
                lbl = fontD.render(f"P{i}", True, (255,255,255))
                screen.blit(lbl, (wp[0] - 12, wp[1] - 20))

        # HUD text (gold, wave, lives)
        font = pygame.font.SysFont(None, 24)
        gold_txt = font.render(f"Gold: {self.gold}", True, (255,255,255))
        wave_txt = font.render(f"Wave: {self.wave_manager.wave_index+1}/{len(self.wave_manager.waves)}", True, (255,255,255))
        lives_txt = font.render(f"Lives: {self.lives}", True, (255,255,255))

        screen.blit(gold_txt, (10, 10))
        screen.blit(wave_txt, (10, 30))
        screen.blit(lives_txt, (10, 50))

        # Wave ready notice
        if (not self.wave_manager.wave_active and 
            self.wave_manager.wave_index < len(self.wave_manager.waves)):
            ready_txt = font.render("Next wave is ready!", True, (255,255,255))
            screen.blit(ready_txt, (10, 70))

        # Let UI manager draw top/bottom panels (buttons, debug info)
        self.ui_manager.draw_top_panel(screen)
        self.ui_manager.draw_bottom_panel(screen)
        self.ui_manager.draw_enemy_stats(screen)

    def handle_mouse_click(self, mx, my):
        """Delegate click handling to the UI manager first."""
        self.ui_manager.handle_ui_click(mx, my)

    # ------------------------------------------------
    # Additional methods for speed/pause/restart, etc.
    # ------------------------------------------------
    def toggle_speed(self):
        self.speedIndex = (self.speedIndex + 1) % len(self.speedOptions)
        self.gameSpeed = self.speedOptions[self.speedIndex]

    def toggle_pause(self):
        # If first start, unpause
        if self.is_first_start:
            self.is_first_start = False
            self.paused = False
        else:
            self.paused = not self.paused

    def resetGame(self, newGold):
        # Re-init the entire game
        self.__init__(self.width, self.height)
        self.startingGold = newGold
        self.gold = newGold
        self.lives = 20
        self.paused = True
        self.is_first_start = True