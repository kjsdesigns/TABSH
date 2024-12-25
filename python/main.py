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
