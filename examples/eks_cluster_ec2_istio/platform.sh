#!/bin/bash

PLATFORM_FOLDER="platform"

if [ ! -d "$PLATFORM_FOLDER" ]; then
  echo "[ERROR] PLATFORM_FOLDER directory does not exists"
  exit 1
fi

echo "platform deploy..."

for file in "$PLATFORM_FOLDER"/*; do
  if [[ $file =~ .*\.(yaml|yml)$ ]]; then
    echo "kubectl apply -f $file"
    kubectl apply -f "$file"
  fi
done

echo "platform script-deploy completed"