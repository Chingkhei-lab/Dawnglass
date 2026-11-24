# Dawnglass: Game Bible

> This file describes **what the game is**: the world, the story, the rules and the feel.
> How to build it is in `AGENT_BUILD_GUIDE.md`. What's done is in `PROGRESS.md`. All three files live in `docs/`.
> If this file and the build guide disagree, **this file wins** on design and the guide wins on technical details.
> Anything marked **(open)** isn't decided yet. Don't invent an answer; use the provisional rule given, or ask.
> Every number in this file is a **starting value** to be tuned in playtests. They all live in `data/tuning.json`.

---

## 1. The game in one paragraph

**Hollin Cove** is a small fishing town at the mouth of a fjord: sea in front, mountains on every other side, and no way out. Every night, creatures made of **stolen shadows** come down from the mountain and up out of the fog. The only thing that stops them is **Dawnglass**, a crystal from deep inside the mountain that soaks up sunlight by day and gives it back as real daylight at night. You play four **keepers** who run the lighthouse, explore the fjord, look after the townsfolk and slowly uncover what's under the mountain. Every beam of Dawnglass light saves someone tonight, but it costs the person aiming it part of their shadow. And every shadow it takes feeds the thing that makes the creatures.

## 2. Pillars (every feature must serve at least one)

1. **Where you shine is what you save.** Light is limited, so wherever you point it, somewhere else stays dark.
2. **Every light costs a shadow.** Dawnglass light hurts the people who use it. Nothing powerful is free.
3. **The town remembers.** Promises, losses and rescues carry forward. Being remembered is what heals you.

## 3. Tone

