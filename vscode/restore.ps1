# Restores a VS Code profile stored in this repo back into VS Code.
#
#   ./vscode/restore.ps1 -Profile minimal
#   ./vscode/restore.ps1 -Profile latex-jupyter -Extensions
#
# Existing files are backed up next to the originals as *.bak-<timestamp>.

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('default', 'minimal', 'latex-jupyter', 'angular-python')]
    [string]$Profile,

    # Also (re)install the extensions listed in extensions.txt for that profile.
    [switch]$Extensions
)

$ErrorActionPreference = 'Stop'

$sourceDir = Join-Path $PSScriptRoot "profiles\$Profile"
if (-not (Test-Path $sourceDir)) {
    throw "Profile folder not found: $sourceDir"
}

$manifest = Get-Content (Join-Path $PSScriptRoot 'profiles.json') -Raw | ConvertFrom-Json
$entry = $manifest.profiles | Where-Object { $_.folder -eq "profiles/$Profile" }
if (-not $entry) {
    throw "Profile '$Profile' is not listed in profiles.json"
}

$codeUser = Join-Path $env:APPDATA 'Code\User'
if ($entry.vscodeName -eq '__default__profile__') {
    $targetDir = $codeUser
}
else {
    $storagePath = Join-Path $codeUser 'globalStorage\storage.json'
    if (-not (Test-Path $storagePath)) {
        throw "VS Code storage.json not found at $storagePath"
    }
    $storage = Get-Content $storagePath -Raw | ConvertFrom-Json
    $live = $storage.userDataProfiles | Where-Object { $_.name -eq $entry.vscodeName }
    if (-not $live) {
        throw "Profile '$($entry.vscodeName)' does not exist in VS Code. Create it first, or restore into 'default'."
    }
    $targetDir = Join-Path $codeUser "profiles\$($live.location)"
}

if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach ($name in @('settings.json', 'keybindings.json')) {
    $src = Join-Path $sourceDir $name
    if (-not (Test-Path $src)) { continue }

    $dst = Join-Path $targetDir $name
    if ($PSCmdlet.ShouldProcess($dst, "restore $name")) {
        if (Test-Path $dst) {
            Copy-Item $dst "$dst.bak-$stamp"
        }
        Copy-Item $src $dst -Force
        Write-Host "restored $name -> $dst"
    }
}

if ($Extensions) {
    $listFile = Join-Path $sourceDir 'extensions.txt'
    if (Test-Path $listFile) {
        $code = Get-Command code -ErrorAction SilentlyContinue
        if (-not $code) {
            throw "The 'code' CLI is not on PATH; cannot install extensions."
        }
        $profileArgs = @()
        if ($entry.vscodeName -ne '__default__profile__') {
            $profileArgs = @('--profile', $entry.vscodeName)
        }

        Get-Content $listFile |
            Where-Object { $_.Trim() } |
            ForEach-Object {
                $id = ($_ -split '@')[0].Trim()
                if ($PSCmdlet.ShouldProcess($id, 'install extension')) {
                    Write-Host "installing $id"
                    & code @profileArgs --install-extension $id --force | Out-Null
                }
            }
    }
}

Write-Host "Done. Restart VS Code (or reload the window) to apply changes."
