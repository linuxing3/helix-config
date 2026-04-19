#!/usr/bin/env bash
set -euo pipefail

HELIX_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

GIT_ROOT="$TMP_ROOT/project"
NESTED_DIR="$GIT_ROOT/nested/deeper"
NON_GIT_DIR="$TMP_ROOT/non-git"

mkdir -p "$NESTED_DIR" "$NON_GIT_DIR"
git -C "$GIT_ROOT" init -q

TEST_SCM="$TMP_ROOT/recentf-paths-test.scm"
cat > "$TEST_SCM" <<SCM
(require "/home/Designers/.config/helix/cogs/recentf-paths.scm")

(define (assert-equal label actual expected)
  (unless (equal? actual expected)
    (error (string-append label ": expected " expected ", got " actual))))

(define home (canonicalize-path "~"))
(assert-equal "git root detection"
              (find-git-root-for "$NESTED_DIR")
              "$GIT_ROOT")
(assert-equal "repo storage root"
              (recentf-storage-root-for "$NESTED_DIR")
              "$GIT_ROOT")
(assert-equal "repo recentf file"
              (recentf-default-file-for "$NESTED_DIR")
              "$GIT_ROOT/.helix/recent-files.txt")
(assert-equal "non-git fallback root"
              (recentf-storage-root-for "$NON_GIT_DIR")
              home)
(assert-equal "non-git fallback file"
              (recentf-default-file-for "$NON_GIT_DIR")
              (string-append home "/.helix/recent-files.txt"))

(displayln "recentf path tests passed")
SCM

cd "$HELIX_DIR"
steel "$TEST_SCM"
