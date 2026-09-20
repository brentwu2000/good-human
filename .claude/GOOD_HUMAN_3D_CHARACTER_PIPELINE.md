# GOOD HUMAN! 3D Character AI Pipeline

## 1. 目標

建立一套本機 AI 輔助的遊戲角色生產流程，用於 GOOD HUMAN! 以及其他 Godot 專案。

主要角色類型：

- 日常人物
- 狗
- 貓
- 未來其他四足動物

主要輸入：

- Front
- Left
- Back
- Right

四張角色正交視圖。

最終輸出：

```text
Reference Images
        ↓
Hunyuan3D Multi-View
        ↓
Raw 3D Mesh
        ↓
Blender
        ↓
AI Agent / MCP
        ↓
Mesh Cleanup
Retopology
UV / Texture
Rig
Weight
Animation Validation
LOD
        ↓
GLB
        ↓
Godot 4
```

第一階段的目標不是做到完全無人工介入。

第一階段成功標準：

> 能從一組人物或狗的四視圖開始，產生 3D Mesh，進入 Blender，由 Claude/Codex 控制 Blender 做處理，建立 Rig，測試動畫，最後輸出 Godot 可讀取的 GLB。

---

# 2. PoC 角色

第一階段只測兩種：

## Human

老太太角色。

用途：

- 驗證 Humanoid
- 衣服
- 頭髮
- 人體比例
- Humanoid Rig
- Walk / Idle

## Dog

柴犬角色。

用途：

- 驗證 Quadruped
- 四足 Mesh
- Tail
- Ear
- Quadruped Rig
- Walk / Run / Sit

暫時不要加入：

- 貓
- 大量 NPC
- 表情系統
- 毛髮模擬
- Cloth Simulation
- 高階 PBR
- 完整動畫庫

等 PoC 成功再增加。

---

# 3. 建議目錄

請 Claude 建立：

```text
good-human-3d-pipeline/
│
├─ README.md
│
├─ docs/
│   ├─ INSTALL.md
│   ├─ PIPELINE.md
│   ├─ HUMAN.md
│   ├─ DOG.md
│   └─ GODOT_EXPORT.md
│
├─ tools/
│   ├─ hunyuan3d/
│   ├─ blender-mcp/
│   └─ scripts/
│
├─ references/
│   ├─ human/
│   │   └─ grandma_01/
│   │       ├─ front.png
│   │       ├─ left.png
│   │       ├─ back.png
│   │       └─ right.png
│   │
│   └─ dog/
│       └─ shiba_01/
│           ├─ front.png
│           ├─ left.png
│           ├─ back.png
│           └─ right.png
│
├─ generated/
│   ├─ raw/
│   ├─ processed/
│   └─ textures/
│
├─ blender/
│   ├─ human/
│   ├─ dog/
│   └─ templates/
│
└─ export/
    └─ godot/
```

不要把大型 AI Model commit 到 Git。

---

# 4. 基礎環境檢查

Claude 第一件事不是安裝。

先檢查：

```bash
nvidia-smi
python --version
git --version
blender --version
uv --version
```

記錄：

```text
OS:
GPU:
VRAM:
CUDA:
Python:
Blender:
Git:
uv:
```

如果沒有 `uv`，再安裝。

如果沒有 Blender，先安裝 Blender。

不要在不知道 GPU / CUDA 狀態的情況下直接安裝 PyTorch。

---

# 5. Hunyuan3D

主要使用：

```text
Tencent Hunyuan3D-2mv
```

目的：

```text
Front
Left
Back
Right
    ↓
Multi-view Conditioning
    ↓
3D Shape
```

Repository：

```text
https://github.com/Tencent-Hunyuan/Hunyuan3D-2
```

Claude 應：

```bash
cd tools
git clone https://github.com/Tencent-Hunyuan/Hunyuan3D-2.git hunyuan3d
```

接下來：

1. 閱讀官方 README。
2. 依目前 OS / CUDA / GPU 安裝 dependencies。
3. 不要盲目照抄舊版 CUDA 指令。
4. 優先使用獨立 Python environment。
5. 驗證 PyTorch CUDA。
6. 再下載模型。

---

# 6. 模型

第一選擇：

```text
tencent/Hunyuan3D-2mv
```

subfolder：

