#!/usr/bin/env bash
# The pre-commit gate. The checks live in verify-source.sh; this entry point is the stable command.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
case "${1:-}" in
  --self-test) bash "$ROOT/Scripts/verify-source.sh" --self-test ;;
  "") bash "$ROOT/Scripts/verify-source.sh" ;;
  *) echo "Usage: $0 [--self-test]" >&2; exit 2 ;;
esac
