extends Node2D

const W = 1152.0
const H = 648.0
const ARENA = Rect2(34, 96, 1084, 518)
const PLAYER_SPEED = 300.0
const BULLET_SPEED = 720.0
const ENEMY_SPEED = 90.0

var player := Vector2(W/2, H/2 + 50)
var hp := 100.0
var score := 0
var wave := 1
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var spawn_timer := 0.0
var wave_timer := 0.0
var shoot_cooldown := 0.0
var game_over := false
var victory := false
var banner_timer := 2.0
var rng := RandomNumberGenerator.new()

func _ready():
    rng.randomize()
    queue_redraw()

func _process(delta):
    if game_over or victory:
        if Input.is_action_just_pressed("restart"):
            reset_game()
        queue_redraw()
        return

    update_player(delta)
    update_bullets(delta)
    update_enemies(delta)
    update_pickups(delta)

    spawn_timer -= delta
    wave_timer += delta
    shoot_cooldown -= delta
    banner_timer -= delta

    var alive_target = 5 + wave * 2
    if spawn_timer <= 0 and enemies.size() < alive_target:
        spawn_enemy()
        spawn_timer = max(0.25, 1.05 - wave * 0.06)

    if wave_timer >= 25.0:
        wave += 1
        wave_timer = 0
        banner_timer = 2.5
        if wave > 5:
            victory = true
        else:
            spawn_pickup()

    check_collisions()
    queue_redraw()

func reset_game():
    player = Vector2(W/2, H/2 + 50)
    hp = 100
    score = 0
    wave = 1
    enemies.clear()
    bullets.clear()
    pickups.clear()
    spawn_timer = 0
    wave_timer = 0
    shoot_cooldown = 0
    banner_timer = 2
    game_over = false
    victory = false

func update_player(delta):
    var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if dir.length() > 0:
        player += dir.normalized() * PLAYER_SPEED * delta
    player.x = clamp(player.x, ARENA.position.x + 20, ARENA.end.x - 20)
    player.y = clamp(player.y, ARENA.position.y + 20, ARENA.end.y - 20)

    if Input.is_action_pressed("shoot") and shoot_cooldown <= 0:
        var target = get_global_mouse_position()
        var dir_to_mouse = (target - player).normalized()
        bullets.append({"pos": player + dir_to_mouse * 20, "vel": dir_to_mouse * BULLET_SPEED, "life": 1.2})
        shoot_cooldown = 0.16

func update_bullets(delta):
    for i in range(bullets.size() - 1, -1, -1):
        bullets[i].pos += bullets[i].vel * delta
        bullets[i].life -= delta
        if bullets[i].life <= 0 or not ARENA.grow(40).has_point(bullets[i].pos):
            bullets.remove_at(i)

func update_enemies(delta):
    for i in range(enemies.size() - 1, -1, -1):
        var e = enemies[i]
        var d = (player - e.pos)
        if d.length() > 0:
            e.pos += d.normalized() * e.speed * delta
        e.flash = max(0.0, e.flash - delta)
        enemies[i] = e

func update_pickups(delta):
    for i in range(pickups.size() - 1, -1, -1):
        pickups[i].pulse += delta * 4
        if pickups[i].pos.distance_to(player) < 24:
            hp = min(100, hp + 25)
            pickups.remove_at(i)

func spawn_enemy():
    var side = rng.randi_range(0, 3)
    var p = Vector2.ZERO
    match side:
        0: p = Vector2(rng.randf_range(ARENA.position.x, ARENA.end.x), ARENA.position.y + 8)
        1: p = Vector2(rng.randf_range(ARENA.position.x, ARENA.end.x), ARENA.end.y - 8)
        2: p = Vector2(ARENA.position.x + 8, rng.randf_range(ARENA.position.y, ARENA.end.y))
        3: p = Vector2(ARENA.end.x - 8, rng.randf_range(ARENA.position.y, ARENA.end.y))
    enemies.append({
        "pos": p,
        "hp": 2 + int(wave / 2),
        "speed": ENEMY_SPEED + wave * 8 + rng.randf_range(-10, 15),
        "flash": 0.0
    })

func spawn_pickup():
    pickups.append({
        "pos": Vector2(rng.randf_range(ARENA.position.x+50, ARENA.end.x-50),
                       rng.randf_range(ARENA.position.y+50, ARENA.end.y-50)),
        "pulse": 0.0
    })

func check_collisions():
    for bi in range(bullets.size() - 1, -1, -1):
        var b = bullets[bi]
        var hit = false
        for ei in range(enemies.size() - 1, -1, -1):
            var e = enemies[ei]
            if b.pos.distance_to(e.pos) < 19:
                e.hp -= 1
                e.flash = 0.1
                enemies[ei] = e
                bullets.remove_at(bi)
                hit = true
                if e.hp <= 0:
                    score += 100
                    if rng.randf() < 0.10:
                        pickups.append({"pos": e.pos, "pulse": 0.0})
                    enemies.remove_at(ei)
                break
        if hit:
            continue

    for e in enemies:
        if player.distance_to(e.pos) < 28:
            hp -= 22 * get_process_delta_time()
            if hp <= 0:
                hp = 0
                game_over = true

