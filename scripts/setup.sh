#!/bin/bash

set -e

echo "🚀 Setting up workspace..."

# =========================================================
# 🌱 WORKSPACE ENV
# =========================================================
WORKSPACE_ENV=".env.localdev"
WORKSPACE_EXAMPLE="env.example"

if [ ! -f "$WORKSPACE_EXAMPLE" ]; then
  echo "❌ Missing env.example in workspace root"
  exit 1
fi

if [ ! -f "$WORKSPACE_ENV" ]; then
  cp "$WORKSPACE_EXAMPLE" "$WORKSPACE_ENV"
  echo "✅ Workspace .env.localdev created"
else
  echo "↩️ Workspace .env.localdev already exists"
fi

# =========================================================
# 📦 CLONE REPOS
# =========================================================
bash scripts/git-clone.sh

# =========================================================
# ⚙️ SETUP ENVS PER REPO
# =========================================================
echo ""
echo "⚙️ Configuring env files in services..."

CONFIG_FILE="repos.json"
SERVICE_COUNT=$(jq '.services | length' $CONFIG_FILE)

for (( i=0; i<$SERVICE_COUNT; i++ ))
do
  NAME=$(jq -r ".services[$i].name" $CONFIG_FILE)
  DIR=$(jq -r ".services[$i].dir" $CONFIG_FILE)
  ENV_FILE=$(jq -r ".services[$i].env" $CONFIG_FILE)
  ENV_PATH=$(jq -r ".services[$i].env_path" $CONFIG_FILE)

  if [ -d "$DIR" ]; then
    echo "🔧 $NAME..."

    EXAMPLE="$DIR/env.example"

    if [ "$ENV_PATH" == "." ]; then
      TARGET_DIR="$DIR"
    else
      TARGET_DIR="$DIR/$ENV_PATH"
    fi

    TARGET="$TARGET_DIR/$ENV_FILE"

    if [ -f "$EXAMPLE" ]; then

      mkdir -p "$TARGET_DIR"

      if [ ! -f "$TARGET" ]; then
        cp "$EXAMPLE" "$TARGET"
        echo "✅ Created $TARGET"
      else
        echo "↩️ $TARGET already exists"
      fi

    else
      echo "⚠️ No .env.example in $NAME"
    fi
  else
    echo "⚠️ Directory $DIR not found"
  fi
done

# =========================================================
# 🐳 DOCKER
# =========================================================
echo ""
echo "🐳 Pulling images..."
docker compose pull

echo ""
echo "🔥 Setup complete"