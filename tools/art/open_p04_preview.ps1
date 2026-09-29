$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
& godot --path $projectRoot --rendering-method gl_compatibility --scene res://assets/art_previews/p04/p04_asset_showcase.tscn
