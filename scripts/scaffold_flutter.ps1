Param(
    [switch]$Force
)

# Scaffold a full Flutter Android app into ./flutter_app using your existing lib/ and tests.
# Requirements: Flutter SDK installed and on PATH.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Exec($cmd, $cwd) {
    Write-Host "> $cmd" -ForegroundColor Cyan
    if ($cwd) { Push-Location $cwd }
    try { & powershell -NoProfile -Command $cmd }
    finally { if ($cwd) { Pop-Location } }
}

$repo = Resolve-Path "$PSScriptRoot/.."
$target = Join-Path $repo 'flutter_app'
$backup = Join-Path $repo ("flutter_app_backup_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))

# 1) Check flutter
try {
    $flutterPath = (Get-Command flutter -ErrorAction Stop).Source
    Write-Host "Found Flutter: $flutterPath" -ForegroundColor Green
} catch {
    Write-Error "Flutter not found on PATH. Install Flutter and Android Studio, then re-run."
    exit 1
}

# 2) Backup existing flutter_app dir (non-destructive)
if (Test-Path $target) {
    if ($Force) {
        Write-Host "Removing existing $target (Force)" -ForegroundColor Yellow
        Remove-Item -Recurse -Force $target
    } else {
        Write-Host "Backing up existing flutter_app -> $backup" -ForegroundColor Yellow
        Move-Item $target $backup
    }
}

# 3) Create fresh Flutter project
Exec "flutter create --platforms=android --org com.mcd.pointtracker flutter_app" $repo

# 4) Overwrite lib/ with domain code from backup (preserve our implementation)
if (Test-Path "$backup/lib") {
    Remove-Item -Recurse -Force "$target/lib" | Out-Null
    Copy-Item -Recurse -Force "$backup/lib" "$target" 
}

# 5) Copy tests from backup if present
if (Test-Path "$backup/test") {
    New-Item -ItemType Directory -Force -Path "$target/test" | Out-Null
    Copy-Item -Recurse -Force "$backup/test/*" "$target/test/"
}

# 6) Ensure crypto dependency
Exec "flutter pub add crypto" $target

# 7) Run pub get and tests
Exec "flutter pub get" $target
try {
    Exec "flutter test" $target
} catch {
    Write-Warning "Tests failed. Review output above."
}

Write-Host "Done. To run on Android: cd $target; flutter run" -ForegroundColor Green


