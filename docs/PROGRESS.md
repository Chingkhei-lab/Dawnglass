# Dawnglass: Progress

> Kept by the AI agent. Updated at the end of every task.
> Status: ✅ done (tested in a real run) · 🟡 in progress · ⬜ not started · ⛔ blocked

## Current status
- **Current module:** M2: Day and night clock ✅ complete and tested in a real run
- **Next step:** M3: Lights and shadows (after the human's go-ahead)
- **Godot version installed:** 4.7.2.stable.official.ed1daf0bf (via Godot MCP `get_godot_version`; renderer Forward+, D3D12, AMD Radeon Graphics)
- **Waiting on the human for:** go-ahead to start M3

---

## Modules

| Module | Status | Notes |
| --- | --- | --- |
| M0: Project setup | ✅ | Project named Dawnglass; main scene, 640×360 viewport, integer-friendly 2× override, nearest filtering, pixel snapping, 60 Hz physics, seven autoload shells, and validated tuning data. |
| M1: Moving one keeper | ✅ | Keeper `CharacterBody2D` with keyboard/gamepad binding, house and boundary collisions, base-anchored y-sort, smooth follow camera, sign interaction text box. All 16 checks pass; three-minute run clean. |
| M2: Day and night clock | ✅ | Clock runs day→dusk→night→dawn from tuning (720/45/300/45 s, cycle 1110 s); `CanvasModulate` blends palette colours through dusk and dawn; Dawnglass charges to 100% by nightfall; debug readout shows day, phase, phase time and charge. 13 checks pass; three-minute windowed run clean. |
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
- ✅ One full cycle takes the configured time (±1 s). Measured 1110.00 s against a configured 1110.00 s.
- ✅ The `day_started`, `night_started` and `dawn` signals fire once each, in order. Observed `night_started, dawn, day_started` for the first cycle (day 1 begins silently before the scene connects).
- ✅ Dawnglass charge rises during daylight and is shown on a debug readout. 0.25 → 0.50 mid-day, 100% at nightfall; readout line: `Day 1   DAY   215.7 / 720 s   Dawnglass 30%`.
- ✅ Light changes smoothly from day through dusk to night and back. Per-frame colour step ≤ 0.030 (dusk) and 0.031 (dawn) with a 2.25 total channel range; day and night colours match tuning exactly.
- ✅ Three-minute run: `M2 TESTS PASS`, `M2 RUNTIME CHECK COMPLETE`, log scan found no `ERROR` or `WARNING` lines.

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

## Decisions made
| Date | Decision | Why |
| --- | --- | --- |
| 2026-11-24 | Bind input actions in code instead of `project.godot`. | A hand-written `[input]` block was malformed and crashed startup; code binding is version-safe and testable. |
| 2026-11-24 | `run/main_scene` points at `scenes/debug/m1_keeper.tscn` during M1. | MCP `run_project` then exercises the current module; M10 replaces it with the real main scene. |
| 2026-11-24 | Autoload order starts with `Data`, then `Events`, `GameState`, `Clock`, `SaveSystem`, `Audio`, `Rng`. | `Clock` reads tuning in `_ready`; declared before `Data` it saw an empty dictionary. |
| 2026-11-24 | `run/main_scene` points at `scenes/debug/m2_clock.tscn` during M2. | Same pattern as M1: the main scene always boots the current module's debug scene. |

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
