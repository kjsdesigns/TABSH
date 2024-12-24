#!/usr/bin/env bash
#
# dump-repo.sh
#
# Usage:
#   1. Make executable: chmod +x dump-repo.sh
#   2. Run at repo root: ./dump-repo.sh
#
# It will generate a file named 'repo.txt' in the repo root with:
#   - The README.md content (if README.md is in the same directory as this script)
#   - A file/directory listing (only files tracked by Git)
#   - The content of all tracked .html, .css, and .js files

OUTPUT_FILE="repo.txt"

{
  echo "=== README.md CONTENT ==="
  if [ -f "./README.md" ]; then
    cat "./README.md"
  else
    echo "No README.md found in this directory."
  fi

  echo ""
  echo "=== REPO FILE STRUCTURE ==="

  echo "Directories:"
  # Take all version-controlled files, extract directory paths, sort uniquely
  git ls-files \
    | xargs -n1 dirname \
    | sort -u \
    | sed 's/^/  /'

  echo ""
  echo "Files:"
  # Directly list all version-controlled files
  git ls-files \
    | sed 's/^/  /'

  echo ""
  echo "=== FILE CONTENTS ==="

  # Iterate through all version-controlled .html, .css, and .js files
  git ls-files \
    | grep -E '\.(html|css|js)$' \
    | while read -r file; do
      echo "=== $file ==="
      cat "$file"
      echo ""
    done
} > "$OUTPUT_FILE"

echo "Output saved to $OUTPUT_FILE"