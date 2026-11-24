# Dawnglass: Build Guide for the AI Agent

> This file tells you, the engineering agent, **how to build** the game.
> **What** the game is lives in `GAME_BIBLE.md`. Read it before you start.
> **What's done** lives in `PROGRESS.md`. You keep it up to date.
> All three files live in the project's `docs/` folder.

---

## 1. Who you are and how you work

You are the only engineer on **Dawnglass**, a 2D pixel-art game in **Godot 4 (GDScript)**, using the Godot MCP tools. The human makes the design decisions and supplies the art and sound. You write and test the code.

### The rules of working
1. **At the start of every session:** read `PROGRESS.md` first, then the parts of `GAME_BIBLE.md` that relate to your current task.
2. **Work on one module at a time** (§5). Don't start a module until the modules it depends on are marked done.
3. **Prove it works by running it.** Run the project, read the debugger output, and check the module's tests. Never mark something done because the code "should" work.
4. **Update `PROGRESS.md` at the end of every task**, not only at the end of a session (§8).
5. **Stop at the gates.** At a 🚦 gate, stop and ask the human to play it. Don't continue until they say so.
6. **Don't invent design.** If the bible says **(open)** or is silent, build the smallest reasonable version, mark it **provisional** in code comments and in `PROGRESS.md` → "Spec gaps", and carry on. If the gap blocks you, ask.
7. **Keep it small.** If a feature isn't in the current module, don't build it, even if it seems easy. Write it under "Ideas for later" in `PROGRESS.md`.

### The first session: setup only
In the first session you **write no game code**. You:
1. Read all three docs in full.
2. Prove the toolchain works: check the Godot version, read the project info, create and delete a throwaway scene, run the empty project, read the debug output, stop it. Report the exact output.
3. Fill in the Godot version and a first session-log entry in `PROGRESS.md`.
4. Restate, in your own words, the game in three sentences, the first slice (GAME_BIBLE §13), and the M0 and M1 tests.
5. Give your file plan for M0 and M1, and list anything in the docs that's unclear or contradicts itself.
6. Stop and wait for the human's go-ahead.

---

## 2. Technical constraints

- **Engine:** Godot 4.x, **GDScript only**. At the start of the first session, check the installed version (`godot --version` or the MCP equivalent) and write it in `PROGRESS.md`. Use only features that version has.
- **No C#, no plugins with native code, no paid assets.** Pure-GDScript tools (for example the GUT test framework) are fine.
- **2D, 3/4 top-down view** (GAME_BIBLE §10.1). A normal square grid, **not isometric**. Y-sorting so characters walk behind and in front of objects correctly.
- **Pixel-perfect:** a low base resolution (start with **640×360**), integer scaling, nearest-neighbour filtering, 2D transform snapping on. The camera may follow and smooth, but no rotation.
- **Physics at 60 Hz.** Gameplay logic runs in `_physics_process`. Turn on physics interpolation if the Godot version supports it, for smooth motion.
- **Lighting is core:** `CanvasModulate` for night, `PointLight2D` for lights, `LightOccluder2D` for shadows. Wherever gameplay needs to know whether something is lit, **use your own check** (distance + angle + raycast against walls), never the renderer's.
- **No gameplay numbers in scripts.** Every speed, radius, cost and duration lives in `res://data/tuning.json` or another file in `res://data/`. Scripts read from there.
- **Every script under 300 lines.** Split into small components.
- **No `await get_tree().create_timer()`** for gameplay. Use `Timer` nodes or frame counters, so pausing and saving work.
- **Randomness** goes only through the `Rng` autoload (seeded, saved).
- **Art and sound are placeholders until the human supplies real ones:** simple shapes with the right size and outline, plus real lighting. When sprites arrive, they replace the placeholders at the same position and pivot. Never generate pixel art with shaders.

---

## 3. Folder layout

```
res://
  project.godot
  scenes/
    main.tscn                    # starts the game, holds the world and the UI
    world/                       # areas: lighthouse, hall, street, beach
    keepers/                     # keeper scenes
    townsfolk/                   # NPC scenes
    creatures/                   # creature scenes
    lights/                      # lantern, glint, beam, pulse
    ui/                          # HUD, dialogue, dawn summary, menus
    debug/                       # one test scene per module
  scripts/
    autoload/                    # global singletons (§4)
    keepers/  townsfolk/  creatures/  lights/  world/  ui/
    components/                  # small reusable pieces (health, shadow, interact...)
  data/
    tuning.json                  # every gameplay number
    keepers.json  creatures.json  townsfolk.json  dialogue/
  assets/
    sprites/  audio/  fonts/
  tests/                         # automated tests (if GUT is used)
  tools/                         # helper scripts (placeholder sound generator, etc.)
```

---

## 4. Shared systems (autoloads)

Keep each one small. Systems talk to each other through **signals on `Events`**, not by reaching into each other's scenes.

