# Akhtaam Dilmun – Godot Project README

This document describes the **project structure**, **installation**, **running instructions**, and **quest logic** for the Akhtaam Dilmun educational game built in **Godot 4**.

The focus is on how the project is organized and how each quest behaves in terms of **success, failure, and testing**.

---

## 1. Project Structure (res://)

res://
├─ assets/
│ └─ (sprites, UI images, audio, backgrounds)
│
├─ fonts/
│ └─ (custom fonts used in UI)
│
├─ scenes/
│ ├─ objects/
│ │ └─ (reusable scene objects such as interactables)
│ │
│ ├─ Quest3/
│ │ └─ (Quest 3 related sub-scenes or objects)
│ │
│ ├─ Quest1_Water_MapTracing.tscn
│ ├─ Quest2_Earth.tscn
│ ├─ Quest3_Pearls.tscn
│ ├─ Quest5_Unity.tscn
│ ├─ Quest6_Memory.tscn
│ ├─ quest_1_water.tscn
│ └─ Seal4_Harvest.tscn
│
├─ scripts/
│ └─ (GDScript files for quests, UI, and logic)
│
├─ overworld.tscn
├─ overworld.gd
├─ icon.svg
└─ project.godot

### Key Files
- **`overworld.tscn`**  
  Main hub where the player selects and enters quests.

- **`overworld.gd`**  
  Controls overworld navigation, quest access, and scene transitions.

- **Quest scenes (`QuestX_*.tscn`)**  
  Each quest is fully self-contained and handles:
  - Gameplay logic
  - UI
  - Success / fail conditions
  - Returning to the overworld

---

## 2. Requirements
- Godot Engine **4.5**
- Desktop platform (Windows / macOS / Linux)

---

## 3. Installation
1. Download or clone the project:
   ```bash
   git clone https://github.com/<your-username>/akhtaam-dilmun.git
Open Godot 4

Click Import

Select the folder containing project.godot

4. Running the Project
Open the project in Godot

Ensure the main scene is set to:

res://overworld.tscn
(Project → Project Settings → Application → Run → Main Scene)

Press F5 to run

5. Quest Breakdown, Success & Failure States, and Test Cases
Quest 1 — Water (Ports & Landmarks Connection)
Scene:

Quest1_Water_MapTracing.tscn

quest_1_water.tscn

Goal:
Connect Dilmun ports to the correct landmarks using water routes.

Gameplay:

The map is visible from a top-down view.

The player traces or connects paths between ports and landmarks.

Only correct connections count.

Success State
All required ports are connected to their correct landmarks

No broken or incorrect paths remain

Result panel shows “Quest Completed”

Player is returned to overworld.tscn

Fail State
Player exits without completing all required connections

OR incorrect connections remain

Result panel shows “Quest Failed” (if enabled)

Retry option reloads the quest scene

Test Cases
Connect all ports correctly → Quest completes.

Leave one port unconnected → Quest does not complete.

Connect a port to the wrong landmark → Quest does not complete.

Exit mid-quest → No completion recorded.

Retry resets all paths → Puzzle returns to initial state.

Quest 2 — Earth (Artifact Reconstruction)
Scene:

Quest2_Earth.tscn

Goal:
Reconstruct a broken artifact by placing fragments correctly.

Gameplay:

Drag-and-drop shards into their correct positions.

Success State
All shards are placed correctly

Result panel shows “Quest Completed”

Player returns to overworld

Fail State
Player exits before all shards are placed

Optional: too many incorrect attempts

Test Cases
All shards placed correctly → Success.

One shard misplaced → No completion.

Shard snaps correctly when close → Accepts placement.

Shard locked after correct placement → Cannot be moved.

Exit before completion → No progress saved.

Quest 3 — Pearls (Boat Collection)
Scene:

Quest3_Pearls.tscn

Goal:
Collect all pearls before time runs out.

Gameplay:

Player controls a boat.

Pearls are collected on collision.

A timer counts down.

Success State
All pearls collected before timer reaches zero

Result panel shows “Quest Completed”

Player returns to overworld

Fail State
Timer reaches zero with pearls remaining

Result panel shows “Quest Failed”

Retry button resets the quest

Test Cases
Collect all pearls in time → Success.

Timer ends early → Failure.

Pearl collected once only → Cannot double count.

Counter updates correctly (x / total).

Retry resets timer and pearls.

Quest 4 — Harvest (Sorting / Collection)
Scene:

Seal4_Harvest.tscn

Goal:
Correctly sort or collect harvest items.

Gameplay:

Items appear and must be placed or collected correctly.

Wrong actions reduce lives or score.

Success State
Required score reached OR all correct items processed

Result panel shows “Quest Completed”

Player returns to overworld

Fail State
Lives reach zero

Too many incorrect actions

Test Cases
Correct sorting increases score.

Incorrect sorting reduces lives.

Lives reach zero → Failure.

Reaching target score → Success.

Retry resets score, lives, and items.

Quest 5 — Unity (Logic / Pattern)
Scene:

Quest5_Unity.tscn

Goal:
Solve a logic or pattern-based puzzle representing unity.

Success State
Puzzle solved correctly

Result panel shows “Quest Completed”

Fail State
Maximum attempts reached with incorrect solution

Test Cases
Correct pattern → Success.

Incorrect pattern → No completion.

Exceed attempt limit → Failure.

Retry resets puzzle.

Replay does not double-count completion.

Quest 6 — Memory (Final Quest)
Scene:

Quest6_Memory.tscn

Goal:
Reorder the seals correctly and answer final questions.

Correct Order:
Water → Earth → Pearls → Harvest → Unity → Memory

Success State
Seals placed in correct order

Final questions meet pass requirement

Result panel shows “Quest Completed”

End of game state

Fail State
Incorrect order after max attempts

Final score below passing threshold

Test Cases
Correct order → Success.

One seal misplaced → No completion.

Failed questions → Failure.

Retry resets seals and questions.

Completion persists after returning to overworld.

6. Notes
Each quest is self-contained and handles its own logic and UI.

Scene transitions always return to overworld.tscn.

Result panels are used to clearly indicate success or failure.
