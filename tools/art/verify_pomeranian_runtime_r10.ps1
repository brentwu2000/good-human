$ErrorActionPreference = 'Stop'
$project = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$godotExe = 'C:\Users\b\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe'
$stage = Join-Path $project 'build\dogs_face_r10'
$p = Start-Process -FilePath $godotExe -ArgumentList @('--headless','--editor','--path',$project,'--import','--quit') -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $stage 'import.log') -RedirectStandardError (Join-Path $stage 'import_stderr.log')
if ($p.ExitCode -ne 0) { throw "Import exit: $($p.ExitCode)" }
$captureArgs = @('--path',$project,'--resolution','800x800','--script','res://tools/art/capture_pomeranian_r9.gd','--','--candidate','res://assets/characters/dog/models/breeds/pomeranian.glb','--baseline','res://assets/art_previews/dogs/candidates/r9/pomeranian.glb','--encounter','res://data/encounters/enc_old_master.tres','--label','r10','--baseline-label','r9','--output','res://build/dogs_face_r10/godot')
$p = Start-Process -FilePath $godotExe -ArgumentList $captureArgs -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $stage 'capture.log') -RedirectStandardError (Join-Path $stage 'capture_stderr.log')
if ($p.ExitCode -ne 0) { throw "Capture exit: $($p.ExitCode)" }
$count = (Get-ChildItem -LiteralPath (Join-Path $stage 'godot') -Filter '*.png').Count
if ($count -ne 29) { throw "Expected 29 captures, got $count" }
Get-Content (Join-Path $stage 'capture.log'),(Join-Path $stage 'capture_stderr.log')

