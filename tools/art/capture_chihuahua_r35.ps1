$ErrorActionPreference='Stop'
$project=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$exe='C:/Users/b/Downloads/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64_console.exe'
$out=Join-Path $project 'build/dog_polish_r35'
& $exe --headless --editor --path $project --import *> "$out/import.log"
if ($LASTEXITCODE -ne 0) { throw 'Import failed' }
$args=@('--path',$project,'--resolution','800x800','--script','res://tools/art/capture_pomeranian_r9.gd','--','--candidate','res://assets/art_previews/dogs/candidates/r35/chihuahua.glb','--baseline','res://assets/art_previews/dogs/candidates/r34/models/chihuahua.glb','--height','0.35','--breed','Chihuahua','--label','r35','--baseline-label','r34','--output','res://build/dog_polish_r35/godot')
$p=Start-Process -FilePath $exe -ArgumentList $args -WindowStyle Hidden -RedirectStandardOutput "$out/capture.log" -RedirectStandardError "$out/capture.err" -PassThru
$handle=$p.Handle
if (-not $p.WaitForExit(120000)) { $p.Kill(); throw 'Capture timed out' }
$p.Refresh();if($p.ExitCode -ne 0){throw 'Capture failed'}
Get-Content "$out/capture.log","$out/capture.err"