Quiet, cold, tender, a little cruel. Warm amber light against slate-blue night. Nobody gives speeches. The horror is sad rather than gory: the creatures are lost, not evil. Moments of warmth (a shared meal in the Hall, a child's drawing of the lighthouse) matter as much as the scary ones.

---

## 4. The world

### 4.1 Setting: Hollin Cove
A fictional fishing town at the mouth of a narrow fjord. The **sea** lies to the south and ends in a permanent **fog bank** at the fjord mouth. **Mountains** close in on the other three sides: steep cliffs, pine forest on the lower slopes, snow above.

### 4.2 The map
One connected outdoor map (no loading screens between town areas). The mine and the sea caves are separate interior maps.

```
                 ▲▲▲  SNOW PEAKS  ▲▲▲
          ▲▲  [PASS BEACON]──(collapsed pass)  ▲▲
       ▲▲▲        │                         ▲▲▲
     ▲▲  FOREST  [MINE] ◄─ mine road ─[MINE BEACON]  ▲▲
    ▲▲   SLOPE     │                               ▲▲
   ▲▲              │  chapel      workshop           ▲▲
  ▲▲   [LIGHTHOUSE]──── TOWN STREETS ──── [CLIFF BEACON]
  ▲      (west point)   │  THE HALL  │      (east headland)
   ~~      docks ── HARBOUR ── market     BEACH + SEA CAVES
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   ~~~~~~~~~~~~~~~~ THE FJORD (sea) ~~~~~~~~~~~~~~~~~~~
   ░░░░░░░░░░░░░░░░ FOG BANK (fjord mouth) ░░░░░░░░░░░░
```

| Place | What it is | Role |
| --- | --- | --- |
| **The Lighthouse** | On the west point, above the harbour | The main light. The keepers' home base |
| **The Hall** | An old meeting hall in the middle of town, inside the beam's reach | Where most townsfolk sleep at night |
| **The Chapel** | Off the main street | Sister Vell's records, and the beds of the **Sleepers** (§7.4) |
| **Harbour, docks, market** | South of town | Daily life; boats coming in at dusk |
| **Town streets, workshop** | The centre | Homes, NPCs, requests, homes to protect. Pip's workshop |
| **Beach and sea caves** | Below the east cliffs | Exploring; things the fog washes up |
| **The forest slope** | North-west | Materials, hidden paths |
| **The old mine** | North, up the mine road, sealed | Where Dawnglass comes from. Where the truth is |
| **Cliff beacon** | East headland | First beacon to restore. Protects the beach and the east side |
| **Mine beacon** | On the mine road | Second beacon. Makes the road to the mine safe |
| **Pass beacon** | Near the collapsed pass, far north | Late game. Needed for the "Reopen the pass" route |
| **The collapsed pass** | The only road out | Blocked |

### 4.3 Dawnglass (the power)
- A pale crystal that grows in veins deep inside the mountain.
- **It soaks up sunlight during the day and releases it at night as true daylight.** The lighthouse doesn't make light; it gives back a piece of the day.
- When fully charged, or cracked under heat, it releases its light in a sudden **ring-shaped wave**. The lighthouse lens normally shapes this into a steady beam, but it can also fire a deliberate **Dawn Pulse** (§6.3).
- **The secret (revealed late, §9):** Dawnglass doesn't only store sunlight. **It grows by taking shadows.**

### 4.4 How it was discovered
The town was founded as a mining town. Generations ago, the miners dug too deep and broke into a huge mass of crystal: **the Heart**. That's when the creatures first appeared. A miner trapped in a collapsed tunnel, **Ivo's grandfather Aske**, survived the night because a vein of glowing crystal kept the dark away. **The cure and the curse came out of the same hole.** The first lighthouse was built with that crystal, and the mine was sealed. The official story says Aske died soon after. He didn't (§9).

### 4.5 Why they can't just light up the whole town
- **It's limited.** Dawnglass only stores as much sun as it caught that day. Cloudy days and short winter days mean less light.
- **It hurts people.** Dawnglass light slowly takes the **shadow** of anyone it touches (§7.2).
- **It attracts them.** Even as it burns creatures, it draws more of them. Lighting the whole town would pull the whole dark down onto it.
- **The good crystal is deep in the mine,** right where the creatures are.

### 4.6 The creatures: stolen shadows
- Every time Dawnglass light touches someone, it takes a bit of their shadow. Those shadows gather in the mine and in the fog and become **the creatures**.
- **They come to the town to get back into a person,** any person. When one reaches someone, it **pulls their shadow out** and carries it into the dark. The person is left behind as a **Sleeper** (§7.4).
- **Sunlight and Dawnglass light destroy them,** because a shadow can't exist in full daylight. Normal light (lanterns, fire) does **nothing** to them; it only helps you see them.
- **By day they hide** in caves, the mine, the deep sea and fog banks. Dark places are still dangerous during the day.
- **They have no faces.** When one is near, **your own shadow leans toward it**, as if it wants to go too. This is the main danger cue.
- Full list in §8.

### 4.7 Why nobody leaves
- **The road is gone.** The only pass collapsed years ago.
- **The sea is a trap.** Boats that sail into the fog bank don't come back, with one exception: Sol (§7.1).
- **Their shadows are thin.** Everyone who has lived under Dawnglass light has a thinner shadow. People who tried to walk out were found faded on the road. **The town is tied to the light it depends on.**
- **Personal reasons.** Some are too old or poor to try, some won't leave family graves, and some believe the fog will lift one day. A few want to escape (§7.3).

---

## 5. Seasons, days and nights

- The story runs from **late autumn to the winter solstice**.
- **Days get shorter and nights get longer** as the game goes on. Since Dawnglass charges in sunlight, **power drops just as danger rises.**
- Day and night run on a continuous in-game clock. Starting real-time lengths:

| Stage | Day | Night |
| --- | --- | --- |
| Early | about 12 min | about 5 min |
| Middle | about 10 min | about 7 min |
| Near the solstice | about 8 min | about 10 min |
| **Solstice night** (finale) | — | the longest night |

- **Weather** changes how much Dawnglass charges (sun, clouds, snow) and what the night is like (fog, wind). The weather list is **(open)**.

---

## 6. Light

### 6.1 What every keeper carries
| Light | What it does | Limits |
| --- | --- | --- |
| **Lantern** (normal light) | Lets you see in the dark. Does nothing to creatures | Small radius. **Lurkers and Moths notice a lit lantern** from a distance; other creatures don't. Turning it off lets you sneak but see less |
| **Glint** (hand Dawnglass device) | A short-range burst of daylight that destroys weak creatures and pushes back strong ones | A few charges. Refills in sunlight or at a lighthouse. Each use costs the holder a little shadow |

### 6.2 The lighthouse beam
- **The beam is turned by a person, not a motor.** A keeper has to be in the lamp room.
- When the **player controls** that keeper, they aim the beam directly: a strong, flexible beam they can focus. It turns with weight (limited speed and acceleration), never snapping.
- When the player **switches to another keeper**, the operator keeps sweeping on their own in a **slow, predictable pattern with gaps**. Creatures can learn to slip through those gaps. Maren's auto-sweep is better than anyone else's.
- **Cost:** the operator is exposed to Dawnglass light all night and slowly loses shadow. Rotate who keeps the light.

### 6.3 Dawn Pulse
A big **ring of daylight** that rolls out from the lighthouse across the town, destroying or pushing back every creature it touches. It uses a large share of stored Dawnglass and costs the operator a lot of shadow. An emergency move.

### 6.4 Beacons
- You start with **one lighthouse**. Three **ruined beacons** can be restored, in this order: **Cliff**, **Mine**, **Pass** (§4.2).
- Each restored beacon lights a new area, protects more of the town and makes exploring safer.
- **Each beacon also needs a person to run it,** and they all share the same stored Dawnglass. More beacons mean more coverage but less power for each, and more keepers exposed.
- After each restored beacon, the creatures change their routes, and a new part of town starts getting hit until you light the next one.

### 6.5 Light tunings
The lighthouse (and later the beacons) can be **tuned** with lenses:
- **Burn:** destroys creatures (the default).
- **Reveal:** shows hidden creatures (Lurkers in shadows, Stretchers on walls).
- **Mend:** returns a Lost shadow to its Sleeper (§7.4). Does nothing to other creatures.
Unlock order: Burn at the start, Reveal early, Mend when the first person is taken. Exact timing **(open)**.

---

## 7. People

### 7.1 The keepers
You control **one keeper at a time** and can switch whenever you like. Keepers you aren't controlling **keep doing their last job** with simple behaviour: sweeping the beam, guarding a house, waiting in the Hall, or hiding.

| Keeper | Role | Who they are | Why they're here | Strength | Weakness or secret |
| --- | --- | --- | --- | --- | --- |
| **Maren** (30s) | The Keeper | The old keeper's apprentice. She took over when he walked into the fog last winter | She owes him, and nobody else will do it | Best beam control: steadier aim, a better auto-sweep | She has the **thinnest shadow** in town. Every night in the tower is a real risk |
| **Ivo** (50s) | The Climber | A former miner, grandson of Aske, who found Dawnglass | His family has always guarded the mine. He feels responsible | Climbs ledges, mines Dawnglass, carries more | His family has kept a **secret** about Aske and the Heart (§9) |
| **Sol** (20s) | The Sailor | A young fisher. Her boat drifted out of the fog bank with only her aboard | The town doesn't trust her. She wants to know why she survived | Rows the boat, swims, explores sea caves, can step briefly **into the fog** | She doesn't remember what happened in the fog. Some creatures seem to **know** her |
| **Pip** (13) | The Tinkerer | The bell-ringer's kid, always building things | Pip insists on helping, and the adults can't stop it | Builds and repairs gadgets and beacons, fits through gaps | Pip has the **strongest shadow** because they've barely been exposed. Using Pip in the light should feel wrong |

- **First playable slice:** Maren and Ivo only. Sol and Pip join later in the story.
- What exactly happened to Sol in the fog is **(open)**.

### 7.2 Shadow
Every keeper and townsperson has a **shadow**, shown through how solid their shadow looks (no number on screen by default; an optional number in settings).

- **Losing it:** exposure to Dawnglass light: aiming the beam, using the Glint, standing in a Dawn Pulse.
- **Getting it back (short term):** shadow slowly returns in **sunlight** during the day.
- **The maximum drops:** each time someone falls below **30%**, their **maximum** shadow drops a little for good.
- **Raising the maximum again only happens through people:** a bond moment with an NPC, waking a Sleeper, a kept promise. *Being remembered restores you.*

| Shadow | What happens |
| --- | --- |
| 100–60% | Normal |
| 60–30% | The shadow flickers. Small **memory gaps**: they forget a name, and some dialogue options go grey |
| 30–1% | The shadow is faint. Creatures **target them first**. They sometimes hear whispers |
| 0% | **They fade.** Gone for good |

### 7.3 Townsfolk
- Most townsfolk sleep in **the Hall** at night.
- **Some refuse to leave their homes.** They ask you to **promise** to keep their street lit. Kept promises build trust; broken ones cost it, and someone may be taken.
- **Empty homes left dark at night become "hollow":** shadows settle inside like a nest. The next day, a keeper has to clear the house with lantern and Glint before the family can move back.
- **Theft and conflict** happen between *people*, not creatures (for example, Kael stealing Dawnglass shards in the Hall). These are story events, not a full system.
- NPCs make **requests** in natural conversation (no request cards). Accepting, refusing and delivering change **trust** (town-wide) and **bond** (with each person).
- Each NPC **leans toward one ending**, so the town is divided:

| NPC | Who they are | Their story | Leans toward |
| --- | --- | --- | --- |
| **Old Ferrow** | Retired fisherman | Won't leave his late wife's house at night. Your first promise | Survive |
| **Odile** | The baker | Keeps everyone fed in the Hall. Her husband is a Sleeper | Free the shadows |
| **Sister Vell** | Keeper of the chapel and the town records | Cares for the Sleepers. Knows old history about the mine | Free the shadows |
| **Bram** | The ferryman's son, 17 | Desperate to escape. Secretly digging at the collapsed pass | Reopen the pass |
| **Greta** | The harbourmaster, unofficial town leader | Practical and hard. Thinks the light is worth any price | Survive, or seal the mine |
| **Kael** | A smuggler | Steals and sells Dawnglass shards. Not evil, just afraid | Reopen the pass |
| **Doctor Aulden** | The town doctor | Studies the shadow loss. Wants to understand it | Seal the mine |
| **Ness** | The schoolteacher | Looks after the children in the Hall. Pip's teacher | Free the shadows |

**First slice:** Old Ferrow (the stubborn one), Odile and Sister Vell.

### 7.4 Sleepers and the Lost
1. A creature reaches a person and **pulls their shadow out**.
2. **The body stays behind.** The next morning it's found in the street or on the shore, breathing but **asleep and shadowless**. The town keeps the Sleepers in **beds in the chapel**.
3. Their shadow returns on later nights as a **Lost**: a creature in their outline that wanders, doesn't attack, and searches for its body.
4. Light the Lost with **Mend** until it's restored, and the **Sleeper wakes up**. That raises the maximum shadow of the keeper who did it (§7.2) and adds a story moment.
5. **Time limit:** if a Sleeper isn't restored within **5 nights**, the body fades and they're gone for good. Burning a Lost with normal Burn light also loses them for good. Their name is crossed out in the keeper's log.

**Odile's husband is a Sleeper from before the game starts,** so the chapel already has one bed in use on day 1. He's too far gone to save with the basic Mend (special story case, **(open)**).

---

## 8. Creatures

All of them are **stolen shadows**. Sunlight and Dawnglass destroy them, normal light doesn't, and they hide during the day.

| Creature | What it is | Behaviour | How to deal with it | First appears |
| --- | --- | --- | --- | --- |
| **Walker** (slice) | A plain human shadow | Walks straight at the nearest person. Ignores lanterns | Any daylight | Night 1 |
| **Lurker** (slice) | A shadow that hides in shadows | Waits in dark corners, rushes people who come near. **Notices lit lanterns** | Reveal light, or a Glint up close | Night 1 |
| **Hollow** | Shadows that settle into an empty dark house | Doesn't move, but grows. Turns the house into a nest | Clear it by day | Early |
| **Flock** | Shadows of birds and small animals | A fast swarm. Weak alone, dangerous together | A Dawn Pulse or a wide beam | Early |
| **Stretcher** | A long shadow that lives on walls | Moves **only along walls and surfaces**, stretching toward people | Light the wall it's on | Early to mid |
| **Moth** | A shadow drawn to Dawnglass itself | Goes for the lighthouse, beacons and the Glint, and **drains their charge**. **Notices lit lanterns** | Close the beam, use a lantern as bait, or the Glint | Mid |
| **Tidewalker** | Old, huge shadows from the fog bank (lost sailors) | Slow, comes from the sea, tough. Attacks boats and docks | A focused beam | Mid |
| **The Lost** | The shadow of a specific taken townsperson | Wanders, doesn't attack, looks for its body | **Mend** wakes the Sleeper; Burn loses them for good | After the first person is taken |
| **The First Shadow** (final boss) | Aske's own shadow, the oldest of them all | Leads the others. Appears in the final act | Depends on the route chosen | Late |

---

## 9. The truth, the goal and the endings

### 9.1 What's under the mountain
- Deep under the mountain is a huge mass of Dawnglass: **the Heart**.
- **Dawnglass grows by taking shadows.** That's why it takes the shadows of people it touches. The light and the creatures are **one process**: Dawnglass eats shadows and gives back daylight.
- **Aske never died.** He's down there, shadowless and ancient, **keeping the Heart fed**. He believes the town would die without the light, so he sends the shadows out to bring in more. Ivo's family has known for generations and kept it quiet.
- The details of the final act (how you reach the Heart, what Aske says) are **(open)**.

### 9.2 The big decision
**Main goal:** find out what's under the mountain and **free the shadows**.
About two-thirds of the way through, after learning the truth, the town faces **one big decision**. Until then, about 80% of the game is shared by every route; only the last act differs.

| Route | What it takes | The ending |
| --- | --- | --- |
| **Free the shadows** (true ending) | Break the Heart. Needs high trust, Sleepers saved, and the full truth | Every shadow goes home at once and the Sleepers wake. But **there will never be Dawnglass again**: the town has to survive one last, longest night with no magic light at all |
| **Survive to the solstice** | No big decision; you just hold on | The town lives, but the cycle starts again next winter |
| **Reopen the pass** | Restore the Pass beacon and clear the road | Some escape with thin shadows; some fade on the road. The town empties |
| **Seal the mine** | Bury the Heart, Aske and every shadow | No more creatures, no more light, and the Sleepers never wake. A grim, quiet ending |

---

## 10. Day and night loop

```
DAY (short: choose 2–4 things)              NIGHT
 ├ EXPLORE (main): beach, caves, forest,     ├ townsfolk go to the Hall (or stay home)
 │   mine — Dawnglass, materials, clues      ├ a keeper runs the beam (and beacons, later)
 ├ TOWN (second): talk, requests, promises,  ├ other keepers go out: guard homes,
 │   visit the Sleepers, clear hollow houses │   rescue people, explore with lantern + Glint
 ├ BUILD (third): repair beacons, gadgets,   ├ switch between keepers when needed
 │   reinforce the Hall                      └ dawn: who's safe, who's asleep, who faded
 └ decide who keeps the light tonight
```

- The day is short, so you can only do **2–4 things**. Choosing is the game.
- With several keepers, you can **send them to different places at once**. Switching between them is how you get more done in a short day.
- **The main night decision:** stay in the tower and protect the town properly, or go out to rescue, find or fix something while the beam sweeps on its own.

---

## 11. Gadgets

**First two (the first ones built after the slice):**
- **Mirror:** a portable mirror you set up in town. It **bounces the lighthouse beam** into an alley or behind a building it couldn't reach. The keeper in the tower and the keeper on the street have to work together.
- **Flare shard:** a small Dawnglass shard you throw. It lights an area with daylight for a few seconds.

**Later:**
| Gadget | What it does | Who's best with it |
| --- | --- | --- |
| **Glint upgrades** | More charges, a wider burst, a short cone | Everyone |
| **Shadow compass** | Points to the nearest Lost | Sol |
| **Dawnglass jar** | Carries extra charge for the Glint or a beacon | Ivo |
| **Grappling hook** | Climb cliffs, cross gaps | Ivo |
| **Signal bell** | Calls townsfolk to the Hall from far away | Pip |
| **Shuttered lantern** | A lantern you can narrow or close quietly | Everyone |
| **Beam remote** | Control a beacon's beam from a distance for a short time | Pip (late game) |
| **Light tunings** | Burn / Reveal / Mend lenses (§6.5) | Maren |

---

## 12. Look and sound

### 12.1 Camera and view
- **3/4 top-down view**, like *Sea of Stars*: you look down at an angle and see both the ground and the front faces of buildings, cliffs and people.
- **Not isometric.** The beam, shadows and movement work on a normal grid.
- The camera **follows the active keeper** smoothly. Switching keepers moves the camera to them.
- Height matters: cliffs, ledges and stairs make the mountains feel tall.

### 12.2 Lighting first
- Lighting carries the look. Night is dark slate blue; Dawnglass light is warm, bright and slightly unreal; lanterns are small and orange.
- Godot 2D lights, real shadows, and normal maps on sprites (when art arrives).
- Shadows are a mechanic, so **every character's shadow must always be readable**, especially when it leans toward a creature or grows faint.

### 12.3 Art
- Pixel art. **Art comes from the human** (asset packs, an artist, or their own). Until then, placeholder shapes with real lighting.
- Starting palette: `#141B29 #26354D #1B3B44 #7CA5B8 #FFB84D #E67E22 #F4F7FA`.

### 12.4 Sound
- Quiet and sparse: wind, waves, creaking wood, a distant foghorn. The beam hums. Whispers when shadow is low.
- Placeholder sounds can be generated by code; final audio comes from the human.

---

## 13. The first playable slice (prove it's fun first)

Everything above is the **full** game. The first goal is much smaller:

- **One area:** the lighthouse, the docks, the Hall, the chapel and one street with 3 homes.
- **2 keepers:** Maren (the beam) and Ivo (out in the street).
- **1 day and 1 night**, start to finish.
- **2 creature types:** Walker and Lurker.
- **Lantern, Glint and lighthouse beam (Burn only).** Shadow loss, sunlight recovery and the visible shadow stages.
- **3 townsfolk:** Odile and Sister Vell go to the Hall; **Old Ferrow refuses** and asks you to keep his home lit (a promise).
- **Sleepers:** anyone taken during the night is in a chapel bed at dawn (no Mend in the slice).
- **One hollow house** to clear the next morning, if a home was left dark and empty.
- **A dawn summary:** who's safe, who's asleep, whether the promise was kept.

**Success test:** a new player understands what to do without a tutorial screen, feels the tension of switching between the tower and the street, and wants to play the next night.

---

## 14. What we kept from the first design, and what we dropped

| Idea | Status |
| --- | --- |
| The Lost (restoring taken people) | **Kept**, now central: Sleepers + the Lost |
| Light types (burn / reveal / restore) | **Kept** as Burn / Reveal / Mend tunings |
| Requests and promises | **Kept**, as natural NPC conversations, not cards |
| Fog | **Kept**, as where shadows gather |
| Single fixed screen, no movement | **Dropped** |
| Rewind lens | **Dropped** |
| Fixed 8-hour day | **Dropped**, replaced by the real sun clock |
| 4 lens shapes | **Reworked** into lighthouse and beacon upgrades |
| 21 fixed nights | **Reworked** into seasons and day length (§5) |

---

## 15. Still open (decide before building them)

1. What happened to Sol in the fog, and why creatures know her.
2. The details of the final act: reaching the Heart, Aske's scenes, the boss fight on each route.
3. Odile's husband: can he be saved, and how?
4. The weather list and its effects.
5. Exact unlock timing for Reveal, Mend, beacons and gadgets.
6. How many in-game days the full story lasts.
7. Exact numbers: shadow loss and recovery rates, Dawnglass charge, creature counts per night.
8. Where the art comes from (asset pack, artist, or self-made).
