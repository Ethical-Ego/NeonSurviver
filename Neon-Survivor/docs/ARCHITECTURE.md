# Architecture

## Current implementation

The current game uses one `Node2D` main scene (`Main.tscn`) with `main.gd` attached. Runtime entities are represented as dictionaries in arrays and drawn through the node's `_draw()` method.

### Main update loop

1. Read player movement and shooting input.
2. Update projectiles, enemies, and pickups.
3. Advance spawn and wave timers.
4. Spawn enemies while under the active enemy cap.
5. Advance to the next wave after each 25-second interval.
6. Resolve projectile/enemy hits and enemy/player contact damage.
7. Refresh the rendered arena and HUD.

### Runtime state

| State | Purpose |
|---|---|
| `player`, `hp` | Player position and health |
| `enemies` | Active enemy positions, health, speed, and hit flash |
| `bullets` | Projectile position, velocity, and lifetime |
| `pickups` | Health pickup position and pulse animation |
| `score`, `wave`, `wave_timer` | Progress and scoring |
| `game_over`, `victory` | End-state flags |

### Game rules in this build

- Five waves, each lasting 25 seconds.
- Enemy spawn cap scales with the current wave.
- Enemy health and speed increase as waves progress.
- Each defeated enemy awards 100 points.
- Green health pickups restore 25 HP, up to 100 HP.
- Enemy contact drains player health over time.
- `R` restarts the run after Victory or Game Over.

## Extension direction

For a larger version, consider splitting the controller into reusable scenes and scripts: `Player`, `Enemy`, `Projectile`, `HealthPickup`, `WaveManager`, and `HUD`. This would make it easier to add new enemy types, weapons, effects, and automated tests without turning the main controller into a monolith.
