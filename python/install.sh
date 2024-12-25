#!/bin/bash
# ----------------------------------------
# setup_game.sh
# Creates the folder structure and Python files
# for a Pygame-based tower defense game.
# ----------------------------------------

# 1) Make directories
mkdir -p my_python_td_game/assets/enemies
mkdir -p my_python_td_game/assets/maps

# 2) Create requirements.txt
cat << EOF > my_python_td_game/requirements.txt
pygame
EOF

# 3) Create main.py
cat << 'EOF' > my_python_td_game/main.py
import pygame
from game import Game

def main():
    # 1) Initialize pygame
    pygame.init()
    
    # 2) Create window
    width, height = 800, 600
    screen = pygame.display.set_mode((width, height))
    pygame.display.set_caption("Tower Defense in Python")
    
    # 3) Create a clock for managing FPS
    clock = pygame.time.Clock()
    
    # 4) Create our main Game object
    game = Game(width, height)

    # 5) Main loop
    running = True
    while running:
        delta_ms = clock.tick(60)  # ~60 FPS
        delta_sec = delta_ms / 1000.0

        # Handle events
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.MOUSEBUTTONDOWN:
                # On click, pass the position to the game
                mx, my = pygame.mouse.get_pos()
                game.handle_mouse_click(mx, my)
        
        # Update game logic
        game.update(delta_sec)

        # Draw everything
        screen.fill((0, 0, 0))  # black background if no map loaded
        game.draw(screen)

        # Flip the display buffer
        pygame.display.flip()

    pygame.quit()

if __name__ == "__main__":
    main()
EOF

# 4) Create game.py
cat << 'EOF' > my_python_td_game/game.py
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

        # Basic stats
        self.gold = 200
        self.lives = 20

        # Game flow
        self.paused = False
        self.is_first_start = True
        self.debug_mode = True

        # Enemies, towers, ...
        self.enemies = []
        self.tower_spots = []
        self.path = []
        self.background_img = None

        # Managers
        self.wave_manager = WaveManager(self)
        self.enemy_manager = EnemyManager(self)
        self.tower_manager = TowerManager(self)
        self.ui_manager = UIManager(self)

        # Load level data (similar to level1Data in your JS code)
        self.load_level_data()

    def load_level_data(self):
        """
        Hard-code or parse your `level1Data` from JS.
        """
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

        # Load background
        bg_path = level1Data["background"]
        if os.path.exists(bg_path):
            self.background_img = pygame.image.load(bg_path)
        else:
            print("Warning: background image not found at", bg_path)

        # Scale path points and tower spots to the actual game canvas
        map_w = level1Data["mapWidth"]
        map_h = level1Data["mapHeight"]
        scale_x = self.width / map_w
        scale_y = self.height / map_h

        # Path
        self.path = []
        for pt in level1Data["path"]:
            self.path.append((
                int(pt["x"] * scale_x),
                int(pt["y"] * scale_y)
            ))

        # Tower spots
        self.tower_spots = []
        for spot in level1Data["towerSpots"]:
            self.tower_spots.append({
                "x": int(spot["x"] * scale_x),
                "y": int(spot["y"] * scale_y),
                "occupied": False
            })

        # Waves
        self.wave_manager.load_waves_from_level(level1Data)

    def update(self, delta_sec):
        if not self.paused:
            self.wave_manager.update(delta_sec)
            self.enemy_manager.update(delta_sec)
            self.tower_manager.update(delta_sec)

    def draw(self, screen):
        # Draw background if loaded
        if self.background_img:
            bg_scaled = pygame.transform.scale(self.background_img, (self.width, self.height))
            screen.blit(bg_scaled, (0, 0))
        else:
            screen.fill((0, 0, 0))

        # Draw enemies
        for enemy in self.enemies:
            self.enemy_manager.draw_enemy(screen, enemy)

        # Draw projectiles
        self.tower_manager.draw_projectiles(screen)

        # Draw towers
        self.tower_manager.draw_towers(screen)

        # Draw tower spots (optional debug)
        if self.debug_mode:
            for i, spot in enumerate(self.tower_spots):
                pygame.draw.circle(screen, (0, 255, 0, 128), (spot["x"], spot["y"]), 10)
                font = pygame.font.SysFont(None, 16)
                txt = font.render(f"T{i}", True, (255, 255, 255))
                screen.blit(txt, (spot["x"] - 12, spot["y"] - 20))

        # Draw path debug
        if self.debug_mode:
            for i, wp in enumerate(self.path):
                pygame.draw.circle(screen, (255, 255, 0), wp, 5)
                font = pygame.font.SysFont(None, 16)
                txt = font.render(f"P{i}", True, (255, 255, 255))
                screen.blit(txt, (wp[0] - 12, wp[1] - 20))

        # HUD
        font = pygame.font.SysFont(None, 24)
        gold_text = font.render(f"Gold: {self.gold}", True, (255,255,255))
        screen.blit(gold_text, (10, 10))

        wave_text = font.render(
            f"Wave: {self.wave_manager.wave_index+1}/{len(self.wave_manager.waves)}",
            True,
            (255,255,255)
        )
        screen.blit(wave_text, (10, 30))

        lives_text = font.render(f"Lives: {self.lives}", True, (255,255,255))
        screen.blit(lives_text, (10, 50))

        if not self.wave_manager.wave_active and self.wave_manager.wave_index < len(self.wave_manager.waves):
            next_wave_text = font.render("Next wave is ready (Press 'Send Wave' if we had a button)", True, (255,255,255))
            screen.blit(next_wave_text, (10, 70))

        # Draw selected enemy stats
        self.ui_manager.draw_enemy_stats(screen)

    def handle_mouse_click(self, mx, my):
        self.ui_manager.handle_canvas_click(mx, my)
