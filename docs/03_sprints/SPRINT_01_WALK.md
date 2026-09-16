# GOOD HUMAN!MVP Sprint 01 — WALK

> Godot 4.x / GDScript  
> 用途：放在 Godot 專案根目錄，供開發者、Codex、Claude 共用。

## 0. Sprint Goal

本 Sprint **不做戰鬥、不做正式美術、不做完整序章**。

唯一目標：

**Home → 出門 → 狗移動 → 搜索 → Loot → 背包 → 5 分鐘後撤離 → 結算 → Home → 再出門**

第一版必須「醜但完整」。

### Definition of Done

- Home 可開始 Run。
- 狗可用 PC 與 Mobile Input 移動。
- 可靠近 SearchPoint 並互動。
- Loot 由 LootTable 隨機抽取，不寫死在 SearchPoint。
- Loot 可進 Human Run Inventory。
- Item 可移到 Dog Safe Inventory。
- 5:00 後 Extraction A 開放；8:00 後 Extraction B 開放。
- 成功撤離後物品進 Home Stash。
- 下一局 SearchPoint 與 Loot 重置。
- Run Seed 可記錄與顯示。
- Debug Panel 可快轉時間、給 Item、解鎖撤離。
- Android 實機可完成完整流程。
- 可連續完成 3 局無阻斷 Bug。

## 1. 技術基準

- Engine：Godot 4.x
- Language：GDScript
- Game：2D
- Target：Mobile first
- Desktop Debug：WASD + E
- Mobile：Virtual Joystick + Context Interaction Button
- Save：`user://save.json`
- 正式美術：Sprint 01 不需要
- Multiplayer：不實作

### 架構原則

1. Gameplay Code 不判斷鍵盤／手機，統一讀 Input Map。
2. Item、LootTable 等內容 Data Driven。
3. RunManager 不做 Autoload；Run 是一次性 Session。
4. Game、SaveManager、DataRegistry 可做 Autoload。
5. Inventory 共用同一套實作。
6. SearchPoint 只引用 LootTable，不知道具體掉落物。
7. 不為未來功能過度設計。
8. Sprint 01 禁止加入戰鬥、技能、主人 AI、地盤與完整事件。

## 2. 專案目錄

```text
res://
├── autoload/
│   ├── game.gd
│   ├── save_manager.gd
│   └── data_registry.gd
├── core/
│   ├── run/
│   │   ├── run_manager.gd
│   │   ├── run_state.gd
│   │   └── run_result.gd
│   ├── interaction/
│   │   ├── interactable.gd
│   │   └── interaction_area.gd
│   └── inventory/
│       ├── inventory.gd
│       ├── inventory_slot.gd
│       └── item_stack.gd
├── resources/
│   ├── item_data.gd
│   ├── loot_entry.gd
│   └── loot_table_data.gd
├── data/
│   ├── items/
│   ├── loot_tables/
│   └── game_balance/
├── actors/dog/
│   ├── dog.tscn
│   └── dog_controller.gd
├── world/
│   ├── run_map/run_map_01.tscn
│   ├── search_point/search_point.tscn
│   └── extraction/extraction_point.tscn
├── ui/
│   ├── home/
│   ├── hud/
│   ├── inventory/
│   ├── interaction/
│   ├── run_result/
│   └── debug/
├── scenes/
│   ├── boot.tscn
│   └── home.tscn
└── assets/placeholder/
```

## 3. Scene Flow

```text
Boot → Home → RunMap01 → RunResult → Home
```

**Boot**：初始化 Global、Load Save、進 Home。  
**Home**：查看 Stash／狗包資訊、開始 Run。  
**RunMap01**：RunManager、Dog、Greybox Map、SearchPoint、ExtractionPoint、HUD、Debug Panel。  
**RunResult**：Run 時間、Seed、帶回物品、撤離結果、返回 Home。

## 4. Input Map

建立：

```text
move_left
move_right
move_up
move_down
interact
inventory
debug_panel
```

Desktop：W/A/S/D、E、Tab、F1。

DogController 使用：

```gdscript
var direction := Input.get_vector(
    "move_left", "move_right", "move_up", "move_down"
)
```

