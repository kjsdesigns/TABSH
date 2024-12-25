import pygame

class UIManager:
    def __init__(self, game):
        self.game = game
        self.selected_enemy = None

        # We'll anchor the buttons from the right side of the window (which is 800 wide by default).
        # Each button has a width; we set x = self.game.width - (some offset).
        sendWaveBtn = {
            "label": "Send Wave", 
            "x": self.game.width - 120,  # 800 - 120 = 680
            "y": 10, 
            "w": 110, 
            "h": 24, 
            "action": "sendwave"
        }

        pauseBtn = {
            "label": "Start", 
            "x": self.game.width - 190,  # 800 - 190 = 610
            "y": 10, 
            "w": 60, 
            "h": 24, 
            "action": "pause"
        }

        speedBtn = {
            "label": "1x", 
            "x": self.game.width - 240,  # 800 - 240 = 560
            "y": 10, 
            "w": 40, 
            "h": 24, 
            "action": "speed"
        }

        self.top_buttons = [speedBtn, pauseBtn, sendWaveBtn]

        self.debug_toggle_button = {
            "label": "Disable Debug", 
            "x": 10, 
            "y": None, 
            "w": 120, 
            "h": 24, 
            "action": "debugToggle"
        }

        self.gold_minus_button = {
            "label": "-",   
            "x": None, 
            "y": None, 
            "w": 24, 
            "h": 24, 
            "action": "goldMinus"
        }
        self.gold_plus_button = {
            "label": "+",   
            "x": None, 
            "y": None, 
            "w": 24, 
            "h": 24, 
            "action": "goldPlus"
        }
        self.restart_button = {
            "label": "Restart", 
            "x": None, 
            "y": None, 
            "w": 80, 
            "h": 24, 
            "action": "restart"
        }

        self.show_debug_table = True

    # ---------------------------------------
    # Drawing the top panel
    # ---------------------------------------
    def draw_top_panel(self, screen):
        """Draw the top-row buttons (speed, pause, send wave)."""
        # Update labels in real-time
        speedBtn = self.top_buttons[0]
        pauseBtn = self.top_buttons[1]
        sendBtn  = self.top_buttons[2]

        # Speed label
        speedBtn["label"] = f"{self.game.gameSpeed}x"

        # Pause/Resume label
        if self.game.is_first_start:
            pauseBtn["label"] = "Start"
        else:
            pauseBtn["label"] = "Pause" if not self.game.paused else "Resume"

        # Just draw them
        for btn in self.top_buttons:
            self.draw_button(screen, btn)

    # ---------------------------------------
    # Drawing the bottom panel
    # ---------------------------------------
    def draw_bottom_panel(self, screen):
        font = pygame.font.SysFont(None, 20)
        panel_y = self.game.height - 130

        # Debug toggle
        self.debug_toggle_button["y"] = panel_y
        self.draw_button(screen, self.debug_toggle_button)

        # "Starting gold" label
        gold_lbl = font.render("Starting gold", True, (255,255,255))
        screen.blit(gold_lbl, (10, panel_y + 30))

        # Minus button
        self.gold_minus_button["x"] = 120
        self.gold_minus_button["y"] = panel_y + 26
        self.draw_button(screen, self.gold_minus_button)

        # Show current starting gold
        gold_val_str = str(self.game.startingGold)
        gold_val_surf = font.render(gold_val_str, True, (255,255,255))
        screen.blit(gold_val_surf, (150, panel_y + 30))

        # Plus button
        self.gold_plus_button["x"] = 180
        self.gold_plus_button["y"] = panel_y + 26
        self.draw_button(screen, self.gold_plus_button)

        # Restart button
        self.restart_button["x"] = 220
        self.restart_button["y"] = panel_y + 26
        self.draw_button(screen, self.restart_button)

        # Debug table if enabled
        if self.show_debug_table:
            self.draw_debug_table(screen, panel_y + 60)

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
        hp_text   = font.render(f"HP: {int(enemy['hp'])}/{int(enemy['baseHp'])}", True, (255,255,255))
        spd_text  = font.render(f"Speed: {int(enemy['speed'])}", True, (255,255,255))
        gold_text = font.render(f"Gold on Kill: {enemy['gold']}", True, (255,255,255))

        screen.blit(name_text, (panel_x+10, panel_y+5))
        screen.blit(hp_text,   (panel_x+10, panel_y+25))
        screen.blit(spd_text,  (panel_x+10, panel_y+40))
        screen.blit(gold_text, (panel_x+10, panel_y+55))

    def draw_debug_table(self, screen, y_start):
        font = pygame.font.SysFont(None, 20)
        towerData = self.game.tower_manager.get_tower_data()
        if len(towerData) < 2:
            return  # We only have 2 tower types in the example

        row_x = 10
        row_y = y_start

        # Title row
        headers = f"Base Price       {towerData[0]['type'].upper()} Tower    {towerData[1]['type'].upper()} Tower"
        txtSurf = font.render(headers, True, (255,255,255))
        screen.blit(txtSurf, (row_x, row_y))
        row_y += 20

        # Base price row
        basePriceRow = f"Base Price  ${towerData[0]['basePrice']}          ${towerData[1]['basePrice']}"
        txtSurf = font.render(basePriceRow, True, (255,255,255))
        screen.blit(txtSurf, (row_x, row_y))
        row_y += 20

        # Upgrades
        maxUpgrades = max(len(towerData[0]["upgrades"]), len(towerData[1]["upgrades"]))
        for i in range(maxUpgrades):
            lvl = i + 1
            # Damage row
            leftDam  = towerData[0]["upgrades"][i]["damage"] if i < len(towerData[0]["upgrades"]) else "-"
            rightDam = towerData[1]["upgrades"][i]["damage"] if i < len(towerData[1]["upgrades"]) else "-"
            lineD = f"Level {lvl} Damage:     {leftDam}             {rightDam}"
            txtSurf = font.render(lineD, True, (255,255,255))
            screen.blit(txtSurf, (row_x, row_y))
            row_y += 20

            # Upgrade cost row
            if lvl > 1:
                leftCost  = towerData[0]["upgrades"][i]["upgradeCost"] if i < len(towerData[0]["upgrades"]) else "-"
                rightCost = towerData[1]["upgrades"][i]["upgradeCost"] if i < len(towerData[1]["upgrades"]) else "-"
                lineC = f"Level {lvl} Upgrade:   ${leftCost}             ${rightCost}"
                txtSurf = font.render(lineC, True, (255,255,255))
                screen.blit(txtSurf, (row_x, row_y))
                row_y += 20

    # ---------------------------------------
    # Button-click handling
    # ---------------------------------------
    def handle_ui_click(self, mx, my):
        # 1) Check top-row buttons
        for btn in self.top_buttons:
            if self.clicked_in_button(mx, my, btn):
                self.handle_button_action(btn["action"])
                return

        # 2) Check bottom-row buttons
        if self.clicked_in_button(mx, my, self.debug_toggle_button):
            self.handle_button_action(self.debug_toggle_button["action"])
            return
        if self.clicked_in_button(mx, my, self.gold_minus_button):
            self.handle_button_action(self.gold_minus_button["action"])
            return
        if self.clicked_in_button(mx, my, self.gold_plus_button):
            self.handle_button_action(self.gold_plus_button["action"])
            return
        if self.clicked_in_button(mx, my, self.restart_button):
            self.handle_button_action(self.restart_button["action"])
            return

        # 3) If none of the UI buttons were clicked, we check the game canvas
        self.handle_canvas_click(mx, my)

    def handle_button_action(self, action):
        if action == "speed":
            self.game.toggle_speed()
        elif action == "pause":
            self.game.toggle_pause()
        elif action == "sendwave":
            self.game.wave_manager.send_wave_early()
        elif action == "debugToggle":
            self.show_debug_table = not self.show_debug_table
            if self.show_debug_table:
                self.debug_toggle_button["label"] = "Disable Debug"
                self.game.debug_mode = True
            else:
                self.debug_toggle_button["label"] = "Enable Debug"
                self.game.debug_mode = False
        elif action == "goldMinus":
            self.game.startingGold = max(0, self.game.startingGold - 100)
        elif action == "goldPlus":
            self.game.startingGold += 100
        elif action == "restart":
            self.game.resetGame(self.game.startingGold)

    def handle_canvas_click(self, mx, my):
        # Tower spots
        for spot in self.game.tower_spots:
            dx = mx - spot["x"]
            dy = my - spot["y"]
            if dx*dx + dy*dy <= 100:
                existing_tower = None
                for t in self.game.tower_manager.towers:
                    if t["spot"] == spot:
                        existing_tower = t
                        break
                if existing_tower:
                    self.game.tower_manager.upgrade_tower(existing_tower)
                else:
                    tower_data = self.game.tower_manager.get_tower_data()[0]  # default "point" tower
                    cost = tower_data["basePrice"]
                    if self.game.gold >= cost and not spot["occupied"]:
                        self.game.gold -= cost
                        self.game.tower_manager.create_tower(
                            tower_data["type"], 
                            spot["x"], 
                            spot["y"], 
                            spot
                        )
                        spot["occupied"] = True
                return

        # Enemies
        for enemy in self.game.enemies:
            left   = enemy["x"] - enemy["width"]/2
            right  = enemy["x"] + enemy["width"]/2
            top    = enemy["y"] - enemy["height"]/2
            bottom = enemy["y"] + enemy["height"]/2
            if (mx >= left and mx <= right and my >= top and my <= bottom):
                self.selected_enemy = enemy
                return

        self.selected_enemy = None

    # ---------------------------------------
    # Helpers
    # ---------------------------------------
    def draw_button(self, screen, btn):
        """Draw a simple rect with label."""
        bx, by, bw, bh = btn["x"], btn["y"], btn["w"], btn["h"]
        if bx is None or by is None:
            return  # Not positioned yet

        pygame.draw.rect(screen, (128,0,0), (bx, by, bw, bh), 0)  # fill
        pygame.draw.rect(screen, (200,0,0), (bx, by, bw, bh), 1)  # border
        font = pygame.font.SysFont(None, 18)
        label_surf = font.render(btn["label"], True, (255,255,255))
        text_rect = label_surf.get_rect(center=(bx + bw//2, by + bh//2))
        screen.blit(label_surf, text_rect)

    def clicked_in_button(self, mx, my, btn):
        bx, by, bw, bh = btn["x"], btn["y"], btn["w"], btn["h"]
        if bx is None or by is None:
            return False
        return (mx >= bx and mx <= bx + bw and 
                my >= by and my <= by + bh)