func _draw():
    draw_rect(Rect2(0,0,W,H), Color("#080b16"))
    # Header
    draw_rect(Rect2(0,0,W,78), Color("#11182b"))
    draw_string(ThemeDB.fallback_font, Vector2(36,48), "NEON SURVIVOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#62e6ff"))
    draw_string(ThemeDB.fallback_font, Vector2(355,45), "WASD / ARROWS  •  AIM + CLICK TO SHOOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#aab5d6"))
    draw_string(ThemeDB.fallback_font, Vector2(1010,45), "WAVE %d" % wave, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffcf5c"))

    # Arena
    draw_rect(ARENA, Color("#0d1221"), true)
    draw_rect(ARENA, Color("#263453"), false, 2)
    for x in range(int(ARENA.position.x)+30, int(ARENA.end.x), 48):
        draw_line(Vector2(x, ARENA.position.y), Vector2(x, ARENA.end.y), Color(0.12,0.16,0.25,0.35), 1)
    for y in range(int(ARENA.position.y)+30, int(ARENA.end.y), 48):
        draw_line(Vector2(ARENA.position.x,y), Vector2(ARENA.end.x,y), Color(0.12,0.16,0.25,0.35), 1)

    # Pickups
    for p in pickups:
        var r = 8.0 + sin(p.pulse) * 2
        draw_circle(p.pos, r+5, Color(0.25,1,0.7,0.12))
        draw_circle(p.pos, r, Color("#48f0a8"))
        draw_line(p.pos-Vector2(6,0), p.pos+Vector2(6,0), Color("#092019"), 3)
        draw_line(p.pos-Vector2(0,6), p.pos+Vector2(0,6), Color("#092019"), 3)

    # Bullets
    for b in bullets:
        draw_circle(b.pos, 5, Color("#ffe66d"))
        draw_circle(b.pos, 9, Color(1,0.8,0.2,0.12))

    # Enemies
    for e in enemies:
        var c = Color("#ff496f") if e.flash <= 0 else Color.WHITE
        draw_circle(e.pos, 18, Color(1,0.1,0.3,0.12))
        draw_circle(e.pos, 14, c)
        draw_circle(e.pos, 5, Color("#230b16"))
        draw_line(e.pos + Vector2(-5,-4), e.pos + Vector2(5,4), Color("#230b16"), 2)

    # Player
    draw_circle(player, 25, Color(0.2,0.85,1,0.10))
    draw_circle(player, 17, Color("#4bdcff"))
    var aim = (get_global_mouse_position() - player).normalized()
    draw_line(player, player + aim * 27, Color("#ffffff"), 5)
    draw_circle(player, 7, Color("#102438"))

    # HUD
    draw_rect(Rect2(36, 92, 230, 18), Color("#202943"), true)
    draw_rect(Rect2(36, 92, 230 * hp/100.0, 18), Color("#42e6a4"), true)
    draw_string(ThemeDB.fallback_font, Vector2(40,108), "HP %d / 100" % int(hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#08151a"))
    draw_string(ThemeDB.fallback_font, Vector2(36,137), "SCORE  %06d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f2f5ff"))
    draw_string(ThemeDB.fallback_font, Vector2(920,610), "SURVIVE: %02d s" % max(0, 25 - int(wave_timer)), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#aab5d6"))

    if banner_timer > 0 and not game_over and not victory:
        draw_rect(Rect2(390, 250, 372, 100), Color(0.05,0.08,0.16,0.94))
        draw_string(ThemeDB.fallback_font, Vector2(430,292), "WAVE %d" % wave, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("#62e6ff"))
        draw_string(ThemeDB.fallback_font, Vector2(430,322), "Survive the incoming swarm!", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#d9e2ff"))

    if game_over:
        draw_overlay("GAME OVER", "You survived to wave %d" % wave, "Press R to restart")
    elif victory:
        draw_overlay("VICTORY!", "You survived all 5 waves.", "Press R to play again")

func draw_overlay(title: String, subtitle: String, hint: String):
    draw_rect(Rect2(0,0,W,H), Color(0.01,0.02,0.06,0.78))
    draw_rect(Rect2(310,215,532,220), Color("#11182b"), true)
    draw_rect(Rect2(310,215,532,220), Color("#314365"), false, 2)
    draw_string(ThemeDB.fallback_font, Vector2(380,290), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color("#62e6ff"))
    draw_string(ThemeDB.fallback_font, Vector2(380,330), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#d9e2ff"))
    draw_string(ThemeDB.fallback_font, Vector2(380,385), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffcf5c"))
