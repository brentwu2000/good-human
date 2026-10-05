# 博美整張前臉重建候選 r10 — 2026-10-04

Codex ART。主人指出 r9「整張臉」不自然，**r9 的外觀驗收結論撤回**。
本輪不再以鼻頭局部位移作為修復方案，從原 r6 網格重建連續前臉。
**主人已認可 r10，並明確要求套入遊戲。2026-10-04 已替換遊戲中的 r9；
此為獲准使用的 B 級迭代版本，並非 S 級最終品質。Factory 原檔仍保留。**

## 本次實際改動

- 移除前臉 6,126 個舊三角形，重新建立額頭、雙頰、雙側口鼻墊、鼻頭、口腔
  凹面與舌頭表面。這不是只換貼圖，也不是在臉上再加圓球眼睛。
- 將原本會在平面投影上回折的邊界重新排列，與保留的頭部外緣銜接；鄰近六圈
  網格做位移過渡。原有耳朵、後腦、身體仍沿用原模型，接縫鄰近區域有調整。
- 五官改用主人原博美正面設定圖作同一套表面投影；眼睛也改回該設定圖的眼形，
  並非宣稱 r6 的眼睛像素或位置未改。前臉獨立 1024² 貼圖，外緣混合舊毛色。
- 新面中央綁定既有 head 骨骼，外圈逐步混合原邊界蒙皮權重。

## 真實 Godot 畫面

上排為主人指出有問題的 r9，下排為本輪 r10。只做縮放、排版與標籤，未修圖。

- [正面與左右 45°](pomeranian_r10_2026-10-04/face_false.png)
- [一般材質五角度](pomeranian_r10_2026-10-04/all_false.png)
- [SoftToon 五角度](pomeranian_r10_2026-10-04/all_true.png)
- [Idle／Walk／Sit，各取 25%、50%、75%](pomeranian_r10_2026-10-04/animations.png)

前臉的額頭／眼睛／口鼻已採同一套比例，原先鼻樑厚片和獨立黏上的鼻頭不再保留。
但**仍未通過完整外觀驗收**：側臉接原鬃毛的材質／形狀過渡、下巴接脖子的環狀
折邊、頭頂交界仍可見；側面投影的立體感也有限。原耳背破碎表面、頸前舊貼圖
殘影與 Sit 懸浮等問題未解決。因此不能把正面改善當作整隻狗已修好。

## 驗證與界限

- Blender 5.2 多輪渲染並檢視正面、左右 45°、側面。
- Godot 4.6.3 / D3D12 Forward Mobile / RTX 3070 Ti：20 張靜態對照及 9 張動畫
  取樣完成，退出碼 0，stderr 空白；已檢视兩套材質與動畫的所有組圖。
- `validate_pomeranian_r10.py` 對照原 r6：23 骨骼節點、bind matrices、動畫
  channels、插值與所有關鍵影格值一致。重封裝後 accessor 編號有改，不能宣稱
  整份 GLB 或動畫 JSON 完全 byte-identical。
- 使用中的頂點與法線均有限；兩個 primitive 都無零面積三角形；法線單位長度、
  權重總和與骨骼索引檢查通過。這些是資料有效性檢查，**不是美術通過**，也不是
  全模型自相交／最終拓撲驗收。
- 前臉 9,126 tris，保留部分 41,043 tris，總計 50,169 tris；3,130,528 bytes。
  超出角色目標面數，仍需後續完整降面與拓撲工作，不是行動裝置最終成品。
- 動畫取樣可見新前臉隨原骨架運動；既有 Sit 動作未修，不宣稱動畫品質通過。
  沒有執行玩法回歸，也不是盲測 QA。

## 交付

- 遊戲使用：`assets/characters/dog/models/breeds/pomeranian.glb`；
  `data/encounters/enc_old_master.tres` 的小白沿用此路徑，自動載入 r10。
- 更新前 r9 備份：`build/dogs_face_r10/publish_previous/pomeranian_r9.glb`。
- 後續品種採用的方法：[整臉重建流程](DOG_WHOLE_FACE_REPAIR_WORKFLOW.md)。

- 候選 GLB：`assets/art_previews/dogs/candidates/r10/pomeranian.glb`。
- SHA-256：`f3380b10d780b8d31c6d87fad7576f408f88fb4b15fd14942ba29f75ded2db5d`。
- 可編輯 Blender 檔：工作室 `blender/dog/pomeranian_r10/pomeranian_r10_01_shape.blend`。
- 驗證、原始截圖與貼圖：`build/dogs_face_r10/`；永久對照與驗證紀錄見本文件旁的資料夾。
- 重現：`rebuild_pomeranian_face_r10.py`、`render_pomeranian_r10.py`、
  `validate_pomeranian_r10.py`、`verify_pomeranian_r10.ps1`、`contact_pomeranian_r10.py`。
  `capture_pomeranian_r9.gd` 已支援候選／基準路徑參數，預設仍可重現 r9 檢查。

來源仍是主人製作的博美設定圖及原 breed factory 模型，沒有新第三方素材。
既有 rig／weight 來源與授權限制不變。實驗中的外圈重新投影造成後側折面顏色
混入，已撤回；交付 SHA 與通過資料檢查、完成 Godot 擷取的候選一致。
