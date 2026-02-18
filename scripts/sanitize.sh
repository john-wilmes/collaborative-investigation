#!/usr/bin/env bash
set -euo pipefail

# PHI sanitization using Microsoft Presidio.
# Processes files in-place, replacing patient PHI with typed placeholders.
# Customer/org info is intentionally kept.
#
# Usage: scripts/sanitize.sh <file> [file...]
# Called by .githooks/pre-commit on staged BRIEF.md and FINDINGS.md files.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PRESIDIO_CONFIG="$ROOT_DIR/schemas/presidio.yaml"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <file> [file...]" >&2
    exit 1
fi

# Check if Presidio is available
if ! command -v presidio-analyzer &>/dev/null || ! command -v presidio-anonymizer &>/dev/null; then
    echo "Warning: Presidio not installed. Skipping PHI sanitization." >&2
    echo "Install with: pip install presidio-analyzer presidio-anonymizer" >&2
    exit 0
fi

CHANGED=0

for FILE in "$@"; do
    if [ ! -f "$FILE" ]; then
        continue
    fi

    # Run Presidio analyzer + anonymizer on the file
    # Uses the project's presidio.yaml for configuration
    ORIGINAL_HASH=$(sha256sum "$FILE" | cut -d' ' -f1)

    python3 -c "
import sys
import yaml
from presidio_analyzer import AnalyzerEngine, PatternRecognizer, Pattern
from presidio_anonymizer import AnonymizerEngine
from presidio_anonymizer.entities import OperatorConfig

# Load config
with open('$PRESIDIO_CONFIG', 'r') as f:
    config = yaml.safe_load(f)

# Set up analyzer
analyzer = AnalyzerEngine()

# Add custom MRN recognizer if configured
for custom in config.get('analyzer', {}).get('custom_recognizers', []):
    patterns = [Pattern(p['name'], p['regex'], p['score']) for p in custom.get('patterns', [])]
    recognizer = PatternRecognizer(
        supported_entity=custom['supported_entity'],
        patterns=patterns,
        context=custom.get('context', [])
    )
    analyzer.registry.add_recognizer(recognizer)

# Read file
with open('$FILE', 'r', encoding='utf-8') as f:
    text = f.read()

# Analyze
entities = config.get('analyzer', {}).get('recognizers', [])
results = analyzer.analyze(text=text, entities=entities, language='en')

if not results:
    sys.exit(0)

# Build operator config from yaml
operators = {}
for entity, op in config.get('anonymizer', {}).get('operators', {}).items():
    operators[entity] = OperatorConfig(op['type'], {'new_value': op['new_value']})

# Anonymize
anonymizer = AnonymizerEngine()
anonymized = anonymizer.anonymize(text=text, analyzer_results=results, operators=operators)

# Write back
with open('$FILE', 'w', encoding='utf-8') as f:
    f.write(anonymized.text)
" 2>/dev/null || true

    NEW_HASH=$(sha256sum "$FILE" | cut -d' ' -f1)
    if [ "$ORIGINAL_HASH" != "$NEW_HASH" ]; then
        echo "Sanitized PHI in: $FILE"
        CHANGED=1
    fi
done

exit 0