EOF

# 5) Create wave_manager.py
cat << 'EOF' > my_python_td_game/wave_manager.py
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
EOF

# 6) Create enemy_manager.py
cat << 'EOF' > my_python_td_game/enemy_manager.py
import pygame
import math
import random
import os

class EnemyManager:
    def __init__(self, game):
        self.game = game

        self.enemy_base_data = {
            "drone": {
                "baseHp": 30,
                "gold": 5,
                "baseSpeed": 80,
            },
            "leaf_blower": {
                "baseHp": 60,
                "gold": 8,
                "baseSpeed": 60,
            },
            "trench_digger": {
                "baseHp": 100,
                "gold": 12,
                "baseSpeed": 30,
            },
            "trench_walker": {
                "baseHp": 150,
                "gold": 15,
                "baseSpeed": 25,
            }
        }

        self.loaded_enemy_assets = {}
        for e_type in self.enemy_base_data.keys():
            image_path = os.path.join("assets", "enemies", f"{e_type}.png")
            if os.path.exists(image_path):
                img = pygame.image.load(image_path)
                max_dim = 30
                iw, ih = img.get_size()
                scale = max_dim / max(iw, ih)
                new_size = (int(iw * scale), int(ih * scale))
                scaled_img = pygame.transform.scale(img, new_size)
                self.loaded_enemy_assets[e_type] = scaled_img
            else:
                print(f"Warning: {image_path} not found.")
                surface = pygame.Surface((30,30))
                surface.fill((255,0,0))
                self.loaded_enemy_assets[e_type] = surface

    def update(self, delta_sec):
        to_remove = []
        for enemy in self.game.enemies:
            self.update_enemy(enemy, delta_sec)
            if enemy["hp"] <= 0:
                self.game.gold += enemy["gold"]
                to_remove.append(enemy)
            else:
                if enemy["waypointIndex"] >= len(self.game.path):
                    self.game.lives -= 1
                    if self.game.lives <= 0:
                        self.game.lives = 0
                        self.game.paused = True
                        print("Game Over")
                    to_remove.append(enemy)

        self.game.enemies = [e for e in self.game.enemies if e not in to_remove]

    def update_enemy(self, enemy, delta_sec):
        path = self.game.path
        if enemy["waypointIndex"] < len(path):
            next_wp = path[enemy["waypointIndex"]]
            ex, ey = enemy["x"], enemy["y"]
            tx, ty = next_wp
            dx, dy = tx - ex, ty - ey
            dist = math.hypot(dx, dy)
            step = enemy["speed"] * delta_sec

            if dist <= step:
                enemy["x"] = tx
                enemy["y"] = ty
                enemy["waypointIndex"] += 1
            else:
                enemy["x"] += (dx / dist) * step
                enemy["y"] += (dy / dist) * step

    def draw_enemy(self, screen, enemy):
        img = enemy["image"]
        rect = img.get_rect(center=(enemy["x"], enemy["y"]))
        screen.blit(img, rect)

        if enemy["hp"] < enemy["baseHp"]:
            bar_w = img.get_width()
            bar_h = 4
            pct = max(0, enemy["hp"] / enemy["baseHp"])
            bar_x = enemy["x"] - bar_w / 2
            bar_y = enemy["y"] - img.get_height() / 2 - 6
            pygame.draw.rect(screen, (255,0,0), (bar_x, bar_y, bar_w, bar_h))
            pygame.draw.rect(screen, (0,255,0), (bar_x, bar_y, bar_w * pct, bar_h))

    def spawn_enemy(self, e_type, hp_multiplier=1.0):
        base_data = self.enemy_base_data.get(e_type, self.enemy_base_data["drone"])
        asset = self.loaded_enemy_assets.get(e_type, self.loaded_enemy_assets["drone"])

        final_hp = base_data["baseHp"] * 0.8 * hp_multiplier
        speed_factor = 0.8 + random.random() * 0.4
        final_speed = base_data["baseSpeed"] * speed_factor

        if not self.game.path:
            print("No path defined, cannot spawn enemy!")
            return

        first_wp = self.game.path[0]
        enemy = {
            "name": e_type,
            "image": asset,
            "width": asset.get_width(),
            "height": asset.get_height(),
            "x": float(first_wp[0]),
            "y": float(first_wp[1]),
            "hp": final_hp,
            "baseHp": final_hp,
            "speed": final_speed,
            "gold": base_data["gold"],
            "waypointIndex": 1,
            "dead": False
        }
        self.game.enemies.append(enemy)