```text
hunyuan3d-dit-v2-mv
```

可先測 Turbo：

```text
hunyuan3d-dit-v2-mv-turbo
```

官方 Gradio 啟動方式目前為：

```bash
python3 gradio_app.py \
  --model_path tencent/Hunyuan3D-2mv \
  --subfolder hunyuan3d-dit-v2-mv \
  --texgen_model_path tencent/Hunyuan3D-2 \
  --low_vram_mode
```

Turbo 可研究：

```bash
python3 gradio_app.py \
  --model_path tencent/Hunyuan3D-2mv \
  --subfolder hunyuan3d-dit-v2-mv-turbo \
  --texgen_model_path tencent/Hunyuan3D-2 \
  --low_vram_mode \
  --enable_flashvdm
```

第一階段：

> Geometry 成功優先於 Texture。

如果 texture generation 導致 VRAM 不足：

先關閉 texture。

不要因為 Texture 卡住整個 PoC。

---

# 7. Hunyuan 驗證

Claude 必須實際確認：

```text
[ ] Model 正常下載
[ ] CUDA 正常
[ ] Gradio 正常啟動
[ ] 可以生成 Mesh
[ ] 可以輸出 GLB/OBJ
[ ] Multi-view 可以讀取不同方向圖片
```

建立：

```text
docs/HUNYUAN_TEST.md
```

記錄：

```text
GPU:
Peak VRAM:
Generation Time:
Input Resolution:
Output Polygon Count:
Output Format:
Problems:
```

---

# 8. Reference Image 規範

四張圖片：

```text
front.png
left.png
back.png
right.png
```

必須：

- 同一角色
- 同一服裝
- 同一比例
- 同一姿勢
- 同一高度
- 同一 Camera Height
- 背景乾淨
- Orthographic / 弱透視
- 手腳不要互相遮擋

人物建議：

```text
A Pose
```

或：

```text
Relaxed T Pose
```

狗／貓：

```text
Neutral standing pose
```

禁止：

- Front 坐著，Side 站著
- 每張衣服不同
- 頭部角度不同
- 透視誇張
- Front/Back 比例不同
- 尾巴位置每張不同

---

# 9. Blender

安裝目前穩定版本 Blender。

用途：

```text
Raw AI Mesh
     ↓
Cleanup
     ↓
Retopo
     ↓
Rig
     ↓
Weight
     ↓
Animation
     ↓
LOD
     ↓
GLB
```

---

# 10. Blender MCP

PoC 優先測：

```text
webita/blender-codex-mcp
```

Repository：

```text
https://github.com/webita/blender-codex-mcp
```

Clone：

```bash
cd tools
git clone https://github.com/webita/blender-codex-mcp.git blender-mcp
```

此 MCP 提供：

```text
Scene inspection
Object inspection
Viewport screenshot
Blender Python execution
GLB export
```

最重要的是：

```text
get_viewport_screenshot
```

Claude/Codex 必須能：

```text
修改 Blender
     ↓
Screenshot
     ↓
分析結果
     ↓
再修改
```

而不是一次產生大量 Blender Python 後直接宣稱完成。

---

# 11. Blender Addon

安裝：

```text
tools/blender-mcp/addon.py
```

Blender：

```text
Edit
→ Preferences
→ Add-ons
→ Install
```

選：

```text
addon.py
```

啟用：

```text
Blender Codex MCP
```

開啟：

```text
3D Viewport
→ N
→ BlenderCodexMCP
```

預設：

```text
localhost:9876
```

---

# 12. Claude Code MCP

Claude Code 與 Codex 的 MCP 設定方式可能不同。

本文件不強制 Claude 使用 Codex-specific config。

Claude 必須：

1. 確認目前 Claude Code 版本。
2. 查詢目前 MCP config 方法。
3. 將 blender MCP server 加入 Claude Code。
4. 不要覆寫現有 MCP。
5. 保留既有 MCP servers。

成功後測試：

```text
Inspect the current Blender scene.
```

接著：

```text
Take a viewport screenshot.
```

只有兩個都成功，才算 Blender Agent 安裝完成。

---

# 13. Godot 專用 MCP

第二階段可以另外測：

```text
ricky-yosh/blender-mcp
```

用途是：

```text
Blender
→ Godot GLB
```

提供：

