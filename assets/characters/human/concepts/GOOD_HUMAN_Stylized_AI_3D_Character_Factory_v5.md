# GOOD HUMAN! Stylized AI 3D Character Factory v5

## Claude Code / Opus × Qwen × ComfyUI × Modly × Blender × Godot

> v5 取代 v4 作為目前角色製作主流程。第一個測試角色為老奶奶。
> 核心目標不是把 AI 模型修得更寫實，而是建立可批量產出「同一個 GOOD
> HUMAN! 動畫遊戲世界」角色的流程。 若 Grandma Geometry
> 已存在，先判斷能否 Stylize；不要一開始就重跑 Image-to-3D。

## 1. Agent 執行原則

不要只提出建議。實際執行：

`inspect → analyze → backup → process → render → compare → repair → export → report`

只有需要帳號/Token、付費、授權不清、destructive system
change、硬體無法執行、或真正的美術方向決策時才詢問使用者。

## 2. Production Flow

`STYLE BIBLE → Character Sheet → Stylized Reference → Stylized Multi-view → Stylized Geometry → Retopology → UV → Stylized Texture → Soft Toon Material → LOD → Animation → Godot → Style/Performance/License QA`

所有角色必須像來自同一款 GOOD
HUMAN!，而不是每個角色各自漂亮但像不同遊戲。

## 3. Existing Grandma First

先 Backup，再做 Geometry Analysis、Texture Analysis、Stylization
Feasibility。

-   Geometry 可用且能風格化：KEEP → Stylize Geometry → Rebuild Texture。
-   Geometry 可用但太寫實：先做 controlled proportion/silhouette
    stylization。
-   Geometry 根本不相容：Stylized References → Regenerate Geometry。
-   只有 Texture 壞：KEEP GEOMETRY → Rebuild Stylized Texture。

**Texture 醜不能直接觸發重新建模。**

## 4. Workspace

``` text
good_human_stylized_factory/
├─ input/
├─ style_bible/
├─ references/{original,stylized,approved}/
├─ source_master/
├─ modly_output/
├─ blender_work/
├─ texture_work/{source,projection,generated,repair,approved}/
├─ materials/
├─ renders/{baseline,stylized,texture_qa,lod_qa}/
├─ lod/
├─ export/
├─ godot_test/
├─ scripts/
├─ reports/
├─ licenses/
└─ logs/
```

永遠保留 Source Master。

## 5. GOOD HUMAN! Style Bible v1

目標：Stylized 3D、animation-game character、strong readable
silhouette、clean color blocks、soft shapes、slight exaggeration、warm
personality、humorous contrast。

避免：photorealistic、scan-like、hyperreal skin、pores、uncanny
human、extreme anime、chibi、toy-like
plastic、直接模仿特定動畫公司的既有角色風格。

### Human baseline

-   約 5.5--6 heads tall。
-   Head：真人 baseline × 1.15--1.25。
-   Hands：× 1.05--1.15。
-   Feet：× 1.05--1.10。
-   Eyes：略放大，不做典型 anime 大眼。
-   Nose / mouth / jaw / face planes：簡化。
-   Body：silhouette-first。

比例只是第一輪測試值，最終由 Render QA 調整。

### Age stylization

老人仍必須看得出年齡。保留 gray/white hair、facial sag、nasolabial
suggestion、eye-area age、posture、body language；減少 tiny
wrinkles、pores、micro skin noise、photographic spots。

目標是 OLD，不是 PHOTOREAL OLD SKIN。

## 6. Grandma Direction

平常：frail、gentle、slightly hunched、slow、ordinary、harmless、easy to
underestimate。

禁止 fighter grandma、martial artist、cool sunglasses、muscular、hero
pose、combat costume。

戰鬥力放在 Animation、Timing、Camera、VFX、Sound。

Grandma shape language 第一版：

-   head slightly oversized
-   glasses slightly oversized / readable
-   hair bun simplified into a strong shape
-   narrow shoulders
-   compact torso
-   mild hunch
-   slightly oversized hands and shoes
-   clothing uses large readable forms
-   floral pattern uses large simplified graphic motifs，不做大量 AI
    小碎花

## 7. Dog Direction

同一 Style Bible 必須套用狗。Shiba 第一版：Head ×1.20、simplified
muzzle、slightly larger eyes、emphasized ears、compact body、slightly
shorter legs、larger paws、emphasized tail curl。

毛髮使用 major silhouette + large fur groups + painted color
regions，避免大量 realtime individual fur。

## 8. Environment / Inventory / Baseline

檢查 OS、CPU/RAM、GPU/VRAM、Python、Git、Node、Claude
Code、Blender、Godot、ComfyUI/Qwen、Modly，輸出
`reports/environment.md`。

搜尋 Grandma 的
`.blend/.glb/.gltf/.fbx/.obj`、textures、references、character
sheet，輸出 `reports/grandma_inventory.md`。

任何修改前，在 Blender 建立固定
Camera/Lighting/Background/Pose/Exposure，Render
Front、Back、Left、Right、3/4 Left、3/4 Right、Face Close-up 至
`renders/baseline/`。