| Autoload | Job |
| --- | --- |
| `Events` | A signal bus: `day_started`, `night_started`, `dawn`, `keeper_switched`, `person_taken`, `promise_kept`, ... |
| `GameState` | The single source of truth: trust, bonds, inventory, who's alive/taken/faded, promises, shadow values, flags |
| `Clock` | In-game time, day/night phase, day length by season, Dawnglass charging |
| `Data` | Loads and checks every JSON file at startup. **Stops with a clear error** if a value is missing |
| `SaveSystem` | Saves and loads `GameState` (one slot, autosave at dawn and at the start of each day) |
| `Audio` | Plays sounds and music through buses: Master → Music / SFX / Ambience |
| `Rng` | The only source of randomness. Seeded and saved |

---

## 5. Modules: build in this order

Each module is a small, separate piece that can be tested on its own. Every module has:
- a **debug scene** in `scenes/debug/` that shows it working alone, and
- **tests**: checks that print `PASS` or `FAIL` lines in the output (or GUT tests).

A module is **done** only when all of its tests pass in a real run, the output shows no errors or warnings, and `PROGRESS.md` is updated.

### M0: Project setup
Project settings (resolution, scaling, snapping, filtering, physics rate), folder layout, all autoloads as empty-but-working shells, `tuning.json` with the first values, `Data` loading.
- [ ] The project runs with no errors or warnings.
- [ ] `Data` loads `tuning.json`, and a deliberately missing key gives a clear error.
- [ ] The Godot version is written in `PROGRESS.md`.

### M1: Moving one keeper
One keeper walks around a small test area (keyboard + gamepad), collides with walls, and y-sorts behind and in front of objects. The camera follows smoothly.
- [ ] Movement and collisions work; no getting stuck on corners.
- [ ] The keeper walks behind a house and in front of it correctly.
- [ ] Interacting with an object (a sign) shows a text box.

### M2: Day and night clock
`Clock` runs a day and a night using the lengths in `tuning.json`. The light changes smoothly from day through dusk to night and back to dawn. Dawnglass charges during daylight.
- [ ] One full cycle takes the configured time (±1 s).
- [ ] The `day_started`, `night_started` and `dawn` signals fire once each, in order.
- [ ] The Dawnglass charge rises during the day and is shown on a debug readout.

### M3: Lights and shadows
The normal lantern (sight only) and the Glint (short daylight burst, limited charges). A shared **"is this point lit by daylight?"** check that respects walls. Every keeper has a **shadow** value and a **maximum shadow** (GAME_BIBLE §7.2). Shadow drops with Dawnglass exposure and recovers in sunlight up to the maximum. Their visible shadow gets fainter as it drops. (Raising the maximum through people comes in M7.)
- [ ] The lantern lights the area but has no gameplay effect on anything.
- [ ] The Glint's daylight check is blocked by walls.
- [ ] Shadow drops while exposed, by the amount set in `tuning.json`, and the visible shadow fades with it.
- [ ] Shadow recovers in sunlight at the set rate, but never above the keeper's current **maximum**.
- [ ] Falling below 30% lowers the maximum by the set amount (once per drop below 30%).
- [ ] The visible shadow shows the stages in GAME_BIBLE §7.2 (normal, flickering, faint).

### M4: Creatures (2 types)
- **Walker:** heads toward the nearest person.
- **Lurker:** waits in dark spots, then rushes a person who comes near.