```text
Rig
Animation
Godot metadata
GLTF / GLB export
Custom properties
```

但是第一階段不要同時啟動兩套 Blender MCP。

原因：

```text
MCP A
   ↘
    Blender
   ↗
MCP B
```

容易增加除錯複雜度。

先讓：

```text
Claude
 ↓
Blender Codex MCP
 ↓
Blender
```

跑通。

再決定是否加入 Godot-specific MCP。

---

# 14. Blender AI 工作原則

Claude 不允許直接：

```text
Generate everything
→ Export
→ Done
```

必須採：

```text
Inspect
 ↓
Change
 ↓
Screenshot
 ↓
Evaluate
 ↓
Change
 ↓
Screenshot
```

所有大型修改前：

```text
Save .blend
```

建立 milestones：

```text
shiba_01_00_import.blend
shiba_01_01_cleanup.blend
shiba_01_02_retopo.blend
shiba_01_03_rig.blend
shiba_01_04_weight.blend
shiba_01_05_animation.blend
shiba_01_final.blend
```

---

# 15. Dog Asset Specification

柴犬 PoC：

Target：

```text
Stylized game character
```

Triangle：

```text
8,000 – 15,000
```

Texture：

```text
1024 × 1024
```

必要結構：

```text
Head
Body
4 Legs
4 Paws
Tail
2 Ears
```

避免：

```text
Non-manifold
Internal geometry
Duplicate vertices
Floating geometry
Broken normals
Extreme thin triangles
```

---

# 16. Quadruped Rig

建立：

```text
ROOT
└─ pelvis
   ├─ spine_01
   │  ├─ spine_02
   │  │  ├─ neck
   │  │  │  └─ head
   │  │  │     ├─ ear_L
   │  │  │     └─ ear_R
   │  │
   │  ├─ front_leg_L
   │  └─ front_leg_R
   │
   ├─ rear_leg_L
   ├─ rear_leg_R
   │
   └─ tail_01
      └─ tail_02
         └─ tail_03
```

實際骨架允許 Claude 根據模型調整。

但命名要穩定。

---

# 17. Dog Deformation Test

必測：

```text
Idle
Walk
Run
Sit
Lie Down
Head Turn
Tail Wag
```

PoC 最低要求：

```text
Idle
Walk
Sit
```

觀察：

```text
Shoulder
Hip
Knee
Paw
Neck
Tail Base
```

不能出現明顯：

- Mesh collapse
- 腿穿進身體
- 肩膀破裂
- 尾巴根部爆開

---

# 18. Human Specification

老太太：

Triangle：

```text
10,000 – 20,000
```

Texture：

```text
1024
```

先不處理：

```text
Individual fingers animation
Facial blend shapes
Hair physics
Cloth simulation
```

PoC 只需要：

```text
Idle
Walk
```

---

# 19. Retopology 原則

AI Mesh 不等於 Game Ready Mesh。

Claude 必須檢查：

```text
Polygon Count
Non-manifold
Normals
UV
Intersections
Topology around joints
```

尤其：

```text
Human:
Shoulder
Elbow
Hip
Knee

Dog:
Shoulder
Front Knee
Hip
Rear Knee
Tail
Neck
```

不要只使用：

```text
Decimate
```

就宣稱完成 Retopology。

---

# 20. LOD

PoC 成功後建立：

```text
LOD0
LOD1
LOD2
```

建議：

```text
LOD0 = 100%
LOD1 ≈ 50%
LOD2 ≈ 20–25%
```

第一階段可以暫時不做 LOD。

---

# 21. Godot Export

主要格式：

```text
GLB
```

Export 前：

```text
Apply Transform
Check Scale
Check Origin
Check Armature
Check Animation
Check Material
Check Texture
```

Godot 角色高度要合理。

人物約：

```text
1.5 – 1.9 m
```

柴犬：

依遊戲比例調整，但整個專案必須一致。

---

# 22. Godot 目錄

建議：

```text
res://assets/characters/
│
├─ humans/
│   └─ grandma_01/
│       ├─ grandma_01.glb
│       └─ grandma_01.tscn
│
└─ animals/
    └─ dogs/
        └─ shiba_01/
            ├─ shiba_01.glb
            └─ shiba_01.tscn
```

---

# 23. 第一階段任務

