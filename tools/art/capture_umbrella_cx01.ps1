param([ValidateSet('before','after')][string]$Version='before')
$ErrorActionPreference='Stop'
$project=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$exe='C:/Users/b/Downloads/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64_console.exe'
$folder=Join-Path $project ('build/umbrella_cx01/'+$Version)
New-Item -ItemType Directory -Path $folder -Force | Out-Null
foreach ($kind in @('showcase','fight')) {
    $args=@('--path',$project,'--write-movie',($folder+'/'+$kind+'.avi'),'--fixed-fps','30','--resolution','405x720',('res://tools/art/umbrella_'+$kind+'_capture.tscn'),'--','umbrella','--art-output',('res://build/umbrella_cx01/'+$Version+'/'+$kind))
    $p=Start-Process -FilePath $exe -ArgumentList $args -WindowStyle Hidden -RedirectStandardOutput ($folder+'/'+$kind+'.log') -RedirectStandardError ($folder+'/'+$kind+'.err') -PassThru
    $processHandle=$p.Handle
    if (-not $p.WaitForExit(180000)) { $p.Kill(); throw "Capture timeout $kind" }
    $p.Refresh()
    if ($p.ExitCode -ne 0) { throw "Capture failed $kind" }
    Get-Content ($folder+'/'+$kind+'.log'),($folder+'/'+$kind+'.err')
}