禁止核心移動程式直接判斷 `KEY_W` 等實體按鍵。

## 5. Dog Scene

```text
Dog (CharacterBody2D)
├── Visual (AnimatedSprite2D / Placeholder)
├── CollisionShape2D
├── InteractionDetector (Area2D)
│   └── CollisionShape2D
└── Camera2D
```

DogController 只負責 Movement、Facing、選出附近最佳 Interactable、發出 interact intent。不得負責 Run Timer、Loot Roll、Save、Stash、Extraction State。

## 6. Interactable

```gdscript
class_name Interactable
extends Node2D

@export var prompt: String = "互動"
@export var enabled: bool = true

func can_interact(context) -> bool:
    return enabled

func interact(context) -> void:
    pass
```

Sprint 01：`SearchPoint`、`ExtractionPoint`。未來可擴 TerritoryPoint、NPC、Shop、TrainingPoint、EventPoint，但本 Sprint 不實作。

## 7. ItemData

使用 Godot Resource：

```gdscript
class_name ItemData
extends Resource

enum ItemType { JUNK, FOOD, MEDICAL, TRAINING, EQUIPMENT, SPECIAL }
enum Rarity { COMMON, UNCOMMON, RARE }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var type: ItemType
@export var rarity: Rarity
@export var stackable: bool = true
@export var max_stack: int = 99
@export var value: int = 0
@export var icon: Texture2D
```

資料放 `res://data/items/*.tres`。

## 8. Sprint 01 Item List

| ID | 名稱 | 類型 | 備註 |
|---|---|---|---|
| tennis_ball | 舊網球 | JUNK | 基礎 Loot |
| dog_treat | 肉乾 | FOOD | 後續狗使用 |
| sports_drink | 運動飲料 | FOOD | 後續消耗品 |
| bandage | 繃帶 | MEDICAL | 後續住院 |
| old_running_shoes | 舊跑鞋 | EQUIPMENT | P0 只當 Loot |
| umbrella | 雨傘 | EQUIPMENT | 未來隱藏技能 |
| jump_rope | 跳繩 | TRAINING | 未來訓練 |
| hand_grip | 握力器 | TRAINING | 未來力量訓練 |
| dog_toy | 狗玩具 | JUNK | 狗相關物品 |
| old_sports_watch | 舊運動手錶 | EQUIPMENT | 稍稀有 |
| boxing_gloves | 舊拳擊手套 | EQUIPMENT | 高價值測試物 |
| mysterious_item | 神秘物品 | SPECIAL | 測試安全格需求 |

Sprint 01 不讓 Equipment 真正裝備。

## 9. Inventory

只做一套 Inventory Model，建立三個實例：

```text
HumanRunInventory = 8
DogSafeInventory = 2
HomeStash = 30
```

必要操作：`add_item`、`remove_item`、`move_item`、`swap_item`、`has_space`、`clear`、`serialize`、`deserialize`。

ItemStack Sprint 01 只需 `item_id`、`quantity`。

## 10. LootTable

Weighted Roll。資料概念：

```text
LootTableData
├── entries[]
│   ├── item
│   ├── weight
│   ├── min_quantity
│   └── max_quantity
└── nothing_weight
```

建立 `ResidentialTrash`、`ParkSearch` 兩張表。SearchPoint 只能引用 LootTable Resource，禁止依 SearchPoint 名稱寫死 Item。

## 11. SearchPoint

Export：`search_id`、`loot_table`、`search_duration`、`one_time`。

建議 `search_duration = 1.0～2.0 sec`、`one_time = true`。

流程：靠近 → 顯示「👃 聞聞看」→ Interact → Search Progress → `LootTable.roll(run_rng)` → Inventory → 顯示取得物品 → 標記 searched。同一 Run 不可重搜；下一 Run 重置。

## 12. Greybox Map

- Spawn → 公園核心：約 60～90 秒。
- 不搜索走完整張：約 2～3 分鐘。
- 至少一條主路＋一條替代路線。

