& 'C:/Users/b/Downloads/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64_console.exe' --headless --editor --path . --import
$OutputDirectory = 'build/dog_polish_r36'
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$godotExe = 'C:/Users/b/Downloads/Godot_v4.6.3-stable_win64.exe/Godot_v4.6.3-stable_win64_console.exe'
$out = Join-Path $project $OutputDirectory
$results = @()
foreach ($suite in @('breed_models','dog_motion')) {
    $stdout = Join-Path $out ($suite + '_final.log')
    $stderr = Join-Path $out ($suite + '_final.err')
    $p = Start-Process -FilePath $godotExe -ArgumentList @('--headless','--path',$project,('res://tests/' + $suite + '_test.tscn')) -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
    $processHandle = $p.Handle
    if (-not $p.WaitForExit(60000)) { $p.Kill(); throw "Timeout: $suite" }
    $p.Refresh()
    $log = (Get-Content -Raw $stdout) + (Get-Content -Raw $stderr)
    $passed = $p.ExitCode -eq 0 -and $log -match 'PASS' -and $log -notmatch 'SCRIPT ERROR|FAIL:|FAILED'
    $results += [pscustomobject]@{ suite=$suite; passed=$passed; exit_code=$p.ExitCode; output=$log }
    Write-Output $log
    if (-not $passed) { throw "Failed: $suite" }
}
$results | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $out 'regression_final.json')
