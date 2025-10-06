#!/usr/bin/env bash

set -euo pipefail

# Resolve project root based on script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Where we will stash intermediate outputs and the final report
REPORT_DIR="${PROJECT_ROOT}/build/auto_fix"
mkdir -p "${REPORT_DIR}"

BEFORE_ANALYZE="${REPORT_DIR}/analyze_before.txt"
DRY_RUN_OUTPUT="${REPORT_DIR}/dart_fix_dry_run.txt"
APPLY_OUTPUT="${REPORT_DIR}/dart_fix_apply.txt"
FORMAT_OUTPUT="${REPORT_DIR}/format_output.txt"
AFTER_ANALYZE="${REPORT_DIR}/analyze_after.txt"
ANALYZE_DIFF="${REPORT_DIR}/analyze_diff.txt"
SUMMARY_REPORT="${REPORT_DIR}/report.txt"

pushd "${PROJECT_ROOT}" >/dev/null

echo "[1/5] Running flutter analyze (pre-fix)"
ANALYZE_STATUS_BEFORE=0
if ! flutter analyze >"${BEFORE_ANALYZE}" 2>&1; then
  ANALYZE_STATUS_BEFORE=$?
fi

echo "[2/5] Running dart fix --dry-run"
if ! dart fix --dry-run >"${DRY_RUN_OUTPUT}" 2>&1; then
  echo "dart fix --dry-run failed; see ${DRY_RUN_OUTPUT}" >&2
  exit 1
fi

echo "[3/5] Applying dart fix"
if ! dart fix --apply >"${APPLY_OUTPUT}" 2>&1; then
  echo "dart fix --apply failed; see ${APPLY_OUTPUT}" >&2
  exit 1
fi

echo "[4/5] Formatting source files"
if ! dart format . >"${FORMAT_OUTPUT}" 2>&1; then
  echo "dart format failed; see ${FORMAT_OUTPUT}" >&2
  exit 1
fi

echo "[5/5] Running flutter analyze (post-fix)"
ANALYZE_STATUS_AFTER=0
if ! flutter analyze >"${AFTER_ANALYZE}" 2>&1; then
  ANALYZE_STATUS_AFTER=$?
fi

# Compute diff between analyze runs (ignore exit status)
if ! diff -u "${BEFORE_ANALYZE}" "${AFTER_ANALYZE}" >"${ANALYZE_DIFF}" 2>/dev/null; then
  : # diff returns non-zero for differences; that's expected
fi

# Capture current git status for context
GIT_STATUS="$(git status --short)"

{
  echo "=== SingleClin Mobile Auto Fix Report ==="
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%SZ')"
  echo
  echo "Flutter analyze (before) exit code: ${ANALYZE_STATUS_BEFORE}"
  echo "Output saved to: ${BEFORE_ANALYZE}"
  echo
  echo "Dart fix dry-run output: ${DRY_RUN_OUTPUT}"
  echo
  echo "Dart fix apply output: ${APPLY_OUTPUT}"
  echo
  echo "Format command output: ${FORMAT_OUTPUT}"
  echo
  echo "Flutter analyze (after) exit code: ${ANALYZE_STATUS_AFTER}"
  echo "Output saved to: ${AFTER_ANALYZE}"
  echo
  if [[ -s "${ANALYZE_DIFF}" ]]; then
    echo "Analyze diff (before -> after) stored at: ${ANALYZE_DIFF}"
  else
    echo "Analyze diff: no changes detected"
  fi
  echo
  echo "Git status snapshot after fixes:"
  if [[ -n "${GIT_STATUS}" ]]; then
    echo "${GIT_STATUS}"
  else
    echo "  (clean)"
  fi
} >"${SUMMARY_REPORT}"

popd >/dev/null

echo
echo "Automation complete. Summary report saved to: ${SUMMARY_REPORT}"
echo "Inspect intermediate files in: ${REPORT_DIR}"
