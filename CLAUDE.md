# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A Godot 4.4 (Forward+) 3D boss-fight game that is **also a teaching course**. It is built one lesson "part" at a time, and each part ships three things together: the game feature, an HTML lesson page, and a snapshot branch. Keep every part tightly scoped — do not add systems the current part did not ask for.

Planned end state: a boss fight playable in single player or multiplayer (the player picks the mode). Built so far: Part 1 = the arena map, Part 2 = a single-player third-person player. Not built yet: mode-select menu, networking, the boss, combat, animations (the knight GLB is a static Tinkercad mesh with no animation tracks).

## Running the game

Godot has no build/test/lint step here; the engine binary is the whole toolchain.

```bash
# Editor (user's local install)
"C:/Users/User/Desktop/Godot_v4.4.1-stable_win64.exe" -e --path .

# Play the main scene (res://game.tscn) without opening the editor
"C:/Users/User/Desktop/Godot_v4.4.1-stable_win64.exe" --path .

# Play one scene in isolation
"C:/Users/User/Desktop/Godot_v4.4.1-stable_win64.exe" --path . map/map1.tscn
```

Never run the editor against this directory while the user has it open, and never edit `project.godot` while their editor is running — it will overwrite your change on save. Ask them to close it, or let them make the change in the UI.

## Architecture

**Scene composition.** `game.tscn` (main scene) is a bare `Node3D` that instances exactly two things: `map/map1.tscn` and `character/player.tscn`. This split is deliberate — the Game node is the future spawn point where one Player is instanced per network peer, so keep player state on the Player scene and world state on the Map scene rather than in Game.

**Map is block-composed, not modeled.** `map/blocks/*.tscn` are reusable `StaticBody3D` prefabs (floor 100×1×100, platform_large 8×2×8, platform_small 4×2×4, step 2×1×2, ramp 4×2×4 prism, pillar 2×6×2, wall 10×3×1), each a `MeshInstance3D` + `CollisionShape3D` with a coloured `StandardMaterial3D` baked in as a sub-resource. `map/map1.tscn` instances them under `Blocks/Quadrant1..4` (the same kit mirrored four ways around a central `BossStage`) plus a `Decoration` group. Changing a block's size or colour in its `.tscn` updates every placement. `block_kirbbb.tscn` is the one imported-mesh block (`map/models/kirbbb.glb`, Tinkercad export, scaled 0.1) and is decoration with no collision.

**Player.** `character/player.tscn` is a `CharacterBody3D` with a capsule collider, a `Model` node holding the GLB (scaled 0.025, offset so the mesh's origin lines up with the capsule), and `CameraPivot → SpringArm3D → Camera3D`. `scripts/player.gd` moves it: mouse motion yaws `CameraPivot` and pitches the SpringArm (clamped −70°..+20°), WASD is converted to world direction via `camera_pivot.global_basis` so movement is camera-relative, and the `Model` yaws toward the travel direction with `lerp_angle`. The SpringArm excludes the player's own RID so the camera does not collide with the body. Esc releases the captured mouse, any click recaptures it.

Input actions (`move_forward/back/left/right`, `jump`) live in `project.godot` under `[input]`; use those action names rather than raw key checks.

## Lesson pages

Each part gets a page in `resources/`: `learning.html` (Lesson 1, the map) and `learning_part2.html` (Lesson 2, the player), cross-linked with back/next footers. They are self-contained HTML — the `<head>` style block is copied between pages, so start a new part by copying the previous page's `<head>`/CSS. Screenshots go in `resources/images/` prefixed per part (`p2_` for Lesson 2) and videos in `resources/videos/` (`p1_`, `p2_`); both are real Godot captures, not mockups. Each lesson has one clip per step plus `pN_lessonN_full.mp4`, the whole lesson concatenated with title cards so a student can follow the video alone. Lesson 2 also ends with gameplay footage recorded from the running game. `resources/.gdignore` keeps Godot from importing any of it.

To capture stills or video: copy the project into the scratchpad, point `APPDATA` at a scratch dir, run the editor with `-e --single-window`, and install a temporary `EditorPlugin` that opens the menus/dialogs and saves the root viewport — one image for a still, one JPG per `frame_post_draw` for video, then encode with ffmpeg. A drawn cursor and red boxes are composited into the image, since nothing moves the real mouse. Gameplay footage is captured the same way from a temporary autoload in the running game, driving the player with `Input.action_press` and synthetic mouse motion. Gotchas: set `OS.low_processor_usage_mode = false` or `frame_post_draw` never fires; `EditorInterface.close_scene()` does not exist in 4.4 (use the Scene menu's "Close Scene" item); the collision option to pick is "Single Convex"; "Focus Selection" only re-centres the camera and never changes zoom, and its bounds ignore nodes not owned by the edited scene. Do this only on the scratchpad copy.

## Branch workflow

Public repo: https://github.com/advaspire12345/3d-boss-fight-multiplayer. All work happens on `main`. When a part is finished, commit to `main`, then create `partN` from `main` and push it — `part1` and `part2` are frozen lesson snapshots, so never commit new work onto them. At the end of each part, offer to cut the next `partN`. Part 3 is next; its topic is not chosen yet.