EOF

# 7) Create tower_manager.py
cat << 'EOF' > my_python_td_game/tower_manager.py
import math
import pygame

class TowerManager:
    def __init__(self, game):
        self.game = game
        self.towers = []
        self.projectiles = []

        self.tower_types = [
            {
                "type": "point",
                "basePrice": 80,
                "range": 169,
                "splashRadius": 0,
                "fireRate": 1.5,
                "upgrades": [
                    { "level": 1, "damage": 10, "upgradeCost": 0   },
                    { "level": 2, "damage": 15, "upgradeCost": 50  },
                    { "level": 3, "damage": 20, "upgradeCost": 100 },
                    { "level": 4, "damage": 25, "upgradeCost": 150 },
                ],
            },
            {
                "type": "splash",
                "basePrice": 80,
                "range": 104,
                "splashRadius": 50,
                "fireRate": 1.5,
                "upgrades": [
                    { "level": 1, "damage": 8,  "upgradeCost": 0   },
                    { "level": 2, "damage": 12, "upgradeCost": 50  },
                    { "level": 3, "damage": 16, "upgradeCost": 100 },
                    { "level": 4, "damage": 20, "upgradeCost": 150 },
                ],
            },
        ]

    def get_tower_data(self):
        return self.tower_types

    def create_tower(self, tower_type_name, x, y, spot):
        definition = next((t for t in self.tower_types if t["type"] == tower_type_name), None)
        if not definition:
            return None

        lvl_data = definition["upgrades"][0]
        tower = {
            "type": definition["type"],
            "level": lvl_data["level"],
            "damage": lvl_data["damage"],
            "range": definition["range"],
            "splashRadius": definition["splashRadius"],
            "fireRate": definition["fireRate"],
            "fireCooldown": 0.0,
            "upgradeCost": definition["upgrades"][1]["upgradeCost"] if len(definition["upgrades"]) > 1 else 0,
            "maxLevel": len(definition["upgrades"]),
            "x": x,
            "y": y,
            "spot": spot,
        }
        self.towers.append(tower)
        return tower

    def update(self, delta_sec):
        for tower in self.towers:
            tower["fireCooldown"] -= delta_sec
            if tower["fireCooldown"] <= 0:
                self.fire_tower(tower)
                tower["fireCooldown"] = tower["fireRate"]

        to_remove = []
        for proj in self.projectiles:
            self.update_projectile(proj, delta_sec)
            if proj["hit"]:
                if proj["splashRadius"] > 0:
                    for enemy in self.game.enemies:
                        dx = enemy["x"] - proj["targetX"]
                        dy = enemy["y"] - proj["targetY"]
                        dist2 = dx*dx + dy*dy
                        if dist2 <= (proj["splashRadius"] ** 2):
                            if enemy == proj["mainTarget"]:
                                enemy["hp"] -= proj["damage"]
                            else:
                                enemy["hp"] -= (proj["damage"] / 2.0)
                else:
                    if proj["mainTarget"] in self.game.enemies:
                        proj["mainTarget"]["hp"] -= proj["damage"]
                to_remove.append(proj)

        self.projectiles = [p for p in self.projectiles if p not in to_remove]

    def update_projectile(self, proj, delta_sec):
        step = proj["speed"] * delta_sec
        dx = proj["targetX"] - proj["x"]
        dy = proj["targetY"] - proj["y"]
        dist = math.hypot(dx, dy)
        if dist <= step:
            proj["x"] = proj["targetX"]
            proj["y"] = proj["targetY"]
            proj["hit"] = True
        else:
            proj["x"] += (dx / dist) * step
            proj["y"] += (dy / dist) * step

    def fire_tower(self, tower):
        in_range_enemies = []
        for enemy in self.game.enemies:
            dx = enemy["x"] - tower["x"]
            dy = enemy["y"] - tower["y"]
            dist2 = dx*dx + dy*dy
            if dist2 <= (tower["range"]*tower["range"]):
                in_range_enemies.append(enemy)

        if not in_range_enemies:
            return

        target = in_range_enemies[0]
        proj = {
            "x": tower["x"],
            "y": tower["y"],
            "speed": 300,
            "damage": tower["damage"],
            "splashRadius": tower["splashRadius"],
            "mainTarget": target,
            "targetX": target["x"],
            "targetY": target["y"],
            "hit": False,
            "w": 4,
            "h": 4
        }
        self.projectiles.append(proj)

    def upgrade_tower(self, tower):
        definition = next((t for t in self.tower_types if t["type"] == tower["type"]), None)
        if not definition:
            return
        if tower["level"] >= len(definition["upgrades"]):
            return

        next_lvl_index = tower["level"]
        next_lvl_data = definition["upgrades"][next_lvl_index]
        cost = next_lvl_data["upgradeCost"]
        if self.game.gold < cost:
            return

        self.game.gold -= cost
        tower["level"] += 1
        tower["damage"] = next_lvl_data["damage"]
        if tower["level"] < tower["maxLevel"]:
            tower["upgradeCost"] = definition["upgrades"][tower["level"]]["upgradeCost"]
        else:
            tower["upgradeCost"] = 0

    def draw_towers(self, screen):
        for tower in self.towers:
            rad = 12 + tower["level"] * 2
            color = (0,0,255) if tower["type"] == "point" else (255,0,0)
            pygame.draw.circle(screen, color, (tower["x"], tower["y"]), rad, 0)
            pygame.draw.circle(screen, (255,255,255), (tower["x"], tower["y"]), rad, 1)

            if self.game.debug_mode:
                pygame.draw.circle(
                    screen, (255,255,255),
                    (tower["x"], tower["y"]),
                    tower["range"], 1
                )

    def draw_projectiles(self, screen):
        for proj in self.projectiles:
            rect = pygame.Rect(proj["x"] - 2, proj["y"] - 2, proj["w"], proj["h"])
            pygame.draw.rect(screen, (255, 255, 0), rect)
