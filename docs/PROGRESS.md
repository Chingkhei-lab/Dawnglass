# Dawnglass: Progress

> Kept by the AI agent. Updated at the end of every task.
> Status: ✅ done (tested in a real run) · 🟡 in progress · ⬜ not started · ⛔ blocked

## Current status
- **Current module:** M6: Switching keepers ✅ complete and tested in a real run
- **Next step:** 🚦 Gate 1: the human plays a test night (M1–M6) and gives feedback in "Playtest notes"
- **Godot version installed:** 4.7.2.stable.official.ed1daf0bf (via Godot MCP `get_godot_version`; renderer Forward+, D3D12, AMD Radeon Graphics)
- **Waiting on the human for:** Gate 1 playtest approval before M7

---

## Modules

| Module | Status | Notes |
| --- | --- | --- |
| M0: Project setup | ✅ | Project named Dawnglass; main scene, 640×360 viewport, integer-friendly 2× override, nearest filtering, pixel snapping, 60 Hz physics, seven autoload shells, and validated tuning data. |
| M1: Moving one keeper | ✅ | Keeper `CharacterBody2D` with keyboard/gamepad binding, house and boundary collisions, base-anchored y-sort, smooth follow camera, sign interaction text box. All 16 checks pass; three-minute run clean. |
| M2: Day and night clock | ✅ | Clock runs day→dusk→night→dawn from tuning (720/45/300/45 s, cycle 1110 s); `CanvasModulate` blends palette colours through dusk and dawn; Dawnglass charges to 100% by nightfall; debug readout shows day, phase, phase time and charge. 13 checks pass; three-minute windowed run clean. |
| M3: Lights and shadows | ✅ | Lantern `PointLight2D` with cast shadows and no gameplay effect; Glint bursts with charges, shadow cost and a wall-aware `DaylightCheck` raycast; `ShadowComponent` with value/maximum, exposure loss, sunlight recovery, the 30% maximum drop and the three visible stages. 26 checks pass; three-minute windowed run clean; M1/M2 re-verified. |
| M4: Creatures (2 types) | ✅ | Walker chases the nearest person; Lurker waits in dark and rushes a nearby person or a lit lantern within its notice range; both ignore lantern light; Glint daylight destroys them; contact turns a person into a GameState-marked Sleeper and fires `person_taken`; keeper shadow leans toward nearby creatures. 22 checks pass; windowed run includes a 40-creature FPS sample. |
| M5: The lighthouse beam | ✅ | Staffed lamp room drives a daylight beam with mouse/right-stick aim, limited turn speed and acceleration (240 deg/s² to 90 deg/s), a focused narrow mode, a predictable auto sweep with a 120° gap, and a rock-occluded cone; the beam drains stored Dawnglass and the operator's shadow, and the Dawn Pulse ring destroys creatures at a large charge/shadow cost. 31 checks pass; three-minute windowed run clean. |
| M6: Switching keepers | ✅ | Two keepers (Maren, Ivo) with Tab / gamepad Y switching at any time; the camera glides to the new keeper; the keeper left in the lamp room keeps the beam sweeping on auto while a street keeper stands guard; both keepers' shadows keep updating (exposure/recovery) while uncontrolled. 22 checks pass. |
| 🚦 Gate 1: Is the core fun? | 🟡 | Waiting on the human: play the current main scene (M1–M6 test night) and write feedback in "Playtest notes". Do not start M7 until approved or given changes. |
| M7: Townsfolk, the Hall and promises | ⬜ | |
| M8: Hollow houses | ⬜ | |
| M9: Dawn summary, HUD and saving | ⬜ | |
| M10: The first playable slice | ⬜ | |
| 🚦 Gate 2: The slice | ⬜ | Needs the human to play |

