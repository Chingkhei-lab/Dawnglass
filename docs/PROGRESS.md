# Dawnglass: Progress

> Kept by the AI agent. Updated at the end of every task.
> Status: ✅ done (tested in a real run) · 🟡 in progress · ⬜ not started · ⛔ blocked

## Current status
- **Current module:** M3: Lights and shadows ✅ complete and tested in a real run
- **Next step:** M4: Creatures (after the human's go-ahead)
- **Godot version installed:** 4.7.2.stable.official.ed1daf0bf (via Godot MCP `get_godot_version`; renderer Forward+, D3D12, AMD Radeon Graphics)
- **Waiting on the human for:** go-ahead to start M4

---

## Modules

| Module | Status | Notes |
| --- | --- | --- |
| M0: Project setup | ✅ | Project named Dawnglass; main scene, 640×360 viewport, integer-friendly 2× override, nearest filtering, pixel snapping, 60 Hz physics, seven autoload shells, and validated tuning data. |
| M1: Moving one keeper | ✅ | Keeper `CharacterBody2D` with keyboard/gamepad binding, house and boundary collisions, base-anchored y-sort, smooth follow camera, sign interaction text box. All 16 checks pass; three-minute run clean. |
| M2: Day and night clock | ✅ | Clock runs day→dusk→night→dawn from tuning (720/45/300/45 s, cycle 1110 s); `CanvasModulate` blends palette colours through dusk and dawn; Dawnglass charges to 100% by nightfall; debug readout shows day, phase, phase time and charge. 13 checks pass; three-minute windowed run clean. |
| M3: Lights and shadows | ✅ | Lantern `PointLight2D` with cast shadows and no gameplay effect; Glint bursts with charges, shadow cost and a wall-aware `DaylightCheck` raycast; `ShadowComponent` with value/maximum, exposure loss, sunlight recovery, the 30% maximum drop and the three visible stages. 26 checks pass; three-minute windowed run clean; M1/M2 re-verified. |
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
- ✅ The lantern lights the area but has no gameplay effect. Cast-shadow `PointLight2D` toggled off and on for 20 frames left the shadow value unchanged.
- ✅ The Glint's daylight check is blocked by walls. Shared `DaylightCheck.is_lit()` passes a clear point, fails the same distance behind the wall, and fails beyond range.
- ✅ Shadow drops while exposed by the tuned amount, and the visible shadow fades with it. 0.10 lost in 2 s at 0.05/s; normal above 60%, flickering 60–30% with a varying alpha, faint and dimmer below 30%.
- ✅ Shadow recovers in sunlight but never above the current maximum. 0.04 gained in 2 s at 0.02/s, stopping exactly at the 80% maximum.
- ✅ Falling below 30% lowers the maximum once per crossing. 100% → 90% at the first crossing, unchanged while staying low, then 90% → 80% after recovering above 30%.
- ✅ Glint charges and cost. 3 charges, one per burst, 0.05 shadow per use, refuses to fire at 0.
- ✅ Three-minute run: 26/26 PASS, `M3 RUNTIME CHECK COMPLETE`, log scan found no `ERROR` or `WARNING` lines. M1 and M2 test scenes were re-run afterwards and still pass.

---

## Spec gaps (things the agent had to guess)
| Date | Where (bible §) | What was missing | What was built (provisional) | Resolved? |
| --- | --- | --- | --- | --- |
| 2026-11-24 | AGENT_BUILD_GUIDE §5 M1 | Input bindings for movement/interact are not specified. | WASD + arrow-less left stick for movement, E + gamepad A for interact, registered at runtime in `keeper_controller.gd`. | Open |
| 2026-11-24 | AGENT_BUILD_GUIDE §5 M1 | Camera smooth-follow speed is not specified. | `camera.follow_speed = 8.0` in `data/tuning.json`; exponential lerp in `follow_camera.gd`. | Open |
| 2026-11-24 | AGENT_BUILD_GUIDE §5 M1 | Sign text and interaction range are not specified. | Placeholder sign text; 28 px probe radius in the debug scene. | Open |
| 2026-11-24 | GAME_BIBLE §5 | Dusk and dawn transition lengths are not specified. | 45 s each, as separate segments on top of day/night (cycle 1110 s rather than 1020 s). | Open |
| 2026-11-24 | GAME_BIBLE §12.2 | Exact sky tint per phase is not specified. | Provisional `CanvasModulate` colours from the §12.3 palette: day `f4f7fa`, dusk `ffb84d`, night `26354d`, dawn `e67e22`, blended in two stages. | Open |
| 2026-11-24 | GAME_BIBLE §4.3 | Whether unused Dawnglass charge carries into the next day is not specified. | Charge persists across days until something spends it (arrives with M5). | Open |
| 2026-11-24 | AGENT_BUILD_GUIDE §6 | A 17-minute cycle cannot be observed inside the 3-minute runtime window. | Debug harness uses `clock.test_time_scale` (20×) and supports `--time-scale=N`; gameplay default stays real time. | Open |
| 2026-11-24 | GAME_BIBLE §7.2 | Shadow loss/recovery rates and the size of the maximum drop are not given, only the stage thresholds. | `dawnglass_loss_rate` 0.05/s, `sunlight_recovery_rate` 0.02/s, `max_drop` 0.10, flicker speed 6. | Open |
| 2026-11-24 | GAME_BIBLE §6.1 | Glint radius, burst duration and the recharge rule are not specified. | 112 px radius, 4 s burst, 3 charges; no recharge implemented yet. | Open |
| 2026-11-24 | GAME_BIBLE §7.2 / guide §4 | Guide says `GameState` holds shadow values; there is no save format yet. | Shadow value and maximum live in each keeper's `ShadowComponent` until saving arrives (M9). | Open |
| 2026-11-24 | GAME_BIBLE §6.1 | Input keys for the lantern and Glint are unspecified. | F / gamepad B toggles the lantern; Q / gamepad X fires the Glint. | Open |

## Decisions made
| Date | Decision | Why |
| --- | --- | --- |
| 2026-11-24 | Bind input actions in code instead of `project.godot`. | A hand-written `[input]` block was malformed and crashed startup; code binding is version-safe and testable. |
| 2026-11-24 | `run/main_scene` points at `scenes/debug/m1_keeper.tscn` during M1. | MCP `run_project` then exercises the current module; M10 replaces it with the real main scene. |
| 2026-11-24 | Autoload order starts with `Data`, then `Events`, `GameState`, `Clock`, `SaveSystem`, `Audio`, `Rng`. | `Clock` reads tuning in `_ready`; declared before `Data` it saw an empty dictionary. |
| 2026-11-24 | `run/main_scene` points at `scenes/debug/m2_clock.tscn` during M2. | Same pattern as M1: the main scene always boots the current module's debug scene. |
| 2026-11-24 | Daylight gameplay checks use our own raycast (`DaylightCheck`), not the renderer; the occluder bitmask lives in `lighting.obstacle_layer`. | Guide §2 requires our own checks; renderer lights stay purely cosmetic. |
| 2026-11-24 | Walls carry collision layers 1 (movement) and 2 (daylight occlusion). | One body blocks walking and light rays; the ray mask only sees layer 2. |
| 2026-11-24 | A Glint burst is itself a daylight field (group `daylight_fields`). | Anyone standing in it loses shadow at the tuned rate; the user also pays `glint_cost`. |
| 2026-11-24 | `run/main_scene` points at `scenes/debug/m3_lights.tscn` during M3. | Same main-scene convention as M1 and M2. |
| 2026-11-24 | Settings equal to engine defaults (60 Hz physics, stretch aspect `keep`) were pruned from `project.godot` when Godot rewrote the file. | Behaviour unchanged; verified by the M0 and M2 checks. |

## Known bugs
| Date found | Bug | Status |
| --- | --- | --- |
| 2026-11-24 | Malformed `[input]` block in `project.godot` made Godot exit before printing output. | Fixed: block removed, actions bound in code. |
| 2026-11-24 | Follow camera's exported node target did not resolve in the hand-written scene, leaving it at the origin. | Fixed: switched to `@export var target_path: NodePath`. |
| 2026-11-24 | `Clock` was declared before `Data` in autoloads, so startup saw an empty tuning dictionary and the clock ran a 0 s cycle. | Fixed: `Data` moved to the first autoload slot; zero-length phases are also ignored safely. |
| 2026-11-24 | `const PHASE_ORDER := PackedStringArray([...])` failed to parse in Godot 4.7 (`isn't a constant expression`). | Fixed: plain array constant. |

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
| 2026-11-24 | Committed and pushed the M0/M1 baseline to GitHub (`7c7bc96`), then built M2. Added the `clock` tuning block, full `Clock` autoload (day→dusk→night→dawn, two-stage smooth sky tint, Dawnglass charging, `Events` signals), `day_night_tint.gd`, `clock_readout.gd`, `scenes/debug/m2_clock.tscn` and a 13-check driven harness. Fixed two runtime bugs: autoload order (`Clock` read before `Data`) and a non-constant `PackedStringArray` const. Headless and windowed runs: 13/13 PASS, cycle 1110.00 s vs configured 1110.00 s, three-minute runtime clean, no `ERROR`/`WARNING` lines. | Wait for the human's go-ahead, then M3. |
| 2026-11-24 | M3 completed. Added `DaylightCheck` (range + angle + wall raycast), `ShadowComponent` (value/maximum, exposure loss, sunlight recovery, the 30% maximum drop, stage and flicker alphas), a cast-shadow lantern `PointLight2D`, Glint bursts with charges and shadow cost, the reusable `maren.tscn` keeper, `shadow_readout.gd`, `scenes/debug/m3_lights.tscn` and a 26-check harness. 26/26 PASS headless and windowed; three-minute runtime clean; M1 (16/16) and M2 (13/13) re-run with no regressions. | Wait for the human's go-ahead, then M4. |