## 9. Stylization Feasibility Gate

Opus 分析 head proportion、face
shape、eyes、nose、jaw、hands、feet、torso、limbs、posture、silhouette、clothing、hair。

輸出 `reports/stylization_feasibility.md`：

`STYLIZE_EXISTING / STYLIZE_WITH_MAJOR_EDIT / REGENERATE_STYLIZED_GEOMETRY`

若 STYLIZE_EXISTING，優先使用 Blender shape keys、proportional
editing、lattice、sculpt、controlled scaling，保持 identity/age/clothing
identity。

若 STYLIZE_WITH_MAJOR_EDIT，先複製 source/work 檔。三輪 Render QA 仍
uncanny、too realistic、bad proportions 或 broken face，才 REGENERATE。

## 10. Stylized Reference Generation

需要重建時，不要拿原始偏真人 Reference 直接進 Modly。

`Original Character Sheet → Qwen Stylization → Stylized Character Sheet`

要求 same
character/age/clothing/hairstyle/glasses/identity/personality，符合
Style Bible、clean large shapes、simplified surface detail、slightly
exaggerated proportions。

禁止 young、fashion-model beautification、fighter、anime
girl、photorealistic、hyperreal、chibi。

生成：

``` text
grandma_stylized_front.png
grandma_stylized_side.png
grandma_stylized_back.png
grandma_stylized_34.png
```

Neutral A-pose；四張必須保持 identity/proportion/clothing/pattern
language/age/hair/glasses。

Opus QA：PASS/RETRY/REJECT，最多自動 retry 3 次。

## 11. License Gate

Input、Qwen model、checkpoint、LoRA、custom node、Modly、3D
generator、weights、extensions、textures 分開檢查。以執行當下官方
License/Model Card 為準。

狀態 PASS / CONDITIONAL / BLOCK。UNKNOWN 不得自動進 Production。

## 12. Stylized Image-to-3D

只有需要重建 Geometry 才執行。主要輸入
`grandma_stylized_34.png`；Front/Side/Back 作 QA/correction。Modly
控制優先 CLI \> MCP \> GUI。所有原始結果保存 `source_master/`。

Geometry QA 不只問像不像人，而是「像不像 GOOD HUMAN!」。檢查
silhouette、head/body ratio、face
simplification、eyes、nose、jaw、hands、feet、hair mass、clothing
mass、posture。

建立 `reports/style_match.md`，比較 Style Bible、Stylized Reference、3D
Render，結果 PASS / NEEDS_STYLIZATION / REGENERATE。

## 13. Retopology / UV

Animated character：`High-poly → Retopology → Low-poly`。

初始 Budget：

-   LOD0 25K--40K
-   LOD1 12K--20K
-   LOD2 5K--8K
-   LOD3 1.5K--3K

保護 face silhouette、eyes region、hands、hair
silhouette、shoulders、elbows、knees、overall silhouette。

重新建立 Low-poly UV；檢查 stretch、overlap、padding、texel
density、face allocation、visible seams。不要直接沿用不相容的 AI UV。

## 14. Stylized Texture Philosophy

不要 `Photographic Texture Projection → preserve every detail`。

改成：

`Reference → Semantic Color/Material Extraction → Stylized Reconstruction → Clean Texture Atlas`

從 Character Sheet 分析 SKIN / HAIR / GLASSES / UPPER_CLOTHING / PATTERN
/ LOWER_CLOTHING / SHOES / BAG。實際色彩從 Approved Reference 擷取。

BaseColor：clean、large color regions、low
noise、readable、consistent。移除 photo noise、pores、random
stains、micro detail、AI paint artifacts。

花衣建立 simplified floral
motif：large、readable、repeatable、consistent。避免 random
symbols、melting flowers、front/back 不同視覺語言。

Face 保留 age、skin tone、eye shape、eyebrows、mouth、subtle age
lines；移除 pores、micro wrinkles、photo lighting baked into
texture、random pigmentation noise。

## 15. Normal Map Policy

保留 major cloth folds、seams、shoe structure、hair large
forms、important facial forms。

降低 pores、tiny wrinkles、fabric fibers、micro noise。Normal 強度要服從
Stylized Art Direction。

## 16. Texture Reconstruction / QA

可使用 approved references、Qwen、projection、procedural
masks、bake，但目標是 clean stylized material，不是 photographic
projection。

至少分 FACE / HAIR / SKIN / UPPER / LOWER / SHOES / BAG，避免
hair→face、skin→sleeve、floral→hand、pants→shoe。

每個 Texture Candidate 必須套回 3D，Render Front/Back/Left/Right/3/4
Left/3/4 Right/Face Close-up。禁止只看 UV PNG。

Opus 比較 Stylized Reference vs 3D Render，檢查 identity、age、color
blocks、face、hair、glasses、pattern、seams、noise、random paint。

結果 PASS / REPAIR / REBUILD，最多自動 repair 3 次。

## 17. Soft Toon Material

Godot 目標為 Stylized PBR / Soft Toon，而不是 Realistic
PBR，也先不要極硬的二段 anime cel shading。

