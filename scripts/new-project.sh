#!/usr/bin/env bash
set -euo pipefail

# Creates a new investigation project from templates.
# Usage: scripts/new-project.sh <ticket-id>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCHEMAS_DIR="$ROOT_DIR/schemas"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <ticket-id>" >&2
    exit 1
fi

TICKET_ID="$1"
PROJECT_DIR="$ROOT_DIR/PROJECTS/$TICKET_ID"

if [ -d "$PROJECT_DIR" ]; then
    echo "Error: Project $TICKET_ID already exists at $PROJECT_DIR" >&2
    exit 1
fi

# Create project structure
mkdir -p "$PROJECT_DIR/EVIDENCE"

# Copy and fill templates
sed "s/{{TICKET_ID}}/$TICKET_ID/g" "$SCHEMAS_DIR/brief.template.md" > "$PROJECT_DIR/BRIEF.md"
sed "s/{{TICKET_ID}}/$TICKET_ID/g" "$SCHEMAS_DIR/findings.template.md" > "$PROJECT_DIR/FINDINGS.md"

# Create STATUS.md
cat > "$PROJECT_DIR/STATUS.md" << EOF
# Status: $TICKET_ID

## Current Hypothesis
<!-- Updated after each session -->

## Open Questions
-

## Next Action
<!-- What the next session should do first -->

## History
| Date | Phase | Summary |
|------|-------|---------|
| $(date +%Y-%m-%d) | init | Project created from template |
EOF

# Create git branch (redirect stderr to stdout -- git checkout writes
# success messages to stderr which causes false failures on Windows Git)
cd "$ROOT_DIR"
git checkout -b "inv/$TICKET_ID" 2>&1 || git checkout "inv/$TICKET_ID" 2>&1

echo "Created investigation project: $PROJECT_DIR"
echo "Branch: inv/$TICKET_ID"
echo ""
echo "Next steps:"
echo "  1. Fill in PROJECTS/$TICKET_ID/BRIEF.md (10 lines max)"
echo "  2. Run /collect $TICKET_ID to start gathering evidence"