Daylight (Glint, beam) destroys them; normal light doesn't. **Lurkers notice a lit lantern** from the distance set in `tuning.json`; Walkers ignore lanterns. When a creature gets close, the keeper's shadow **leans toward it**. A creature that reaches a person **pulls their shadow out**: the person collapses as a **Sleeper** (stays in the world, can't act, marked in `GameState`), and `person_taken` fires. (GAME_BIBLE §7.4)
- [ ] Both creatures behave as described in the debug scene.
- [ ] A lantern does nothing to them; the Glint and daylight do.
- [ ] A Lurker notices a lit lantern at the set range and ignores an unlit one; a Walker ignores both.
- [ ] A taken person becomes a Sleeper (body stays, can't act, marked in `GameState`).
- [ ] The shadow lean is visible when a creature is within the range set in `tuning.json`.
- [ ] 40 creatures on screen run at a steady 60 FPS.

### M5: The lighthouse beam
A keeper in the lamp room can operate the beam. **Under player control:** aim with the mouse or right stick; the beam turns with a limited speed and acceleration (no snapping), and can be focused. **On its own:** a slow, predictable sweep with gaps. The operator loses shadow while the beam is on. The beam uses the stored Dawnglass. A **Dawn Pulse** releases a ring of daylight at a large cost.
- [ ] Turning speed and acceleration match `tuning.json` (logged).
- [ ] The automatic sweep follows its pattern and leaves the gaps it should.
- [ ] The beam's daylight check is blocked by rocks and buildings.
- [ ] Operator shadow loss and Dawnglass use match `tuning.json`.
- [ ] The Dawn Pulse destroys creatures in its ring and costs what it should.

### M6: Switching keepers
The second keeper: M1–M5 used **Maren**; now add **Ivo**. Switch at any time with one button. The camera moves to the new keeper. The keeper you left keeps doing their last job (beam sweep, standing guard, following a path).
- [ ] Switching works at any moment, including mid-movement and while in the lamp room.
- [ ] A keeper left in the lamp room keeps sweeping; a keeper left on the street keeps guarding.
- [ ] Both keepers' shadow values update even while not controlled.

### 🚦 Gate 1: Is the core fun?
Stop. Ask the human to play a test night with M1–M6: two keepers, creatures, the beam and switching. Write their feedback in `PROGRESS.md` → "Playtest notes". **Don't continue until they approve or ask for changes.**

### M7: Townsfolk, the Hall and promises
Three townsfolk with simple daily routines: **Odile, Sister Vell and Old Ferrow** (GAME_BIBLE §7.3). At dusk Odile and Vell walk to the Hall. **Old Ferrow refuses** and stays home. Talking to them before night gives a **promise** ("keep my home lit"). Trust and bond values in `GameState`. A simple dialogue box with choices, read from `data/dialogue/`.
- [ ] At dusk, every NPC except the stubborn one walks to the Hall.
- [ ] The promise is tracked during the night and settled at dawn (kept or broken), changing trust as set in the data.
- [ ] Dialogue choices change trust, bond or flags as written in the data.
- [ ] A kept promise raises the keeper's **maximum shadow** as set in the data (GAME_BIBLE §7.2).

### M8: Hollow houses
A home left dark and empty at night becomes **hollow**. The next day it has creatures inside and a dark look. A keeper clears it with the lantern and the Glint. Then the family moves back.
- [ ] A dark, empty home is hollow at dawn; a lit one isn't.
- [ ] Clearing the house changes its state and lets the family return.

### M9: Dawn summary, HUD and saving
A **dawn summary** screen (who's safe, who's asleep, promises, creatures destroyed). At dawn, every Sleeper is moved to a **bed in the chapel**. A minimal HUD: the active keeper's shadow, Glint charges, stored Dawnglass, time of day. As few numbers on screen as possible. Saving and loading.
- [ ] The dawn summary matches what happened during the night.
- [ ] Every Sleeper is in a chapel bed at dawn.
- [ ] Save → quit → load restores the same state (save the file again; it should be identical).

### M10: The first playable slice
Put it all together as described in GAME_BIBLE §13: one area, 2 keepers, 1 day and 1 night, start to finish. Placeholder art and sound are fine.
- [ ] A full day and night can be played start to finish with no errors.
- [ ] Every system above works together in the real area, not only in debug scenes.

### 🚦 Gate 2: The slice
Stop. Ask the human to play the full slice. Record the feedback. **Nothing after this point gets built until the human decides what comes next** and updates `GAME_BIBLE.md`.

### After the slice (don't build yet)
Listed only so you can design the code to allow them later:
Sol and Pip, the Mirror and Flare shard gadgets, the Reveal and Mend tunings, the Lost and waking Sleepers, beacons, more areas, more creatures (GAME_BIBLE §8), weather, seasons, the mine, the story and the four endings, real art and sound, menus, settings and accessibility, export.

---

## 6. Testing

- **Every module has a debug scene** that sets up exactly what's needed to show it working.
- **Tests print one line per check:** `PASS M5 beam turn speed 105 deg/s` or `FAIL M5 ... expected X, got Y`.
- Useful launch options to add when needed: `--debug-scene=NAME`, `--seed=N`, `--time=night`.
- **Before marking any module done,** run the project for **3 minutes** and confirm **zero errors and warnings** in the output.
- If something can only be judged by a person (does it look right? does it feel good?), say so in `PROGRESS.md` and ask the human.

---

## 7. Code habits

- Small scenes with small scripts. Prefer **components** (a `Shadow` node, an `Interactable` node) over large scripts.
- Use **signals** for "something happened" and **method calls** for "do this now".
- Name things after what they are in the game: `ShadowComponent`, `HallDoor`, `BeamOperator`.
- Mark every provisional rule with `# PROVISIONAL: see GAME_BIBLE §x` so it's easy to find later.
- Keep the game working after every task. Never leave the project broken at the end of a session.

---

## 8. Maintaining `PROGRESS.md`

`PROGRESS.md` is the shared memory between sessions, and the human reads it to see where things stand.

- **Update it at the end of every task.** Keep it short and accurate.
- Mark each module and each test with a status: ✅ done · 🟡 in progress · ⬜ not started · ⛔ blocked.
- **"Done" only means tested in a real run.** If you couldn't test something, write that down.
- Add to the **session log** each session: the date, what you did, what's next.
- Record **spec gaps** (what you had to guess), **known bugs**, **decisions** you made and why, and **ideas for later**.
- Never delete history. Mark old items as resolved instead.

---

## 9. Don't build

- Anything not in the current module.
- Anything marked **(open)** in the bible beyond its provisional rule.
- Multiplayer, 3D, online features, multiple save slots, procedural world generation, a skill tree, voiced dialogue.
- Features from the old design that the bible marks as dropped (the rewind lens, the single-screen arena, the fixed 8-hour day; see GAME_BIBLE §14).

If an idea seems worth having, write it under "Ideas for later" in `PROGRESS.md` and keep going.