EOF

# 8) Create ui_manager.py
cat << 'EOF' > my_python_td_game/ui_manager.py
import pygame

class UIManager:
    def __init__(self, game):
        self.game = game
        self.selected_enemy = None

    def handle_canvas_click(self, mx, my):
        # Check tower spots
        for spot in self.game.tower_spots:
            dx = mx - spot["x"]
            dy = my - spot["y"]
            if dx*dx + dy*dy <= 100:  # ~10 px radius
                existing_tower = None
                for t in self.game.tower_manager.towers:
                    if t["spot"] == spot:
                        existing_tower = t
                        break
                if existing_tower:
                    self.game.tower_manager.upgrade_tower(existing_tower)
                else:
                    tower_data = self.game.tower_manager.get_tower_data()[0]  # "point" tower
                    cost = tower_data["basePrice"]
                    if self.game.gold >= cost and not spot["occupied"]:
                        self.game.gold -= cost
                        self.game.tower_manager.create_tower(tower_data["type"], spot["x"], spot["y"], spot)
                        spot["occupied"] = True
                return

        # Check enemies
        for enemy in self.game.enemies:
            left   = enemy["x"] - enemy["width"] / 2
            right  = enemy["x"] + enemy["width"] / 2
            top    = enemy["y"] - enemy["height"] / 2
            bottom = enemy["y"] + enemy["height"] / 2
            if (mx >= left and mx <= right and my >= top and my <= bottom):
                self.selected_enemy = enemy
                return

        self.selected_enemy = None

    def draw_enemy_stats(self, screen):
        if not self.selected_enemy:
            return

        enemy = self.selected_enemy
        font = pygame.font.SysFont(None, 20)

        panel_x = 10
        panel_y = self.game.height - 80
        panel_w = 200
        panel_h = 70

        s = pygame.Surface((panel_w, panel_h), pygame.SRCALPHA)
        s.fill((0, 0, 0, 180))
        screen.blit(s, (panel_x, panel_y))

        name_text = font.render(f"Name: {enemy['name']}", True, (255,255,255))
        hp_text = font.render(f"HP: {int(enemy['hp'])}/{int(enemy['baseHp'])}", True, (255,255,255))
        speed_text = font.render(f"Speed: {int(enemy['speed'])}", True, (255,255,255))
        gold_text = font.render(f"Gold on Kill: {enemy['gold']}", True, (255,255,255))

        screen.blit(name_text, (panel_x+10, panel_y+5))
        screen.blit(hp_text, (panel_x+10, panel_y+25))
        screen.blit(speed_text, (panel_x+10, panel_y+40))
        screen.blit(gold_text, (panel_x+10, panel_y+55))
EOF

# 9) Final message
echo "---------------------------------------------------------"
echo "Project setup complete. Next steps:"
echo "1) Copy your enemy images (drone.png, leaf_blower.png, etc.) into my_python_td_game/assets/enemies/"
echo "2) Copy your level1.png background into my_python_td_game/assets/maps/"
echo "3) cd my_python_td_game"
echo "4) pip install -r requirements.txt"
echo "5) python main.py"
echo "---------------------------------------------------------"