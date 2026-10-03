$ErrorActionPreference = 'Stop'
$project = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$godotExe = 'C:\Users\b\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe'
$stage = Join-Path $project 'build\dogs_eye_r6'
$importArgs = @('--headless', '--editor', '--path', $project, '--import', '--quit')
$p = Start-Process -FilePath $godotExe -ArgumentList $importArgs -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $stage 'final_import.log') -RedirectStandardError (Join-Path $stage 'final_import_stderr.log')
if ($p.ExitCode -ne 0) { throw "Godot import failed: $($p.ExitCode)" }
$captureArgs = @('--path', $project, '--resolution', '800x800', '--script', 'res://tools/art/capture_dog_faces.gd', '--', '--output', 'res://build/dogs_eye_r6/godot_final')
$p = Start-Process -FilePath $godotExe -ArgumentList $captureArgs -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $stage 'final_capture.log') -RedirectStandardError (Join-Path $stage 'final_capture_stderr.log')
if ($p.ExitCode -ne 0) { throw "Godot capture failed: $($p.ExitCode)" }
$count = (Get-ChildItem -LiteralPath (Join-Path $stage 'godot_final') -Filter '*.png').Count
if ($count -ne 42) { throw "Expected 42 captures, got $count" }
Write-Output "R6_RUNTIME_CAPTURE_COMPLETE images=$count"
