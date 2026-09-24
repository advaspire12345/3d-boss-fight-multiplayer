# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A Godot 4.4 (Forward+) 3D boss-fight game that is **also a teaching course**. It is built one lesson "part" at a time, and each part ships three things together: the game feature, an HTML lesson page, and a snapshot branch. Keep every part tightly scoped — do not add systems the current part did not ask for.

Planned end state: a boss fight playable in single player or multiplayer (the player picks the mode). Built so far: Part 1 = the arena map, Part 2 = a single-player third-person player, Part 3 = player animations (idle, run, jump, punch) on a Mixamo-rigged Minecraft character. Not built yet: mode-select menu, networking, the boss, combat damage.

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

**Player.** `character/player.tscn` is a `CharacterBody3D` with a capsule collider, a `Model` node holding the character and its `AnimationPlayer`, and `CameraPivot → SpringArm3D → Camera3D`. Since Part 3 the character is a Minecraft-style figure: `character/minecraft.zip` is the Tinkercad OBJ export, rigged and animated on Mixamo, downloaded as four FBX files "With Skin" in `character/mixamo/` (`idle`, `run`, `jump`, `punch`). `idle.fbx` is instanced as the model at life size (no scaling). Every FBX import runs `scripts/mixamo_import.gd`, which saves the clip to `character/animations/<name>.res`, makes idle/run loop, pins the hips' X/Z (running was not downloaded In Place) and, for jump, also the height, since physics already moves the body. It also strips the FBX's own AnimationPlayer and the empty Tinkercad meshes (the "surfaces.is_empty()" import errors come from those and are harmless). Godot's `root_motion_track` cannot replace the script: the Mixamo rest pose is offset from the animated pose, so cancelling the hips drops the model to the wrong place. The Player's `AnimationPlayer` only holds those four `.res` clips; `Model/AnimationTree` (a BlendTree) plays them. `movement` is a Transition node (idle/run/jump, 0.2 s crossfade; jump goes through the `jump_seek` TimeSeek so `update_animation()` can start it at `jump_start_time`, past the crouch). `punch` is a OneShot on top whose bone filter covers only Spine/Spine1/Spine2/Neck/Head/HeadTop_End and both Shoulder/Arm/ForeArm/Hand, so the punch plays on the upper body while the legs keep idling, running or jumping — punching never stops movement. `player.gd` only sets `parameters/movement/transition_request` and fires `parameters/punch/request`. Left click is the `attack` action once the mouse is captured (the first click only captures it). `scripts/player.gd` moves it: mouse motion yaws `CameraPivot` and pitches the SpringArm (clamped −70°..+20°), WASD is converted to world direction via `camera_pivot.global_basis` so movement is camera-relative, and the `Model` yaws toward the travel direction with `lerp_angle`. The SpringArm excludes the player's own RID so the camera does not collide with the body. Esc releases the captured mouse, any click recaptures it.

Input actions (`move_forward/back/left/right`, `jump`, `attack`) live in `project.godot` under `[input]`; use those action names rather than raw key checks.

## Lesson pages

Each part gets a page in `resources/`: `learning.html` (Lesson 1, the map), `learning_part2.html` (Lesson 2, the player) and `learning_part3.html` (Lesson 3, animation), cross-linked with back/next footers. They are self-contained HTML — the `<head>` style block is copied between pages, so start a new part by copying the previous page's `<head>`/CSS. Screenshots go in `resources/images/` prefixed per part (`p2_`, `p3_`) and videos in `resources/videos/` (`p1_`, `p2_`, `p3_`); both are real Godot captures, not mockups. Each lesson has one clip per step plus `pN_lessonN_full.mp4`, the whole lesson concatenated with title cards so a student can follow the video alone. Lessons 2 and 3 also end with gameplay footage recorded from the running game. Lesson 3's Step 1 (Tinkercad export and Mixamo) happens in a browser behind the user's Adobe login, so its clips (`p3_mixamo_*.mp4`) come from the user's own screen recordings, not from the capture plugin. `resources/.gdignore` keeps Godot from importing any of it.

To capture stills or video: copy the project into the scratchpad, point `APPDATA` at a scratch dir, run the editor with `-e --single-window`, and install a temporary `EditorPlugin` that opens the menus/dialogs and saves the root viewport — one image for a still, one JPG per `frame_post_draw` for video, then encode with ffmpeg. A drawn cursor and red boxes are composited into the image, since nothing moves the real mouse. Gameplay footage is captured from a temporary autoload in the running game, driving the player with `Input.action_press`, `Input.parse_input_event(InputEventAction)` for `attack`, and by turning `CameraPivot` directly; record it with Godot's Movie Maker (`--write-movie out.avi --fixed-fps 20 --resolution 1280x750`) instead of per-frame JPGs. Editor clips are 1280×750 at 20 fps with `interface/editor/display_scale = 2` (100%) in the scratch editor settings; the editor ignores `--resolution` and opens maximised, so the plugin calls `DisplayServer.window_set_size`. Keep a snapshot of the scratch project after each clip so any clip can be re-recorded from the right starting state. Gotchas: set `OS.low_processor_usage_mode = false` or `frame_post_draw` never fires; `EditorInspectorSection` has no readable label, so find a section by its `tooltip_text` before calling `unfold()`; the bottom panel's expand button has no tooltip text, so match it by its `ExpandBottomDock` icon; after changing an `AnimationNodeBlendTree` from code, call `update_graph` on the `AnimationNodeBlendTreeEditor` to redraw it; selecting an AnimationTree switches the bottom panel to Animation, so press the `AnimationTree` panel button again; `EditorInterface.close_scene()` does not exist in 4.4 (use the Scene menu's "Close Scene" item); the collision option to pick is "Single Convex"; "Focus Selection" only re-centres the camera and never changes zoom, and its bounds ignore nodes not owned by the edited scene. Do this only on the scratchpad copy.

## Branch workflow

Public repo: https://github.com/advaspire12345/3d-boss-fight-multiplayer. All work happens on `main`. When a part is finished, commit to `main`, then create `partN` from `main` and push it — `part1`, `part2` and `part3` are frozen lesson snapshots, so never commit new work onto them. At the end of each part, offer to cut the next `partN`. Part 4 is next; its topic is not chosen yet.
