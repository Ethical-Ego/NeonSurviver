# Development Notes

## Environment

- Engine: Godot 4.x
- Project feature version: Godot 4.3
- Main scene: `Main.tscn`
- Main script: `main.gd`
- Renderer: Compatibility / GL Compatibility

## Quick validation checklist

Before publishing a release, open the project in the target Godot version and verify:

- [ ] Project imports without parse errors.
- [ ] Main scene launches.
- [ ] WASD and arrow-key movement work.
- [ ] Mouse aiming and hold-to-shoot work.
- [ ] Enemies spawn and pursue the player.
- [ ] Projectiles damage and remove enemies.
- [ ] Score increments when an enemy is defeated.
- [ ] Health pickups restore health.
- [ ] Wave progression reaches wave five and Victory.
- [ ] Player health can reach zero and show Game Over.
- [ ] `R` restarts from both end states.

Testing status should be updated only after the checks have actually been run.