```text
                [North Exit]
                     │
             ┌───────┴───────┐
             │     PARK      │
         [Tree]           [Gym]
             │               │
             └───────┬───────┘
                     │
                 Main Path
                     │
          ┌──────────┴──────────┐
       [Alley]            [Convenience]
          │                     │
          └──────────┬──────────┘
                     │
                   SPAWN
```

至少 10 個 SearchPoint：垃圾桶×3、草叢×3、長椅×2、運動區×1、特殊角落×1。

## 13. RunManager

RunMap Scene Controller，禁止 Autoload。

負責：`elapsed_time`、`run_seed`、`run_rng`、`human_run_inventory`、`dog_safe_inventory`、`searched_points`、`extraction_states`、`run_status`、`run_result`。

Lifecycle：`start_run()` → Timer/Gameplay → `extract()` 或 `fail_run()` → Build RunResult → Result Scene。

## 14. Run Seed / RNG

每局產生 `run_seed: int`，並建立：

```gdscript
var rng := RandomNumberGenerator.new()
rng.seed = run_seed
```

Sprint 01 所有 Loot Roll 優先使用 Run RNG。Result／Debug UI 顯示 Seed。

## 15. ExtractionPoint

- Extraction A：公車站，`unlock_time = 300 sec`
- Extraction B：北門，`unlock_time = 480 sec`

Timer 達標 → available → HUD 提示 → 玩家抵達互動 → `RunManager.extract()` → RunResult。

Sprint 01 只做直接撤離。

## 16. Debug Panel

必做：

```text
Current Run Time
Run Seed
[+60 sec]
[Set 04:50]
[Unlock All Extraction]
[Give Tennis Ball]
[Give Mysterious Item]
[Clear Run Inventory]
[Successful Extract]
[Fail Run]
```

Debug UI 不進正式 Release Build。

## 17. SaveManager

Autoload。Sprint 01：

```json
{
  "version": 1,
  "stash": [],
  "dog": {},
  "human": {},
  "statistics": {
    "runs": 0,
    "successful_extractions": 0
  }
}
```

要求：不存在時 Default Save；JSON 損壞不可 Crash；從第一版保留 `version`。不做 Cloud Save、加密、SQLite、帳號。

## 18. UI

### Home
顯示主人 Placeholder、Stash x/30、狗包 x/2、查看 Stash、出去散步。

### Run HUD
顯示 Run Time、Virtual Stick、Context Interaction、Inventory。靠近搜索點顯示「👃 聞聞看」。5:00 顯示「🚌 公車站現在可以撤離」。

### Inventory
主人背包 8 格；狗包安全格 2 格。Mobile 優先 Tap + 選目的格，不強制 Drag & Drop。

### Result
顯示散步時間、Seed、帶回物。成功撤離後 HumanRunInventory + DogSafeInventory → HomeStash。

## 19. Sprint Task List

| ID | Task | 驗收條件 |
|---|---|---|
| P0-001 | Project 基礎目錄 | 專案無錯誤啟動 |
| P0-002 | Game Autoload | Boot → Home 正常 |
| P0-003 | SaveManager | Save/Load/Default 正常 |
| P0-004 | DogController | WASD 可順暢移動 |
| P0-005 | Mobile Input | Virtual Joystick 控制同一 Controller |
| P0-006 | Greybox Map | Spawn 可走到公園核心 |
| P0-007 | Interactable | 可選出附近有效互動物 |
| P0-008 | ItemData | `.tres` Item 可建立 |
| P0-009 | Inventory | Add/Remove/Move/Swap 正常 |
| P0-010 | LootTable | Weighted Roll 正常 |
| P0-011 | SearchPoint | 搜索取得 Loot，同局不可重搜 |
| P0-012 | Dog Safe Slots | Item 可在主人背包與 2 安全格移動 |
| P0-013 | RunManager | Timer/Seed/Run State 正常 |
| P0-014 | ExtractionPoint | 5:00、8:00 正確解鎖 |
| P0-015 | Run Result | 正確顯示結果 |
| P0-016 | Home Stash | 撤離物資永久保存 |
| P0-017 | Second Run | SearchPoint 重置、Loot 重 Roll |
| P0-018 | Debug Panel | 快轉、給 Item、解鎖撤離 |
| P0-019 | Android Export | Android 實機完成完整流程 |
| P0-020 | Sprint Playtest | 連續 3 局無阻斷 Bug |

