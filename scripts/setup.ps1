Write-Host "🚀 Setting up workspace..."

$ErrorActionPreference = "Stop"

# =========================================================
# 🌱 WORKSPACE ENV
# =========================================================

$workspaceEnv = ".env.localdev"
$workspaceExample = "env.example"

if (!(Test-Path $workspaceExample)) {
    Write-Host "❌ Missing env.example in workspace root"
    exit 1
}

if (!(Test-Path $workspaceEnv)) {
    Copy-Item $workspaceExample $workspaceEnv
    Write-Host "✅ Workspace .env.localdev created"
} else {
    Write-Host "↩️ Workspace .env.localdev already exists"
}

# =========================================================
# 📦 CLONE REPOS
# =========================================================

powershell -ExecutionPolicy Bypass -File scripts/git-clone.ps1

# =========================================================
# ⚙️ SETUP ENVS PER REPO
# =========================================================

Write-Host ""
Write-Host "⚙️ Configuring env files in services..."

$config = Get-Content "repos.json" | ConvertFrom-Json

foreach ($service in $config.services) {

    $name = $service.name
    $dir = $service.dir
    $envFile = $service.env
    $envPath = $service.env_path

    if (Test-Path $dir) {

        Write-Host "🔧 $name..."

        $example = Join-Path $dir "env.example"

        if ($envPath -eq ".") {
            $targetDir = $dir
        } else {
            $targetDir = Join-Path $dir $envPath
        }

        $target = Join-Path $targetDir $envFile

        if (Test-Path $example) {

            if (!(Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir | Out-Null
            }

            if (!(Test-Path $target)) {
                Copy-Item $example $target
                Write-Host "✅ Created $target"
            } else {
                Write-Host "↩️ $target already exists"
            }

        } else {
            Write-Host "⚠️ No env.example in $name"
        }

    } else {
        Write-Host "⚠️ Directory $dir not found"
    }
}

# =========================================================
# 🐳 DOCKER
# =========================================================

Write-Host ""
Write-Host "🐳 Pulling Docker images..."
docker compose pull

Write-Host ""
Write-Host "🔥 Setup complete!"