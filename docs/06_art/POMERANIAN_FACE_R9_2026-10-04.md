# 博美臉部網格修整 r9 — 2026-10-04

後續更正：主人指出「整張臉」不自然，本文件的 r9 外觀驗收結論撤回。
正在以 [r10 整臉重建候選](POMERANIAN_FACE_R10_2026-10-04.md) 處理；r10 尚未接回遊戲。

角色：Codex ART。主人本輪已允許修整臉部網格，解除 r7／r8 的「只改貼圖」限制。
已更新遊戲博美；其餘品種與玩家柴犬未改動。**REVIEW / B，非 S 級最終美術。**

## 改動與效果

- 將鼻樑上方突出的厚片收回，讓額頭到鼻樑的側面輪廓較連續。
- 縮短、抬高鼻頭，調整厚度；移除原本像兩個鼻子的外觀。
- 沿用 r8 的口鼻貼圖修正與主人參考圖的鼻孔細節；眼睛沿用 r6 風格。
  沒有新增立體眼球或切割眼窩。
- 在同位置頂點的共用鄰接關係上平滑，避免 UV 島邊界各自移動而裂開。
  實際輸出的頂點索引與拓撲不變。

## 實際模型對照

每張上排 r6、下排 r9；角度依序 −90°、−45°、正面、+45°、+90°。
僅縮放與排版，未修圖掩蓋缺陷。

- [Godot 一般材質](pomeranian_r9_2026-10-04/comparison_false.png)
- [Godot SoftToon](pomeranian_r9_2026-10-04/comparison_true.png)
- [Idle／Walk／Sit，各取 25%、50%、75%](pomeranian_r9_2026-10-04/animations.png)

這輪可以確認鼻樑的大凸塊已降低，45° 遠側眼睛的可見範圍增加，鼻頭縮短。
仍有下鼻樑的小折邊、額頭毛色平滑區與頂部接縫；不是整張臉已無缺陷。

## 驗證

- Blender 5.2：多輪實際渲染與修正，檢視正面、左右 45° 與側面。
- Godot 4.6.3 / D3D12 Forward Mobile / RTX 3070 Ti：20 張靜態對照與
  9 張動畫取樣，擷取退出 0，stderr 空白；已檢視全部組圖。
- 23 骨骼與 Idle / Walk / Sit 保留。GLB 以原檔屬性區塊修改，除 POSITION、
  NORMAL 及其 accessor bounds 之外，與 r8 的其餘 JSON／binary 不變。
  材質、圖片、UV、索引、蒙皮權重、骨架、動畫資料均保留。
- 35,562 個輸出頂點、47,169 三角形；移動 2,610 個頂點，最大位移約 5.27 cm。
  眼睛保護核心的移動頂點為 0。這是原品種網格的面數，**仍高於 8–15k 的狗角色目標**。
- 頂點／法線皆為有限值，沒有新增零面積三角形，法線長度約 1。
  沒有聲稱已完成全網格自相交檢查或最終拓撲驗收。
- 動畫取樣未見新增的臉部裂開；原有 Sit 懸浮、腿部變形仍在，未修復。
  沒有執行玩法回歸或盲測 QA。

## 交付與回復

- 遊戲模型：`assets/characters/dog/models/breeds/pomeranian.glb`。
- 相同候選：`assets/art_previews/dogs/candidates/r9/pomeranian.glb`。
- r6 備份：`build/dogs_face_r9/previous/pomeranian_r6.glb`；美術對照另保留
  `assets/art_previews/dogs/candidates/r9/pomeranian_r6.glb`，避免未來對照誤讀新版。
- SHA-256：`1879395e9919486e807212add6a286c4093bc56386e557d92aa2c8eb2ae5b140`。
- 編號 Blender 檔：工作室 `blender/dog/pomeranian_r9/` 的
  `pomeranian_r9_00_backup.blend` 與 `pomeranian_r9_01_shape.blend`。
- 工具：`reshape_pomeranian_r9.py`、`render_pomeranian_r9.py`、
  `capture_pomeranian_r9.gd`、`verify_pomeranian_r9.ps1`、`contact_pomeranian_r9.py`。
  原始產物與截圖在 `build/dogs_face_r9/`。

Factory 的 `_game.glb`／`_game_codex.glb` 未覆寫，故 factory 仍是舊版；
重新跑 factory 不應直接覆蓋遊戲中的 r9。來源與既有授權链不變，沒有新第三方素材。

## 後續品質欠項

耳背／鬃毛破碎表面、舌頭與下顎接縫、額頭與臉頰貼圖、Sit 動作及面數預算
仍需處理。本次只交付博美的鼻樑與鼻頭修整，不能當作所有狗狗已達最終品質。