## 20. QA Golden Path

1. 開遊戲。
2. Boot → Home。
3. 按「出去散步」。
4. Dog 出生。
5. WASD／手機搖桿移動。
6. 搜垃圾桶。
7. 得到舊網球。
8. 搜草叢。
9. Debug 取得神秘物品。
10. 開 Inventory。
11. 神秘物品移進 Dog Safe Inventory。
12. Debug 設 04:50。
13. 等到 05:00。
14. 公車站解鎖並提示。
15. 故意不撤。
16. 前往公園。
17. 再搜索。
18. Debug／Loot 得到舊拳擊手套。
19. 返回公車站。
20. 成功撤離。
21. Result 顯示時間、Seed、物品。
22. 回 Home。
23. Stash 有三件物品。
24. 再次出門。
25. SearchPoint 重置。
26. Loot 重新 Roll。
27. 完成第二次撤離。
28. 關閉遊戲。
29. 重開。
30. Stash 仍存在。

30 步全過才算 Golden Path Pass。

## 21. Coding Rules

### 必須
- 優先 typed GDScript。
- Data 優先 Resource 化。
- Script 單一責任。
- 關鍵流程使用 Signal／明確 API，避免到處硬抓 Node Path。
- Save Data 必須 JSON-safe。
- RNG 由 RunManager 管理；SearchPoint 不自行 `randomize()`。
- Debug 功能集中管理。

### 禁止
- 不把所有系統塞進 `game.gd`。
- 不把 Inventory 寫進 DogController。
- 不把 Loot 寫死在 SearchPoint。
- 不在 P0 寫 Combat、Skill Tree、Multiplayer。
- 不投入正式 Shader／動畫／特效。
- 不因未來可能需要而建立大量抽象層。
- 不自行擴 Scope；新功能先列 Proposal。

## 22. Codex / Claude 協作規則

**Codex 優先**：GDScript、Scene/Resource、Inventory、Loot、RunManager、Save、Test Helper、Bug Fix。  
**Claude 優先**：架構 Review、Scope Review、Data Schema Review、Scene Coupling、QA、Edge Cases。

每次 AI 工作前：
1. 讀本文件。
2. 確認 Task ID。
3. 查看現有實作。
4. 不假設未完成功能存在。
5. 一次完成小範圍 Task。
6. 完成後列修改檔案。
7. 提供驗收方法。
8. 若需求衝突先提出，不自行改 Scope。

避免兩個 AI 同時大改同一核心 Script。

## 23. Out of Scope

Combat、Human AI、QTE、Human Training、Skill Tree、Territory、Hospital、Solo Dog Mode、NPC Memory、Random Events、Day/Night、Weather、寵物醫院序章、選狗、主人收養、Multiple Breeds、Park Boss、Multiplayer、PvP、Shop、Monetization、正式劇情、正式美術。

## 24. Sprint Review

完成後只問：
- 移動適不適合單手？
- SearchPoint 是否讓人想靠近？
- 搜索等待時間是否舒服？
- Loot 回饋是否足夠？
- 玩家是否理解 Dog Safe Slots？
- 5 分鐘後是否真的產生「撤不撤」？
- 是否有人自然說「我再搜一個」？
- 地圖是否適合 5～15 分鐘 Run？
- Stash 增加是否有累積感？
- 是否願意立刻再次散步？

最重要的訊號：**「我知道可以撤了，但我想再搜一個。」**

若沒有，先調 Loot 價值、SearchPoint 分布、地圖距離、撤離時機、搜索 Feedback；不要急著用戰鬥掩蓋 WALK Loop 的問題。

## 25. Sprint 01 完成後

才進 Sprint 02 — FIGHT：Enemy Dog + Human Encounter、Human Combat Stats、Auto Battle、主人技能第一批、Battle Result、Human Down、Run Failure、Loot Loss、Dog Safe Inventory 保留、第一個越級敵人。

> **Project Principle：先做出讓玩家想「再散一次」的灰盒，再做出漂亮的狗。**