### Tests for the current module
- ✅ Two keepers registered; Maren starts controlled; camera follows her; the staffed lamp room is in manual mode; the switch action is bound.
- ✅ One-button switch moves control to Ivo, retargets the camera, and puts the left-behind Maren's beam into auto: it swept 44.5° in 1.5 s while the camera glided 306.1 → 0.0 px to Ivo; Maren stayed put.
- ✅ Switching mid-movement: Ivo moved 40 px, switch stopped him in place (< 0.5 px drift) while Maren immediately took over and moved 40 px with the same held input.
- ✅ Both shadows update while one is uncontrolled: in a 2 s Glint both Maren (controlled) and Ivo (uncontrolled) dropped 1.00 → 0.90.
- ✅ Switching inside the lamp room works: control returns to Maren, beam back to manual, camera back on her, and Ivo on the street keeps guarding.
- ✅ Readout shows the active keeper and both shadow values.
- ✅ Three-minute windowed run: 22/22 PASS, `M6 RUNTIME CHECK COMPLETE`, no `ERROR`/`WARNING` lines. The runtime leaves Ivo controlled on the street so Maren keeps the beam sweeping, with Walkers spawned into the sweep. M1 (16/16), M2 (13/13), M3 (26/26), M4 (22/22) and M5 (31/31) re-run with no regressions.
- 🚦 Gate 1 needs the human to play and record feedback in "Playtest notes".

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
| 2026-11-24 | GAME_BIBLE §7.4 | Speeds, detection and contact radii, and the shadow-lean distance are not given. | Walker 40 px/s, Lurker rush 70 px/s, Lurker trigger 120 px, lantern notice 140 px, contact 10 px, lean range 80 px with an 8 px maximum. | Open |
| 2026-11-24 | GAME_BIBLE §7.4 | Whether creatures die in ordinary daytime sunlight (as opposed to Dawnglass light) is not specified. | Only Dawnglass daylight (Glint now, beam later) kills them; daytime hiding/spawning arrives with later modules. | Open |
| 2026-11-24 | GAME_BIBLE §7.4 | Which people creatures can take is not narrowed down. | Any takeable node in the `persons` group (keepers and villagers); Sleepers are ignored. | Open |
| 2026-11-24 | AGENT_BUILD_GUIDE §5 M4 | The "steady 60 FPS" test has no measurement rule. | Windowed run spawns 40 Walkers (contact disabled so they stay alive) and averages `Engine.get_frames_per_second()` over 600 frames after a 1 s warmup; floor is `creatures.fps_target` = 55. Fast headless runs skip it. | Open |
| 2026-11-24 | GAME_BIBLE §6.2 | Beam range, cone width, turn speed/acceleration and the draw rates are not given. | 320 px range, 10° half-angle, 90 deg/s with 240 deg/s² acceleration, 0.0025 Dawnglass/s and 0.01 operator shadow/s. | Open |
| 2026-11-24 | GAME_BIBLE §6.2 | "Can be focused" is not defined, and no focus key is given. | Focus narrows the half-angle to 5° and multiplies both draw rates by 1.5; bound to Shift / right mouse button (provisional). | Open |
| 2026-11-24 | GAME_BIBLE §6.2 | The "slow, predictable sweep with gaps" has no pattern, limits or pause. | Triangle sweep 30–150° at 30°/s with a 1 s pause at each end; the 120° sector outside those limits is the permanent gap. M6 will drive auto mode when the player switches keepers. | Open |
| 2026-11-24 | GAME_BIBLE §6.3 | Dawn Pulse radius, duration, ring width and costs are not specified. | 320 px radius expanding over 1.2 s in a 14 px band; 0.50 stored Dawnglass and 0.20 operator shadow per use. | Open |
| 2026-11-24 | GAME_BIBLE §6.2 | Whether the operator is lit by the beam they are aiming is not stated. | Points within the 24 px lamp-room radius are exempt, so the beam drains the operator only through its explicit cost, never twice. | Open |
| 2026-11-24 | AGENT_BUILD_GUIDE §5 M6 / GAME_BIBLE §7.1 | The one-button switch key is not specified. | Tab on keyboard, Y on gamepad (provisional). | Open |
| 2026-11-24 | AGENT_BUILD_GUIDE §5 M6 | What "keeps doing their last job" means for an idle street keeper is not defined. | The uncontrolled keeper stops in place and keeps their lantern state ("standing guard"); no path-following yet. | Open |
| 2026-11-24 | GAME_BIBLE §7.1 | Whether a taken keeper can be switched to is not stated. | Switching does not check Sleeper state yet; a taken keeper simply ignores input. | Open |
| 2026-11-24 | GAME_BIBLE §6.3 | No input is specified for the Dawn Pulse. | Currently method-only (`Beam.fire_dawn_pulse()`, exercised by the M5 harness); bind to a key together with the HUD in M9. | Open |

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
| 2026-11-24 | `run/main_scene` points at `scenes/debug/m4_creatures.tscn` during M4. | Same main-scene convention as earlier modules. |
| 2026-11-24 | Creatures are plain `Node2D` with distance checks, not physics bodies. | Contact and detection need no collision shapes; 40 creatures cost almost nothing. |
| 2026-11-24 | Person protocol via the `persons` group: `is_takeable()` and `take_shadow()`. | Let creatures work with any takeable actor (keeper or stand-in villager) without type coupling; Sleepers are skipped. |
| 2026-11-24 | `Sleeper` state stored as id strings in `GameState.sleepers`; `Events.person_taken` keeps its no-argument signature. | Matches the existing signal and gives later modules a simple save-friendly list. |
| 2026-11-24 | `villager.tscn` is a minimal stand-in for M4 only. | M7 replaces it with the real townsfolk and routines; the person protocol already matches. |
| 2026-11-24 | `run/main_scene` points at `scenes/debug/m5_beam.tscn` during M5. | Same main-scene convention as earlier modules. |
| 2026-11-24 | Beam staffing is physical: the operator must be a `CharacterBody2D` in the `persons` group inside the lamp room's `Area2D`. | No motor; matches the bible rule that a person turns the beam, and works with the M6 switch untouched. |
| 2026-11-24 | The beam joins `daylight_fields` while staffed, but exempts the lamp-room radius. | Creatures die through the same `DaylightCheck` path used by the Glint; the operator's loss is paid once, by the beam's explicit drain. |
| 2026-11-24 | Turning uses a braking clamp (`sqrt(2 * accel * distance)`) on top of the speed limit. | Without it the beam overshot the aim angle by tens of degrees and oscillated; now it settles exactly. |
| 2026-11-24 | Dawn Pulse is an expanding annulus field; costs are paid on fire. | Matches "ring of daylight" and keeps the cost check exact, independent of ring travel. |
| 2026-11-24 | `run/main_scene` points at `scenes/debug/m6_switch.tscn` during M6. | Same main-scene convention as earlier modules. |
| 2026-11-24 | Switching is a scene-level manager (`KeeperSwitch`) that flips `controlled` on keepers and retargets the follow camera. | Keeps the controller small and leaves room for the real game to place one manager; camera gained `set_target()`. |
| 2026-11-24 | An uncontrolled keeper stops in place but keeps `_update_shadow()` running. | "Keeps doing their last job" for a street keeper is standing guard; exposure still applies, which Gate 1 needs. |
| 2026-11-24 | The beam switches mode only when its operator or their `controlled` flag changes. | Auto sweep continues while the player watches elsewhere, without fighting direct mode changes from debug harnesses. |

