# 七隻狗眼睛貼圖修正 r5

> 2026-10-03：主人指出本版 45° 仍有眼睛貼圖失敗，確認成立。
> 本頁眼睛驗收結論已撤回，由 [r6 修正紀錄](BREED_DOGS_EYES_R6_2026-10-03.md) 取代。

日期：2026-10-02。角色：Codex ART，自行檢查，非獨立盲測 QA。

**本次修正眼睛重影與拉伸；整隻狗的美術仍為 REVIEW，尚未完成。**
重新看過上一次已交付模型的左右 45° 近照，法鬥確實有第三顆眼睛，吉娃娃、柯基有重疊眼框，貴賓眼形被拉長。舊報告 r3／r4 的「通過」不能代表這些視覺問題已解決。本報告與本日截圖取代那些眼睛驗收結論。

## 修正與證據

清掉原本混合正面／側面投影留下的眼睛，再用主人原參考圖中的單一眼形，依每隻模型表面重新定位並烘入既有 UV。沒有新增眼球物件或改骨架。貴賓原本一眼落在傾斜的鼻樑表面，改到較高、朝前的真正頭部表面；法鬥另外重新定位鼻子，避免沿用整張參考圖包圍盒造成的臉部偏移。

對照圖上排是本次開始前實際交付的 r4，下排是 r5；左右順序為 −60°、−45°、正面、+45°、+60°。Godot 圖上排為一般材質，下排為 SoftToon，均為 −45°、正面、+45°，不是修過的宣傳圖。

| 品種 | 本次修正 | 最終 GLB bytes | 實際證據 |
|---|---|---:|---|
| 吉娃娃 | 清除重疊眼框，左右各一個眼形 | 2,021,996 | [前後對照](dog_face_review_2026-10-02/chihuahua_heads.png) · [Godot](dog_face_review_2026-10-02/chihuahua_godot.png) |
| 博美 | 重新定位眼睛，清除舊投影殘邊 | 2,444,612 | [前後對照](dog_face_review_2026-10-02/pomeranian_heads.png) · [Godot](dog_face_review_2026-10-02/pomeranian_godot.png) |
| 貴賓 | 眼睛移離鼻樑斜面；正面不再壓成細縫 | 2,072,636 | [前後對照](dog_face_review_2026-10-02/poodle_heads.png) · [Godot](dog_face_review_2026-10-02/poodle_godot.png) |
| 法鬥 | 移除第三顆眼睛，重畫中央毛色並對準鼻子 | 2,069,416 | [前後對照](dog_face_review_2026-10-02/frenchie_heads.png) · [Godot](dog_face_review_2026-10-02/frenchie_godot.png) |
| 柯基 | 清除重疊眼線，重新定位左右眼 | 2,049,260 | [前後對照](dog_face_review_2026-10-02/corgi_heads.png) · [Godot](dog_face_review_2026-10-02/corgi_godot.png) |
| 柴犬 | 統一眼睛投影，清除眼角殘片 | 2,085,216 | [前後對照](dog_face_review_2026-10-02/shiba_heads.png) · [Godot](dog_face_review_2026-10-02/shiba_godot.png) |
| 黃金獵犬 | 重畫單一眼形與周圍殘影 | 2,350,596 | [前後對照](dog_face_review_2026-10-02/golden_heads.png) · [Godot](dog_face_review_2026-10-02/golden_godot.png) |

## 驗證

- Blender：每隻正面、左右 30°／45°／60°／90°近照；實際檢視前後對照。另輸出 3/4、側面、背面、低角度，以及 Idle／Walk／Sit 中段。[全身與動作對照](dog_face_review_2026-10-02/body_and_clips.png)。
- Godot 4.6.3 / RTX 3070 Ti：42 張近照（7 隻 × 3 角度 × 2 材質），已檢視七隻一般／卡通材質對照，貴賓最後定位後重新匯入並重拍。[擷取紀錄](dog_face_review_2026-10-02/godot_capture.log)。
- `tests/run_all.sh`：32 個測試場景 PASS，結束碼 0。[測試紀錄](dog_face_review_2026-10-02/tests.log)。最後貴賓僅換 JPEG 後，再做 Godot 匯入與上述畫面檢查，未重新跑無關的完整測試。
- 封裝逐一驗證所有非圖片 bufferView 與原始 GLB 位元組相同；mesh、UV、23 骨骼、skin weights、Idle／Walk／Sit 及材質設定未改。每隻的 `verification.json` 留在本日證據目錄，含來源與結果 SHA-256。全部使用 1024² JPEG，低於 2.5 MB。

## 尚未完成，不能標成全部修好

- 吉娃娃、法鬥、柯基、柴犬等口鼻仍有多視角貼圖接縫或重複嘴／舌片；本次眼睛修正沒有把這些一起解決。
- 博美鼻樑／額頭突出面、毛髮尖片，法鬥後部尖片，貴賓耳朵空隙及不對稱頭形仍在。
- 移除錯誤投影後，眼睛周圍有些毛色較平；法鬥中央色塊與貴賓鼻樑過渡仍需美術細修。
- Sit 原有變形仍在；不得把「動畫資料保留／可載入」當成動作品質通過。
- 這是預覽候選，仍非 S 級最終角色，沒有放進遊戲正式角色目錄。

## 檔案與重現

預覽：`assets/art_previews/dogs/models/<breed>.glb`；用 `tools/art/open_dog_lineup.bat` **重新開啟**，避免舊程序仍顯示快取模型。Enter 換動作、Space 切卡通、左右鍵轉視角。

原版 factory `<breed>_game.glb` 與 `projection/basecolor.png` 保留；修正版沿用 `_game_codex.glb`、`basecolor_codex.png`。本次開始前的完整備份位於 `build/dogs_face_repair_r5/previous/`，候選輸出在 `candidate/`。

最終七隻 preview GLB 與 factory `_codex` GLB／PNG 已同步並逐檔比對 SHA-256：[preview 交付紀錄](dog_face_review_2026-10-02/published_preview.json)、[factory 交付紀錄](dog_face_review_2026-10-02/published_factory.json)。

主要腳本：`repair_breed_dog_textures.py`、`repair_dog_faces.py`、`package_breed_dog_textures.py`。以 `DOG_REPAIR_OUT` 指定輸出目錄。`iterate_dog_eyes.py` 是使用 r4 備份與 UV 表面快取的快速局部修改工具；`publish_dog_face_repairs.py` 核對原檔雜湊及前次交付紀錄後才複製。截圖由 `render_breed_dog_repairs.py`、`capture_dog_faces.gd` 產出。

素材僅使用原主人參考圖與既有 factory 貼圖，沒有新第三方素材；原本 skin weights 的 grade B／地域授權限制仍適用，詳見預覽目錄 PROVENANCE.md。
