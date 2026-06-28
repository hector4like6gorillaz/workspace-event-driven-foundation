#!/bin/bash

set -e

CONFIG_FILE="repos.json"

if ! command -v jq &> /dev/null; then
  echo "❌ jq is required. Install with: brew install jq"
  exit 1
fi

echo "📦 Cloning repositories from $CONFIG_FILE..."

SERVICE_COUNT=$(jq '.services | length' $CONFIG_FILE)

for (( i=0; i<$SERVICE_COUNT; i++ ))
do
  NAME=$(jq -r ".services[$i].name" $CONFIG_FILE)
  REPO=$(jq -r ".services[$i].repo" $CONFIG_FILE)
  DIR=$(jq -r ".services[$i].dir" $CONFIG_FILE)

  if [ ! -d "$DIR" ] || [ -z "$(ls -A $DIR)" ]; then
    echo "📥 Cloning $NAME..."
    git clone "$REPO" "$DIR"
  else
    echo "✅ $NAME already exists. Skipping."
  fi
done

echo ""
echo "🔥 All repositories processed."