## Known bugs
| Date found | Bug | Status |
| --- | --- | --- |
| 2026-11-24 | Malformed `[input]` block in `project.godot` made Godot exit before printing output. | Fixed: block removed, actions bound in code. |
| 2026-11-24 | Follow camera's exported node target did not resolve in the hand-written scene, leaving it at the origin. | Fixed: switched to `@export var target_path: NodePath`. |
| 2026-11-24 | `Clock` was declared before `Data` in autoloads, so startup saw an empty tuning dictionary and the clock ran a 0 s cycle. | Fixed: `Data` moved to the first autoload slot; zero-length phases are also ignored safely. |
| 2026-11-24 | `const PHASE_ORDER := PackedStringArray([...])` failed to parse in Godot 4.7 (`isn't a constant expression`). | Fixed: plain array constant. |
| 2026-11-24 | `shadow_lean()` failed to parse: `nearest` was typed `Node`, so `(nearest.global_position - global_position)` had no inferred type. | Fixed: keep the nearest creature in a `Node2D` variable (cast from the group array). |
| 2026-11-24 | First beam steering overshot the target by tens of degrees and oscillated (speed cap applied without braking distance). | Fixed: desired speed is also clamped to `sqrt(2 * accel * |delta angle|)`. |
| 2026-11-24 | M5 readout and test failed to parse on `shadow.value` / `get_node_or_null` results typed as Variant. | Fixed: explicit `Node` and `float` annotations. |
| 2026-11-24 | M6 step-3 burst cleanup freed every `daylight_fields` node, including the beam, so later steps hit a freed instance. | Fixed: the debug helper skips the beam. |

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
| 2026-11-24 | M4 completed. Added `creature_base.gd` (group registration, daylight death via `daylight_fields`, nearest-person search, distance contact), `walker.gd` (chases nearest person), `lurker.gd` (hidden until a person enters 120 px or a lit lantern enters 140 px), a `persons` protocol (`is_takeable`/`take_shadow`) on the keeper plus `villager.tscn`, `GameState.sleepers` with `mark_sleeper`, keeper shadow lean, `creature_readout.gd`, `scenes/debug/m4_creatures.tscn` and a 22-check harness; windowed runtime adds a 40-creature FPS sample. 22/22 PASS headless and windowed. | Wait for the human's go-ahead, then M5. |
| 2026-11-24 | M5 completed. Added `beam.gd` (lamp-room staffing, mouse/right-stick aim with speed and acceleration limits plus braking, focus mode, clamped auto sweep with end pauses, cone/range/occlusion daylight check, Dawnglass and operator drain) and `dawn_pulse.gd` (expanding annulus daylight ring with charge/shadow cost), lighthouse debug scene with a rock occluder, `beam_readout.gd` and a 31-check harness. 31/31 PASS headless; three-minute windowed runtime clean with Walkers spawned into the sweeping beam. | Wait for the human's go-ahead, then M6 (Gate 1 comes after M6). |
| 2026-11-24 | M6 completed. Added the `controlled` flag and `body_color` to the keeper controller, `ivo.tscn`, a scene-level `KeeperSwitch` (Tab / gamepad Y, camera retarget via new `FollowCamera.set_target()`), beam mode sync to the operator's control state, `switch_readout.gd`, `scenes/debug/m6_switch.tscn` and a 22-check harness. 22/22 PASS headless; three-minute windowed runtime clean. | 🚦 Gate 1: human plays a test night and gives feedback before M7. |
