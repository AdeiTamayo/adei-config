# Copies the live VS Code profile files into this repo.
#
#   ./vscode/export.ps1
#
# Existing repo copies are backed up to vscode/.backup/<timestamp>/ first.
# Close the Settings / Keyboard Shortcuts editors (or VS Code itself) so that
# changes are flushed to disk before exporting.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$manifest = Get-Content (Join-Path $PSScriptRoot 'profiles.json') -Raw | ConvertFrom-Json
$codeUser = Join-Path $env:APPDATA 'Code\User'
$storagePath = Join-Path $codeUser 'globalStorage\storage.json'
$storage = if (Test-Path $storagePath) { Get-Content $storagePath -Raw | ConvertFrom-Json } else { $null }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $PSScriptRoot ".backup\$stamp"

function Get-ProfileDir($entry) {
    if ($entry.vscodeName -eq '__default__profile__') { return $codeUser }
    if (-not $storage) { return $null }
    $live = $storage.userDataProfiles | Where-Object { $_.name -eq $entry.vscodeName }
    if (-not $live) { return $null }
    return Join-Path $codeUser "profiles\$($live.location)"
}

function Get-Extensions($dir) {
    $file = Join-Path $dir 'extensions.json'
    if (-not (Test-Path $file)) { return @() }
    (Get-Content $file -Raw | ConvertFrom-Json) |
        ForEach-Object { "{0}@{1}" -f $_.identifier.id, $_.version }
}

foreach ($entry in $manifest.profiles) {
    $liveDir = Get-ProfileDir $entry
    if (-not $liveDir -or -not (Test-Path $liveDir)) {
        Write-Warning "skipping $($entry.folder): VS Code profile '$($entry.vscodeName)' not found"
        continue
    }

    $repoDir = Join-Path $PSScriptRoot $entry.folder
    New-Item -ItemType Directory -Force -Path $repoDir | Out-Null

    foreach ($name in @('settings.json', 'keybindings.json')) {
        $src = Join-Path $liveDir $name
        if (-not (Test-Path $src)) { continue }

        $dst = Join-Path $repoDir $name
        if (Test-Path $dst) {
            $backupDir = Join-Path $backupRoot $entry.folder
            New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
            Copy-Item $dst (Join-Path $backupDir $name)
        }
        Copy-Item $src $dst -Force
        Write-Host "exported $name <- $src"
    }

    # The default profile has no extensions.json; fall back to the globally
    # installed extensions in ~/.vscode/extensions.
    $extensions = Get-Extensions $liveDir
    if (-not $extensions -and $entry.vscodeName -eq '__default__profile__') {
        $extRoot = Join-Path $env:USERPROFILE '.vscode\extensions'
        $extensions = Get-ChildItem $extRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { Test-Path (Join-Path $_.FullName 'package.json') } |
            ForEach-Object {
                $pkg = Get-Content (Join-Path $_.FullName 'package.json') -Raw | ConvertFrom-Json
                "{0}@{1}" -f "$($pkg.publisher).$($pkg.name)".ToLower(), $pkg.version
            } | Sort-Object -Unique
    }
    if ($extensions) {
        $extensions | Sort-Object | Set-Content (Join-Path $repoDir 'extensions.txt') -Encoding utf8
        Write-Host "exported extensions.txt for $($entry.folder)"
    }
}

Write-Host "Done."
