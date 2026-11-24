# Dawnglass: Progress

> Kept by the AI agent. Updated at the end of every task.
> Status: ✅ done (tested in a real run) · 🟡 in progress · ⬜ not started · ⛔ blocked

## Current status
- **Current module:** M1: Moving one keeper ✅ complete and tested in a real run
- **Next step:** M2: Day and night clock (after the human's go-ahead)
- **Godot version installed:** 4.7.2.stable.official.ed1daf0bf (via Godot MCP `get_godot_version`; renderer Forward+, D3D12, AMD Radeon Graphics)
- **Waiting on the human for:** go-ahead to start M2

---

## Modules

| Module | Status | Notes |
| --- | --- | --- |
| M0: Project setup | ✅ | Project named Dawnglass; main scene, 640×360 viewport, integer-friendly 2× override, nearest filtering, pixel snapping, 60 Hz physics, seven autoload shells, and validated tuning data. |
| M1: Moving one keeper | ✅ | Keeper `CharacterBody2D` with keyboard/gamepad binding, house and boundary collisions, base-anchored y-sort, smooth follow camera, sign interaction text box. All 16 checks pass; three-minute run clean. |
| M2: Day and night clock | ⬜ | |
| M3: Lights and shadows | ⬜ | |
| M4: Creatures (2 types) | ⬜ | |
| M5: The lighthouse beam | ⬜ | |
| M6: Switching keepers | ⬜ | |
| 🚦 Gate 1: Is the core fun? | ⬜ | Needs the human to play |
| M7: Townsfolk, the Hall and promises | ⬜ | |
| M8: Hollow houses | ⬜ | |
| M9: Dawn summary, HUD and saving | ⬜ | |
| M10: The first playable slice | ⬜ | |
| 🚦 Gate 2: The slice | ⬜ | Needs the human to play |

### Tests for the current module
- ✅ Movement and collisions work; no getting stuck on corners. Proven by driven input: 32.0 px horizontal movement; house blocks at x=503.0; corner approach slides to x=573.9 without penetrating (top=260.1) and the keeper leaves freely.
- ✅ The keeper walks behind and in front of a house correctly. Proven by base-anchored house/keeper origins, shared y-sorted parent, no `z_index` override, and keeper above house at y=200.0 < 260.0.
- ✅ Interacting with the sign shows a text box. Proven by overlap detection through `try_interact()` and the text box showing the sign's text; keyboard (E) and gamepad (A) bindings registered.
- ✅ Camera follows smoothly (292.2 → 45.2 px after 15 physics frames) and settles on the keeper (0.00 px).
- ✅ Three-minute run: `M1 TESTS PASS`, `M1 RUNTIME CHECK COMPLETE`, log scan found no `ERROR` or `WARNING` lines.

---

## Spec gaps (things the agent had to guess)
| Date | Where (bible §) | What was missing | What was built (provisional) | Resolved? |
| --- | --- | --- | --- | --- |
| 2026-11-24 | AGENT_BUILD_GUIDE §5 M1 | Input bindings for movement/interact are not specified. | WASD + arrow-less left stick for movement, E + gamepad A for interact, registered at runtime in `keeper_controller.gd`. | Open |
| 2026-11-24 | AGENT_BUILD_GUIDE §5 M1 | Camera smooth-follow speed is not specified. | `camera.follow_speed = 8.0` in `data/tuning.json`; exponential lerp in `follow_camera.gd`. | Open |
| 2026-11-24 | AGENT_BUILD_GUIDE §5 M1 | Sign text and interaction range are not specified. | Placeholder sign text; 28 px probe radius in the debug scene. | Open |

## Decisions made
| Date | Decision | Why |
| --- | --- | --- |
| 2026-11-24 | Bind input actions in code instead of `project.godot`. | A hand-written `[input]` block was malformed and crashed startup; code binding is version-safe and testable. |
| 2026-11-24 | `run/main_scene` points at `scenes/debug/m1_keeper.tscn` during M1. | MCP `run_project` then exercises the current module; M10 replaces it with the real main scene. |

## Known bugs
| Date found | Bug | Status |
| --- | --- | --- |
| 2026-11-24 | Malformed `[input]` block in `project.godot` made Godot exit before printing output. | Fixed: block removed, actions bound in code. |
| 2026-11-24 | Follow camera's exported node target did not resolve in the hand-written scene, leaving it at the origin. | Fixed: switched to `@export var target_path: NodePath`. |

## Playtest notes (from the human)
_Feedback from each 🚦 gate goes here._

## Ideas for later (not to be built now)
-

---

## Session log
| Date | What was done | What's next |
| --- | --- | --- |
| 2026-11-23 | Session 1 (setup only, no game code). Read all three docs. Toolchain verified: Godot 4.7.2.stable.official.ed1daf0bf; project info reports Dawnglass at E:/Dawnglass, 1 scene, 0 scripts, 1 asset, 5 other files. Created `scenes/_setup_probe.tscn` and deleted it. Running with no main scene returned `Error: Can't run project: no main scene defined in the project.`; running existing `scenes/_throwaway.tscn` succeeded with D3D12 initialization and `errors: []`. | M0 after human approval. |
| 2026-11-23 | M0 completed. Preserved existing `_throwaway.tscn`, renamed project to Dawnglass, set `scenes/main.tscn` as main scene, configured 640×360 viewport, 1280×720 override, canvas-item stretch, nearest filtering, pixel snapping, and 60 Hz physics. Added `data/tuning.json`; seven autoload shells under `scripts/autoload/`; and `scripts/m0_test.gd`. Initialized Git and added origin `https://github.com/Chingkhei-lab/Dawnglass.git`. Test output: `PASS M0 Data loads tuning.json`; `Data: missing required tuning key: deliberately_missing.key`; `PASS M0 missing key produces clear error`; `PASS M0 physics rate 60 Hz`; `M0 TESTS PASS`; Godot debug `errors: []`. The three-minute runtime check completed with no delayed errors or warnings; process then exited normally. | Wait for the human's go-ahead, then M1. |
| 2026-11-24 | M1 implementation started. Added keeper movement using `CharacterBody2D`, collision shapes for a house and boundary wall, a y-sorted debug area, a smoothed `Camera2D`, sign interaction text box, and M1 test/debug scripts. Added `camera.follow_speed` tuning. First run exposed a parser error from overriding Godot's built-in `draw_ellipse`; renamed helper to `draw_shadow`. A subsequent launch attempt returned no active process/output, so M1 was not marked complete. | Diagnose launch failure. |
| 2026-11-24 | M1 completed. Root cause of the launch failure: a malformed hand-written `[input]` block in `project.godot` made Godot abort before logging. Removed it and bound movement (WASD + left stick) and interact (E + gamepad A) in code. Rewrote the debug area as 1024×640 with base-anchored house/keeper y-sort, removed the house `z_index` override, added wall collisions, and replaced the structural-only test with a driven harness. Fixed the follow camera's node target (`target_path` NodePath). Final run: 16/16 PASS, `M1 TESTS PASS`, `M1 RUNTIME CHECK COMPLETE`, and a log scan found no `ERROR`/`WARNING` lines over the three-minute run. | Wait for the human's go-ahead, then M2. |
