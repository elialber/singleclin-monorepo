# .claude/hooks/check_compile_and_fix.sh

#!/usr/bin/env bash

cd "$CLAUDE_PROJECT_DIR"

npm install

if ! npm run build:all; then
  claude code run compile_fixer
  exit 1
fi

cd packages/backend
if ! dotnet build --no-incremental; then
  claude code run compile_fixer
  exit 1
fi

cd ../mobile
if ! flutter analyze; then
  claude code run compile_fixer
  exit 1
fi
