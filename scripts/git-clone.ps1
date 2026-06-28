Write-Host "📦 Cloning repositories from repos.json..."

# =========================================================
# CONFIG
# =========================================================

$ErrorActionPreference = "Stop"

$configFile = "repos.json"

if (!(Test-Path $configFile)) {
    Write-Host "❌ repos.json not found"
    exit 1
}

# Leer JSON
$config = Get-Content $configFile | ConvertFrom-Json

# =========================================================
# FUNCTION
# =========================================================

function Clone-If-Not-Exists {
    param (
        [string]$Name,
        [string]$RepoUrl,
        [string]$TargetDir
    )

    if ([string]::IsNullOrEmpty($RepoUrl)) {
        Write-Host "⚠️ No repo defined for $Name. Skipping..."
        return
    }

    
    if (!(Test-Path $TargetDir) -or !(Get-ChildItem -Path $TargetDir -Force | Select-Object -First 1)) {
        Write-Host "📥 Cloning $Name..."
        git clone $RepoUrl $TargetDir
    } else {
        Write-Host "✅ $Name already exists. Skipping."
    }
}

# =========================================================
# EXECUTION
# =========================================================

foreach ($service in $config.services) {
    $name = $service.name
    $repo = $service.repo
    $dir = $service.dir

    Clone-If-Not-Exists -Name $name -RepoUrl $repo -TargetDir $dir
}

Write-Host ""
Write-Host "🔥 All repositories processed."