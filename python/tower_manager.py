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
