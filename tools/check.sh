#!/usr/bin/env bash
# Enforces the Zone-C architecture rules (see 2026-09-17-zone-c-design.md, section 2.5).
set -uo pipefail

cd "$(dirname "$0")/.."

failures=0

fail() {
    echo "FAIL $1"
    printf '%s\n' "$2" | sed 's/^/     /'
    failures=$((failures + 1))
}

pass() {
    echo "ok   $1"
}

qml_files() {
    find core features shell.qml -name '*.qml' 2>/dev/null
}

# R1: only *Service.qml files and core/services may run external commands.
r1=$(grep -nE '\bProcess\s*\{|execDetached|hyprctl' $(qml_files) \
    | grep -vE '^(core/services/|features/[^/]+/[A-Za-z]+Service\.qml:)')
[ -z "$r1" ] && pass "R1 commands only in services" || fail "R1 commands only in services" "$r1"

# R2: no hard-coded colours outside core/theme.
r2=$(grep -nE '"#[0-9a-fA-F]{3,8}"|Qt\.rgba\(\s*[0-9.]' $(qml_files) | grep -v '^core/theme/')
[ -z "$r2" ] && pass "R2 colours come from Colours" || fail "R2 colours come from Colours" "$r2"

# R3: raw config access only in core/config.
r3=$(grep -nE 'shell\.json|Config\.raw\b' $(qml_files) | grep -v '^core/config/')
[ -z "$r3" ] && pass "R3 typed config access" || fail "R3 typed config access" "$r3"

# R4: core never imports features; a feature never imports another feature.
# shell.qml is exempt: it has to import every feature module so that Quickshell
# registers them for the files it later loads by URL (see the comment there).
r4a=$(grep -rnE 'import\s+qs\.features' core 2>/dev/null)
r4b=""
for dir in features/*/; do
    name=$(basename "$dir")
    hits=$(grep -rnE "import\s+qs\.features\.|import\s+\"\.\./" "$dir" 2>/dev/null \
        | grep -vE "import\s+qs\.features\.${name}\s*$")
    [ -n "$hits" ] && r4b+="$hits"$'\n'
done
r4="${r4a}${r4b}"
r4="${r4%$'\n'}"
[ -z "$r4" ] && pass "R4 feature isolation" || fail "R4 feature isolation" "$r4"

# R5: QML files stay at or under 400 lines.
r5=$(for f in $(qml_files); do
    lines=$(wc -l < "$f")
    [ "$lines" -gt 400 ] && echo "$f: $lines lines"
done)
[ -z "$r5" ] && pass "R5 files <= 400 lines" || fail "R5 files <= 400 lines" "$r5"

# R6 + unit tests: feature contract and pure logic.
if command -v node >/dev/null 2>&1; then
    if out=$(node --test "tests/js/**/*.test.mjs" 2>&1); then
        pass "R6 feature contracts + unit tests ($(printf '%s\n' "$out" | grep -oE '^ℹ pass [0-9]+' | grep -oE '[0-9]+') passed)"
    else
        fail "R6 feature contracts + unit tests" "$(printf '%s\n' "$out" | grep -E '✖|not ok|Error' | head -20)"
    fi
else
    fail "R6 feature contracts + unit tests" "node is not installed"
fi

# R7: qmllint, when available. Informational: Quickshell types are not always resolvable by qmllint.
qmllint_bin=$(command -v qmllint6 || command -v qmllint || ls /usr/lib/qt6/bin/qmllint 2>/dev/null)
if [ -n "${qmllint_bin:-}" ]; then
    if lint=$("$qmllint_bin" $(qml_files) 2>&1); then
        pass "R7 qmllint"
    else
        echo "warn R7 qmllint reported issues (not fatal):"
        printf '%s\n' "$lint" | grep -E '^(Error|Warning)' | head -20 | sed 's/^/     /'
    fi
else
    echo "skip R7 qmllint not installed"
fi

echo
if [ "$failures" -eq 0 ]; then
    echo "All checks passed."
else
    echo "$failures check(s) failed."
    exit 1
fi