方向：clean diffuse、soft shadow bands、controlled specular、low skin
gloss、low micro-normal、clear color blocks、soft transitions。

避免 oily skin、hyperreal reflections、strong pore normal、metal-like
clothing。

## 18. Cross-character Style QA

每新增角色，都用 same camera / lighting / background / framing
Render，與 Grandma、Muscle Man、Young Owner、Dog 並排。

檢查 head scale、eye language、hand/foot exaggeration、surface
detail、texture noise、material response、color saturation、shader。

如果單獨漂亮但 too realistic / too anime / too toy-like / too detailed /
too noisy，相對其他角色不一致，判定 STYLE FAIL。

## 19. Texture / Material / LOD Budget

預設 Body BaseColor 2048、Normal 2048、ORM 2048。Face 僅需要時獨立
1024/2048。Materials target \<=3。

LOD0/1/2/3 每級都做 Geometry QA + Texture QA + Style QA，不只比較
triangle count。

## 20. Godot / Collision / Performance

使用 glTF 2.0/GLB，在獨立 `godot_test/` 驗證
scale、orientation、materials、Soft
Toon、textures、skeleton、animation、shadow、LOD、collision、performance。

角色 collision 優先 CapsuleShape3D，不使用 High-poly Mesh Collision。

初始 Performance Gate：LOD0 \<=40K tris、Materials
\<=3、BaseColor/Normal/ORM \<=2048；GLB 約 \<20--30MB
作工程目標而非絕對限制。

## 21. Grandma Animation

平常：Idle_Frail / Walk_Slow / Pet_Dog / Sit_Bench。

爆發：Threatened / Pause / Eyes_Change / Posture_Straighten / Counter /
Umbrella_Strike / Launch_Enemy。

恢復：Return_To_Frail / Walk_Away。

節奏：慢 → 慢 → 停 → 瞬間爆發 → 壯漢飛出去 → 恢復駝背 → 繼續散步。

## 22. Automation Scripts

優先建立：

``` text
scripts/analyze_asset.py
scripts/render_baseline.py
scripts/stylize_geometry.py
scripts/setup_reference_cameras.py
scripts/bake_maps.py
scripts/build_stylized_texture.py
scripts/render_style_qa.py
scripts/render_texture_qa.py
scripts/generate_lods.py
scripts/export_gltf.py
```

能腳本化就不要反覆依賴 GUI。

## 23. Per-Asset Package

``` text
assets/grandma/
├─ grandma_game.glb
├─ SOURCE.md
├─ LICENSE_AUDIT.md
├─ STYLE_QA.md
├─ TEXTURE_QA.md
├─ GENERATION_METADATA.json
└─ PERFORMANCE.md
```

## 24. 禁止捷徑

-   Texture 醜 → 直接重抽 Geometry
-   直接套 Toon Shader 就宣稱 Stylized
-   真人 Reference → Image-to-3D → 期待最後自然變動畫風
-   Photoreal Texture + Toon Shader
-   Photoreal micro Normal + Toon Shader
-   只把頭放大就叫 Stylized
-   只看正面或 UV PNG
-   每角色使用不同 Shader/Style
-   忽略狗與人的 Style consistency

## 25. Grandma 第一輪實驗：現在直接執行

``` text
1 Backup Existing Grandma
2 Inventory
3 Baseline Render
4 Geometry QA
5 Texture QA
6 Stylization Feasibility
7 建立/固化 GOOD HUMAN! Style Bible v1
8 嘗試 Stylize Existing Geometry
9 Render Stylized Candidate
10 Opus Style QA
```

如果 PASS：

``` text
11 Retopology
12 UV
13 Stylized Texture Reconstruction
14 Soft Normal Bake
15 Soft Toon Material
16 Texture QA
17 LOD
18 Godot Test
19 Performance QA
20 License Audit
```

如果 FAIL：

``` text
11 Qwen Stylized Character Sheet
12 Stylized Multi-view
13 Style QA
14 Modly Image-to-3D
15 Geometry Style QA
16 Retopology
17 Stylized Texture
18 Soft Toon
19 Godot
```

## 26. 第一輪輸出比較

先用 Grandma 驗證，不要一開始批量生產。

輸出 `reports/grandma_style_comparison.md`，至少包含 Before/After
Front、Before/After 3/4、Before/After Face，並回答：

-   What changed?
-   Why?
-   What remains too realistic?
-   What became too cartoonish?
-   What should Style Bible v2 change?

第一輪成功標準不是「模型完成」，而是使用者能清楚判斷：「對，這個方向才像
GOOD HUMAN!。」

## 27. Final Principle

Modly / Image-to-3D 定位為：

`Geometry Starting Point + Texture Reference`

而不是 Final Game Character Generator。

不要問「這個 3D 老奶奶夠不夠真？」

要問：

**「她是不是一眼就像 GOOD HUMAN! 世界裡的老奶奶？」**

不要讓 AI 決定遊戲美術風格。

**Style Bible 決定風格；AI 只是生產工具。**