Claude 現在執行：

## Phase 0

環境檢查。

不要安裝任何大型模型。

輸出：

```text
docs/ENVIRONMENT.md
```

---

## Phase 1

安裝：

```text
Hunyuan3D-2
```

驗證：

```text
Single image → Mesh
```

成功才繼續。

---

## Phase 2

驗證：

```text
Multi-view → Mesh
```

使用：

```text
front
left
back
right
```

---

## Phase 3

安裝：

```text
Blender MCP
```

驗證：

```text
Claude → Blender
```

必須成功：

```text
Scene inspection
Viewport screenshot
Create primitive
Modify primitive
```

---

## Phase 4

Hunyuan：

```text
Shiba references
 ↓
raw_shiba.glb
```

---

## Phase 5

Blender：

```text
Import
 ↓
Cleanup
 ↓
Retopo
 ↓
Rig
```

---

## Phase 6

建立：

```text
Idle
Walk
Sit
```

---

## Phase 7

Export：

```text
shiba_01.glb
```

---

## Phase 8

Godot Import Test。

確認：

```text
Mesh
Material
Skeleton
Animation
Scale
```

---

# 24. 禁止事項

Claude 不要：

- 一次安裝所有候選工具。
- 同時安裝三四套 Image-to-3D。
- 同時啟動多個 Blender MCP。
- 自動修改 Godot 主專案重要設定。
- 刪除既有模型。
- 覆寫使用者 Blender preferences。
- 在沒有備份時執行 destructive mesh operations。
- 自稱某階段成功但沒有實際驗證。

---

# 25. 安裝策略

遵循：

```text
Install
 ↓
Verify
 ↓
Document
 ↓
Next
```

不要：

```text
Install Everything
 ↓
Hope It Works
```

每完成一階段更新：

```text
docs/INSTALL_STATUS.md
```

格式：

```text
# Install Status

## Environment
PASS / FAIL

## Hunyuan3D
PASS / FAIL

## Hunyuan Multi-view
PASS / FAIL

## Blender
PASS / FAIL

## Blender MCP
PASS / FAIL

## Claude → Blender
PASS / FAIL

## Shiba Generation
NOT STARTED

## Rig
NOT STARTED

## Godot Export
NOT STARTED
```

---

# 26. PoC 成功條件

只有下面整條成立：

```text
4-view images
      ↓
AI Mesh
      ↓
Blender
      ↓
Cleanup
      ↓
Rig
      ↓
Walk
      ↓
GLB
      ↓
Godot
      ↓
Animation Playing
```

才算 PoC 成功。

「AI 成功生成漂亮的狗」不算成功。

---

# 27. PoC 完成後

第二階段才研究：

```text
Concept Art
 ↓
AI Generate Turnaround
 ↓
Hunyuan Multi-view
 ↓
Automatic Retopo
 ↓
Shared Quadruped Rig
 ↓
Shared Animation Library
 ↓
Automatic Godot Import
```

最終目標：

```text
GOOD HUMAN Character Factory
```

使用方式：

```text
Input:
shiba_reference.png

Command:
Create a GOOD HUMAN dog character.

Output:
res://assets/characters/animals/dogs/shiba_02/
```

未來同樣建立：

```text
Human Skill
Dog Skill
Cat Skill
```

讓 Claude/Codex 不需要每次重新學習角色製作規格。

---

# 28. Claude 現在開始執行

讀完本文件後：

**先不要直接安裝所有工具。**

請依序：

1. 檢查本機硬體與既有軟體。
2. 建立 `docs/ENVIRONMENT.md`。
3. 判斷 Hunyuan3D 是否適合目前 GPU。
4. 提出你準備使用的 Python/CUDA environment。
5. 安裝 Hunyuan3D。
6. 實際跑一次 generation。
7. 成功後才安裝 Blender MCP。
8. 驗證 Claude 可以控制 Blender 並取得 viewport screenshot。
9. 更新 `INSTALL_STATUS.md`。
10. 停在這裡回報結果。

第一輪不要開始製作最終角色。

第一輪的完成條件只有：

```text
Hunyuan3D = WORKING
Blender = WORKING
Claude → Blender MCP = WORKING
Viewport Screenshot = WORKING
```

確認基礎環境全部通過後，再開始柴犬 PoC。
