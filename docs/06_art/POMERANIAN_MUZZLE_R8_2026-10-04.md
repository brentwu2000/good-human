# 博美口鼻 r8 候選 — 2026-10-04

後續：主人已回覆「ok」，允許修整臉部網格。r9 已完成本輪鼻樑／鼻頭修整並
接回遊戲；見 [r9 紀錄](POMERANIAN_FACE_R9_2026-10-04.md)。下文為 r8 當時的評估。

Codex ART 局部打磨，非盲測 QA。**IN_PROGRESS / B；不替換遊戲中的 r6。**

## 本輪結果

從 r6 開始，清除鼻樑上的重複黑色鼻子投影與白色斷帶，重新建立跨 UV 島的
奶油色口鼻與深色鼻頭，最後把主人原博美正面參考中的鼻孔細節投回鼻頭。
保留眼睛造型。未使用新的外部素材；沿用原品種模型的授權限制。

候選：`assets/art_previews/dogs/candidates/r8/pomeranian.glb`。
此資料夾在美術預覽區，沒有修改遊戲模型或 factory 原檔。

## 實際評估

黑斑與投影切線減少，但結果**仍未通過外觀驗收**：

- 鼻樑中央有異常凸塊，上方表面遮住遠側眼睛。
- 鼻頭本身的幾何被拉長，深色連續包覆後更加明顯。
- 清除區的毛髮細節較平，口鼻邊緣仍有淺色接線。
- 原有嘴部、舌頭接縫、臉部凹凸與動作缺陷未解決。

因此沒有以局部去接縫宣稱整張臉修好。需要修整臉部網格，而先前 r7 擱置
紀錄保留「只换貼圖」限制；已詢問主人這次是否放行網格修整。

## 驗證與重現

- Blender 5.2 實際渲染並檢視正面與左右 45°；比較圖為實際模型畫面。
- 包裝檢查通過：2,442,464 bytes；23 joints，Idle / Walk / Sit。
  所有非圖片 bufferView 與 mesh / UV / skin / 動畫 JSON 與 factory 原檔一致。
- 第一輪 Godot 4.6.3 D3D12 Forward Mobile：12 張截圖，兩版本 × 三角度 ×
  一般／SoftToon；程序退出 0，stderr 空白。檢視一般材質三角度對照。
  鼻孔細節追加後已重新擷取，退出 0、stderr 空白，並檢視全部 12 張組圖。
  [最終對照：r6／r8 一般材質、r6／r8 SoftToon](pomeranian_r8_2026-10-04/comparison.png)。
- 匯入成功；專案另有 `run_hud.gd` 的 `_shown_owner_stage` 未宣告錯誤，
  不影響本次獨立美術擷取，未修改該玩法／UI 檔案。
- 沒有重新驗收動畫變形，也没有跑玩法測試。

重現工具：`tools/art/polish_pomeranian_muzzle_r8.py`（在已載入博美的 Blender 執行），
`package_breed_dog_textures.py`，`capture_pomeranian_r8.gd`。
原始輸出及紀錄：`build/dogs_muzzle_r8/`。
Blender 備份：`%TEMP%/pomeranian_r8_before.blend`、
`%TEMP%/pomeranian_r8_muzzle.blend`（暫存工作檔，未寫進遊戲倉庫）。
