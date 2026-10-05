$ErrorActionPreference = 'Stop'
$project = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$godotExe = 'C:\Users\b\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe'
$stage = Join-Path $project 'build\frenchie_face_r11'
$p = Start-Process -FilePath $godotExe -ArgumentList @('--headless','--editor','--path',$project,'--import','--quit') -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $stage 'import.log') -RedirectStandardError (Join-Path $stage 'import_stderr.log')
if ($p.ExitCode -ne 0) { throw "Import exit: $($p.ExitCode)" }
$captureArgs = @('--path',$project,'--resolution','800x800','--script','res://tools/art/capture_pomeranian_r9.gd','--','--candidate','res://assets/art_previews/dogs/candidates/r11/frenchie.glb','--baseline','res://assets/art_previews/dogs/candidates/r11/frenchie_r6.glb','--height','0.45','--breed','Frenchie','--label','r11','--baseline-label','r6','--output','res://build/frenchie_face_r11/godot')
$p = Start-Process -FilePath $godotExe -ArgumentList $captureArgs -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $stage 'capture.log') -RedirectStandardError (Join-Path $stage 'capture_stderr.log')
if ($p.ExitCode -ne 0) { throw "Capture exit: $($p.ExitCode)" }
$count = (Get-ChildItem -LiteralPath (Join-Path $stage 'godot') -Filter '*.png').Count
if ($count -ne 29) { throw "Expected 29 captures, got $count" }
Get-Content (Join-Path $stage 'capture.log'),(Join-Path $stage 'capture_stderr.log')

