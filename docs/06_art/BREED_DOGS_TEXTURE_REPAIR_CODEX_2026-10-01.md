# 七隻品種狗貼圖修復 — Codex ART

日期：2026-10-01。依 `BREED_DOGS_TEXTURE_HANDOFF_TO_CODEX.md` 執行。
狀態：貼圖修正版／預覽候選；尚未達 S 級最終美術。這是 ART 自檢，不是獨立盲測 QA。

本輪處理錯色、投影重影和隱藏面拖影。使用原有角色參考圖、Blender 5.2 表面投影與配色補繪，保留原 UV。沒有加入新的第三方素材或研究用途模型。新增區域刻意減弱參考圖烘入的強光，部分區域因此比原版毛髮細節平坦。

## 每隻的變更與對照

對照圖上排為 factory 原版，下排為本次修正版；由左至右為 3/4、側面、背面、低角度。

| 品種 | 本輪改善 | 尚存問題 | 對照與動畫 |
|---|---|---|---|
| 吉娃娃 | 腳掌、腿內側及腹部灰白拖影減少；耳背統一暖棕色 | 後腦與身體仍有投影分塊；低角度嘴部與薄片輪廓仍不理想 | [前後](dog_texture_review_2026-10-01/chihuahua/chihuahua_before_after.png) · [動作](dog_texture_review_2026-10-01/chihuahua/chihuahua_clips.png) |
| 博美 | 頭頂與耳背的過白破片減少；尾巴統一橘奶油色；補齊腳底 | 毛尖和頭頂的幾何破口仍在；側面鼻口黑線尚未完全消除 | [前後](dog_texture_review_2026-10-01/pomeranian/pomeranian_before_after.png) · [動作](dog_texture_review_2026-10-01/pomeranian/pomeranian_clips.png) |
| 貴賓 | 以單一正面來源取代相互重疊的眼睛、嘴巴；整理髮夾、耳背與腳底 | 前額到頭側仍有毛髮尺度與亮度差；耳朵實際孔洞、片狀尾巴及軀幹分塊尚存 | [前後](dog_texture_review_2026-10-01/poodle/poodle_before_after.png) · [動作](dog_texture_review_2026-10-01/poodle/poodle_clips.png) |
| 法鬥 | 清掉尾巴和臀部上的背帶圖案；背部改為簡化棕色斑塊；補齊奶油色腹部 | 原本背部突片、長尾與嘴部錯位仍在；新背帶採簡化色帶，並非完整重新建模 | [前後](dog_texture_review_2026-10-01/frenchie/frenchie_before_after.png) · [動作](dog_texture_review_2026-10-01/frenchie/frenchie_clips.png) |
| 柯基 | 清除尾巴藍色項圈片；耳背與腳掌補色；腿內側減少灰白拖影 | 側腹仍可見一條細直線；後頸項圈銜接與側面嘴鼻需再精修 | [前後](dog_texture_review_2026-10-01/corgi/corgi_before_after.png) · [動作](dog_texture_review_2026-10-01/corgi/corgi_clips.png) |
| 柴犬 | 耳背白片、尾巴突兀白楔及腿內側紅色污染減少；腳底補色 | 後腦／項圈交界仍有色塊；尾巴新毛色較平滑 | [前後](dog_texture_review_2026-10-01/shiba/shiba_before_after.png) · [動作](dog_texture_review_2026-10-01/shiba/shiba_clips.png) |
| 黃金獵犬 | 灰色腳底改為暖色毛與肉墊；腹部及尾巴補色；減弱背部接縫 | 背部長毛仍有投影分塊，腹部細節比可見側面少 | [前後](dog_texture_review_2026-10-01/golden/golden_before_after.png) · [動作](dog_texture_review_2026-10-01/golden/golden_clips.png) |

所有犬種的 Sit 後軀變形屬既有權重／動作問題，本輪沒有修正。上面的動畫圖是各 clip 中間時間的截圖，不代表完整動作品質合格。

## 交付位置與原檔保護

- 預覽：`assets/art_previews/dogs/models/<id>.glb`。
- Factory 新檔：`../good_human_stylized_factory/export/dogs/<id>_game_codex.glb`。
- 無損貼圖：`../good_human_stylized_factory/texture_work/dogs/<id>/projection/basecolor_codex.png`。
- 原本的 `<id>_game.glb`、`basecolor.png` 均以 SHA-256 比對確認未變。
- 預覽替換前備份：`build/dogs_texture_codex/preview_originals/`。
- 原遊戲主角 `assets/characters/dog/models/shiba_01/` 未修改；七隻仍僅用於獨立 preview。

每隻證據資料夾中的 `verification.json` 保存原／新 GLB SHA-256、檔案大小及結構驗證；`material_repair.json` 保存原始 PNG SHA-256。

| GLB | 原版 bytes | 修正版 bytes | MB（十進位） |
|---|---:|---:|---:|
| chihuahua | 1,981,048 | 2,027,384 | 2.027 |
| pomeranian | 2,368,164 | 2,448,236 | 2.448 |
| poodle | 2,024,872 | 2,070,868 | 2.071 |
| frenchie | 2,035,180 | 2,076,000 | 2.076 |
| corgi | 1,991,204 | 2,055,520 | 2.056 |
| shiba | 2,024,688 | 2,088,068 | 2.088 |
| golden | 2,277,184 | 2,361,720 | 2.362 |

## 驗證

封裝只替換內嵌 JPEG；所有非圖片 bufferView 逐位元比對相同，並比對 meshes、skins、nodes、animations、accessors、materials、textures、samplers、scenes。保留 DogBody、Shiba_Rig、23 根骨骼和 Idle／Walk／Sit；貼圖為 1024 × 1024 JPEG，未加入 normal／AO。

Blender：每隻均輸出正面、3/4、側面、背面、低角度，以及 Idle／Walk／Sit 中間時間截圖，並檢視前後對照。渲染器依據動作後的包圍盒取景，避免 Sit 超出畫面。

Godot 4.6.3：更新後 `--headless --import` exit 0；實際 preview 載入七隻與三個 clip，擷取 [一般模式](dog_texture_review_2026-10-01/lineup_standard.png) 和 [Soft toon](dog_texture_review_2026-10-01/lineup_toon.png)。兩張均經檢視，七隻有顯示且沒有缺失貼圖；隊列遠景只用於確認引擎整合，細節判斷以上方 Blender 近景為準。[擷取日誌](dog_texture_review_2026-10-01/godot_capture.log)。

更新預覽模型後，`tests/run_all.sh` 的 32 個測試場景全部 PASS、exit 0，見 [完整結果](dog_texture_review_2026-10-01/tests.log)。測試不涵蓋美術品質；上述尚存問題不因測試通過而視為解決。沙箱內曾因 Godot 使用者日誌目錄權限而無法執行，改以授權的正常使用者權限完成測試。

## 可重現工具

`tools/art/repair_breed_dog_textures.py` 產生貼圖；`package_breed_dog_textures.py` 封裝與逐位元驗證；`render_breed_dog_repairs.py` 渲染；`contact_breed_dog_reviews.py` 排列原始截圖；`publish_breed_dog_repairs.py` 檢查原檔雜湊後交付；`capture_breed_dog_modes.gd` 擷取實際預覽的兩種材質模式。

授權沿用 [PROVENANCE](../../assets/art_previews/dogs/PROVENANCE.md) 所記載的來源；修圖不改變原先繼承權重的地域限制。
