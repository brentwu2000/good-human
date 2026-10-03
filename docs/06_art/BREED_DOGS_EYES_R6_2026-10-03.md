# 七隻狗眼睛修正 r6

日期：2026-10-03（工作始於 10-02）。角色：Codex ART，自行視覺驗證，非盲測 QA。

主人指出 r5 在 45° 仍有貼圖失敗，這個指正成立。**r5 的眼睛驗收結論撤回。**

本次已更新七隻預覽 GLB，修正眼睛本身的白色斜切、舊眼框殘留與投影形變；
整個頭部仍有口鼻貼圖接縫及網格問題，不能把這次更新當成整隻角色通過。

## 確認的原因與修正

- 法鬥原正面參考圖的鼻口遮住眼睛下緣。r5 把整塊眼睛裁圖投影到臉上，
  連遮擋眼睛的白色鼻口也被烘進貼圖，形成斜切。單純搬眼睛位置無法修好。
- r5 的 45° 固定切平面與頭部前表面不一致，側看時眼形被拉扯。
- 原眼框的清除範圍不夠，博美眼睛下方保留了一段舊黑邊。
- 本次以主人原吉娃娃參考圖的眼睛風格，用內建 imagegen 產生完整、未被鼻口
  遮擋的單眼素材。它是新的共用眼睛素材，眼形／眼白與 r5 有所不同，並非原
  眼睛像素的無損修復。[素材、完整 prompt 與來源紀錄](../../assets/_source/generated/dog_eyes_r6/PROVENANCE.md)。
- 每隻、每側以 ray cast 找到頭部落點，再用較朝前的局部座標烘回既有 UV；
  檢查實際表面遮擋，避免把新眼睛投到凹折後方。擴大舊眼框清除範圍，並以
  16 次取樣處理透明邊緣。
- 測試過獨立立體眼球，但外觀像圓鈕，因此沒有交付該方案。最終不新增眼球
  mesh，只替換嵌入式 JPEG。

## 實際前後對照

前後對照上排 r5、下排 r6，依序 −45°、正面、+45°。Godot 圖上排一般材質、
下排 SoftToon。所有圖片都是實際模型畫面，只縮放排版，沒有修圖掩蓋接縫。

| 品種 | r5 / r6 | 最終 Godot |
|---|---|---|
| 吉娃娃 | [前後](dog_eye_review_r6_2026-10-03/chihuahua_before_after.png) | [三角度／雙材質](dog_eye_review_r6_2026-10-03/chihuahua_godot.png) |
| 博美 | [前後](dog_eye_review_r6_2026-10-03/pomeranian_before_after.png) | [三角度／雙材質](dog_eye_review_r6_2026-10-03/pomeranian_godot.png) |
| 貴賓 | [前後](dog_eye_review_r6_2026-10-03/poodle_before_after.png) | [三角度／雙材質](dog_eye_review_r6_2026-10-03/poodle_godot.png) |
| 法鬥 | [前後](dog_eye_review_r6_2026-10-03/frenchie_before_after.png) | [三角度／雙材質](dog_eye_review_r6_2026-10-03/frenchie_godot.png) |
| 柯基 | [前後](dog_eye_review_r6_2026-10-03/corgi_before_after.png) | [三角度／雙材質](dog_eye_review_r6_2026-10-03/corgi_godot.png) |
| 柴犬 | [前後](dog_eye_review_r6_2026-10-03/shiba_before_after.png) | [三角度／雙材質](dog_eye_review_r6_2026-10-03/shiba_godot.png) |
| 黃金獵犬 | [前後](dog_eye_review_r6_2026-10-03/golden_before_after.png) | [三角度／雙材質](dog_eye_review_r6_2026-10-03/golden_godot.png) |

## 驗證與交付

- Blender 5.2：最終版本各輸出正面、左右 45°／60°，並檢視七組左右 45° 前後對照。
- Godot 4.6.3／D3D12 Forward Mobile／RTX 3070 Ti：重新匯入成功；最終 42 張
  畫面（7 × 3 × 2）擷取完成並檢視七組對照，stdout 為
  `DOG_FACE_CAPTURE_OK dogs=7 angles=3 modes=2`，stderr 空白，程序結束碼 0。
  [擷取紀錄](dog_eye_review_r6_2026-10-03/godot_capture.log)。
- 擷取程式檢查七隻模型均有 Idle／Walk／Sit。封裝逐一比對非圖片 bufferView
  及 mesh、UV、skin、23 骨骼、動畫、材質 JSON，全部與 factory 原 GLB 相同。
  各品種 `*_verification.json` 位於本次證據資料夾。所有 GLB 均小於 2.5 MB。
- 本次是材質修正，沒有重跑整套玩法測試，也不宣稱原本的 Sit 變形已修復。
- 預覽交付：`assets/art_previews/dogs/models/<breed>.glb`。
  [逐檔 SHA-256](dog_eye_review_r6_2026-10-03/published_preview.json)。
- Factory 的 `_game_codex.glb`／`basecolor_codex.png` 已同步並逐檔核對；
  原始 `_game.glb`／`basecolor.png` 未覆寫。
  [Factory 交付紀錄](dog_eye_review_r6_2026-10-03/published_factory.json)。
- 本次開始前的 r5 備份：`build/dogs_eye_r6/previous/`。
  候選 atlas／GLB：`build/dogs_eye_r6/texture_candidate/`。
  最終原始 Godot 圖：`build/dogs_eye_r6/godot_final/`。

以 `tools/art/open_dog_lineup.bat` **重新啟動**預覽即可載入本次模型。
Enter 換動作、Space 切材質、左右鍵旋轉。

## 仍然存在的品質限制

口鼻仍有明顯的正面／側面投影接縫、重複嘴形與鼻子色塊；博美鼻樑突出面會
遮住遠側眼睛，鼻樑附近仍有鼻子投影的黑色斑塊。這些不能說成眼睛重新烘焙
就已解決。貴賓的耳部空隙、法鬥的破面、既有動作變形也保留。

1024² 全身 atlas 在極近距離仍能看到眼緣像素；眼周清除區的毛色偏平，
整體仍是 REVIEW／B 級預覽，沒有 S 級最終品質認可。

重現工具：`bake_complete_dog_eyes.py`、`package_breed_dog_textures.py`、
`render_breed_dog_repairs.py`、`publish_dog_eyes_r6.py`、
`verify_dog_eyes_r6.ps1`、`contact_dog_eyes_r6.py`。

## r7 實驗擱置 — 2026-10-03

Codex 曾開始 r7（`rebuild_dog_faces_r7.py`：挖眼窩、加眼球與眼瞼幾何、重建臉部 atlas），
七隻候選只停在 `build/dogs_face_r7/`，未驗收、未發佈。工作室渲染
（`build/dogs_face_r7/r7_color_sheet.png`）顯示：眼睛成為全黑圓珠，正是上方已否決的
「圓鈕」外觀；博美額頭出現凹洞；貴賓耳部空隙與口鼻接縫仍在；且改動幾何，違反只換貼圖的
原則。主人決定擱置 r7，預覽維持 r6。r7 腳本與 build 產物保留未提交，僅供參考。
