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
