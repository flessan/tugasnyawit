#!/usr/bin/env bash
# ============================================================================
# AUTOMATED END-TO-END QA TEST SUITE
# Professional Procrastination Management System™ (SawitLang Task Manager)
# ============================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SAWIT="./sawit"
SOURCE="src/main.sawit"
BIN="bin/tugasnyawit"
TEST_DB="tests/tmp_qa_tasks.sawitdb"

PASSED=0
FAILED=0

pass() {
    PASSED=$((PASSED + 1))
    printf "  [PASS] %s\n" "$1"
}

fail() {
    FAILED=$((FAILED + 1))
    printf "  [FAIL] %s\n" "$1"
    printf "         Reason: %s\n" "$2"
    exit 1
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local label="$3"
    if grep -Fq -- "$needle" <<<"$haystack"; then
        pass "$label"
    else
        printf "\n--- ACTUAL OUTPUT ---\n%s\n---------------------\n" "$haystack"
        fail "$label" "Expected output to contain: '$needle'"
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local label="$3"
    if ! grep -Fq -- "$needle" <<<"$haystack"; then
        pass "$label"
    else
        printf "\n--- ACTUAL OUTPUT ---\n%s\n---------------------\n" "$haystack"
        fail "$label" "Expected output NOT to contain: '$needle'"
    fi
}

cleanup() {
    rm -f "$TEST_DB" "$TEST_DB.tmp"
}
trap cleanup EXIT
cleanup

echo "=============================================================================="
echo " RUNNING SAWITLANG TASK MANAGER QA TEST SUITE"
echo "=============================================================================="

# ----------------------------------------------------------------------------
# 1. Toolchain & Compilation Tests
# ----------------------------------------------------------------------------
echo ""
echo "[Suite 1] SawitLang Toolchain, AMDAL Audit, Transpilation, & Compilation"

OUT_AUDIT="$($SAWIT audit AMDAL.txt 2>&1)"
assert_contains "$OUT_AUDIT" "AMDAL.txt: struktur valid." "AMDAL.txt passes ./sawit audit"

mkdir -p bin
$SAWIT transpile "$SOURCE" -o bin/transpiled_check.c
assert_contains "$(head -n 5 bin/transpiled_check.c)" '#include "sawit_runtime.h"' "Transpiler injects sawit_runtime.h"
gcc -Wall -Wextra -Werror bin/transpiled_check.c -I. -o bin/strict_c_check
pass "Transpiled C code compiles cleanly under gcc -Wall -Wextra -Werror"

g++ -Wall -Wextra -Werror -x c++ bin/transpiled_check.c -I. -o bin/strict_cpp_check
pass "Transpiled S++ code compiles cleanly under g++ -Wall -Wextra -Werror"
rm -f bin/transpiled_check.c bin/strict_c_check bin/strict_cpp_check

$SAWIT build "$SOURCE" -o "$BIN"
if [[ -x "$BIN" ]]; then
    pass "./sawit build produces executable binary at $BIN"
else
    fail "./sawit build binary check" "Binary $BIN not found or not executable"
fi

OUT_RUN="$($SAWIT run "$SOURCE" -- --db "$TEST_DB" list 2>&1)"
assert_contains "$OUT_RUN" "Nothing to do. Suspicious. Are you sure you're being productive?" "./sawit run executes src/main.sawit directly"

# ----------------------------------------------------------------------------
# 2. Task Creation & Parody Messaging
# ----------------------------------------------------------------------------
echo ""
echo "[Suite 2] Task Creation (Titles, Descriptions, Priorities, Due Dates, Special Chars)"

OUT_ADD1="$($BIN --db "$TEST_DB" add "File 5-year AMDAL report" "Submit palm oil environmental paperwork | Form #62" high 2026-01-15 2>&1)"
assert_contains "$OUT_ADD1" "Congratulations! You've officially created another responsibility." "Add task displays official parody congratulations"
assert_contains "$OUT_ADD1" "URGENT! Your laziness has reached critical levels." "High-priority task triggers URGENT laziness warning"

OUT_ADD2="$($BIN --db "$TEST_DB" add "Clean desk" "" low tomorrow 2>&1)"
assert_contains "$OUT_ADD2" "Task #2 (\"Clean desk\")" "Second task assigned auto-incremented ID #2"

OUT_ADD3="$($BIN --db "$TEST_DB" add "Attend meeting about meetings" "Pretend to take notes while daydreaming" medium 2026-12-31 2>&1)"
assert_contains "$OUT_ADD3" "Task #3 (\"Attend meeting about meetings\")" "Third task created with medium priority and future due date"

# ----------------------------------------------------------------------------
# 3. Data Persistence Across Application Restarts
# ----------------------------------------------------------------------------
echo ""
echo "[Suite 3] Data Persistence Across Restarts"

if [[ -f "$TEST_DB" ]]; then
    pass "Database file $TEST_DB created on disk"
else
    fail "Database file existence" "$TEST_DB was not created"
fi

OUT_LIST="$($BIN --db "$TEST_DB" list 2>&1)"
assert_contains "$OUT_LIST" "File 5-year AMDAL report" "Task #1 title persisted across restart"
assert_contains "$OUT_LIST" "Submit palm oil environmental paperwork | Form #62" "Task #1 description with pipe '|' character escaped and restored accurately"
assert_contains "$OUT_LIST" "Too lazy to write a description." "Task #2 empty description replaced with funny default and persisted"
assert_contains "$OUT_LIST" "[OVERDUE! PANIC!]" "Past due date (2026-01-15) accurately flagged as OVERDUE"
assert_contains "$OUT_LIST" "Your future self would like to file a complaint." "Pending task warning displayed"

# ----------------------------------------------------------------------------
# 4. Task Completion, Uncompletion, & Edit Operations
# ----------------------------------------------------------------------------
echo ""
echo "[Suite 4] Task Completion, Re-opening, and Editing"

OUT_DONE="$($BIN --db "$TEST_DB" complete 1 2>&1)"
assert_contains "$OUT_DONE" "Incredible. You actually did something. Scientists are investigating." "Completing task #1 prints required parody message"

OUT_DONE_AGAIN="$($BIN --db "$TEST_DB" complete 1 2>&1)"
assert_contains "$OUT_DONE_AGAIN" "ALREADY completed" "Re-completing already completed task is handled gracefully"

OUT_UNDONE="$($BIN --db "$TEST_DB" uncomplete 1 2>&1)"
assert_contains "$OUT_UNDONE" "marked as INCOMPLETE again" "Task #1 can be marked incomplete again"

# Complete task #1 again for subsequent filter/stats tests
$BIN --db "$TEST_DB" complete 1 >/dev/null

OUT_EDIT="$($BIN --db "$TEST_DB" edit 2 "Clean desk eventually" "Shove papers into drawer" high 2026-11-20 2>&1)"
assert_contains "$OUT_EDIT" "History has been successfully rewritten! Task #2 (\"Clean desk eventually\") updated." "Editing task #2 updates fields and persists"

OUT_LIST_AFTER_EDIT="$($BIN --db "$TEST_DB" list 2>&1)"
assert_contains "$OUT_LIST_AFTER_EDIT" "Clean desk eventually" "Edited title persisted after restart"
assert_contains "$OUT_LIST_AFTER_EDIT" "Shove papers into drawer" "Edited description persisted after restart"
assert_contains "$OUT_LIST_AFTER_EDIT" "2026-11-20" "Edited due date persisted after restart"

# ----------------------------------------------------------------------------
# 5. Filtering & Searching Tasks
# ----------------------------------------------------------------------------
echo ""
echo "[Suite 5] Task Filtering (by Status, by Priority, and Keyword Search)"

OUT_FILT_DONE="$($BIN --db "$TEST_DB" filter-status completed 2>&1)"
assert_contains "$OUT_FILT_DONE" "File 5-year AMDAL report" "Completed filter includes completed task #1"
assert_not_contains "$OUT_FILT_DONE" "Clean desk eventually" "Completed filter excludes pending task #2"

OUT_FILT_PEND="$($BIN --db "$TEST_DB" filter-status pending 2>&1)"
assert_contains "$OUT_FILT_PEND" "Clean desk eventually" "Pending filter includes pending task #2"
assert_not_contains "$OUT_FILT_PEND" "File 5-year AMDAL report" "Pending filter excludes completed task #1"

OUT_FILT_MED="$($BIN --db "$TEST_DB" filter-priority medium 2>&1)"
assert_contains "$OUT_FILT_MED" "Attend meeting about meetings" "Priority filter (medium) includes task #3"
assert_not_contains "$OUT_FILT_MED" "Clean desk eventually" "Priority filter (medium) excludes high-priority task #2"

OUT_SEARCH="$($BIN --db "$TEST_DB" search "daydreaming" 2>&1)"
assert_contains "$OUT_SEARCH" "Attend meeting about meetings" "Case-insensitive keyword search matches description"
assert_not_contains "$OUT_SEARCH" "File 5-year AMDAL report" "Keyword search excludes non-matching tasks"

# ----------------------------------------------------------------------------
# 6. Task Statistics & Completion Percentages
# ----------------------------------------------------------------------------
echo ""
echo "[Suite 6] Task Statistics & Percentage Calculations"

OUT_STATS="$($BIN --db "$TEST_DB" stats 2>&1)"
assert_contains "$OUT_STATS" "Total Tasks Created      : 3" "Statistics reports exact total tasks (3)"
assert_contains "$OUT_STATS" "Completed Tasks          : 1 (33.33%)" "Statistics calculates exact completed percentage (33.33%)"
assert_contains "$OUT_STATS" "Pending Tasks            : 2 (66.67%)" "Statistics calculates exact pending percentage (66.67%)"
assert_contains "$OUT_STATS" "HIGH Priority        : 2 total (1 done, 1 pending)" "Statistics breaks down High priority counts accurately"
assert_contains "$OUT_STATS" "MEDIUM Priority      : 1 total (0 done, 1 pending)" "Statistics breaks down Medium priority counts accurately"

# ----------------------------------------------------------------------------
# 7. Task Deletion
# ----------------------------------------------------------------------------
echo ""
echo "[Suite 7] Task Deletion & Persistence"

OUT_DEL="$($BIN --db "$TEST_DB" delete 3 2>&1)"
assert_contains "$OUT_DEL" "Task eliminated. Your problems have been reduced by exactly one." "Deleting task #3 prints official parody deletion message"

OUT_STATS_AFTER_DEL="$($BIN --db "$TEST_DB" stats 2>&1)"
assert_contains "$OUT_STATS_AFTER_DEL" "Total Tasks Created      : 2" "Total tasks updated to 2 after deletion"
assert_contains "$OUT_STATS_AFTER_DEL" "Completed Tasks          : 1 (50.00%)" "Completion percentage updated to 50.00%"
assert_contains "$OUT_STATS_AFTER_DEL" "Pending Tasks            : 1 (50.00%)" "Pending percentage updated to 50.00%"

# ----------------------------------------------------------------------------
# 8. Input Validation, Leap Year, Edge Cases, & Persistence Honesty
# ----------------------------------------------------------------------------
echo ""
echo "[Suite 8] Input Validation, Error Handling, & Transactional Honesty"

OUT_BAD_PRIO="$($BIN --db "$TEST_DB" add "Invalid Priority Task" "Desc" ultra-mega 2026-11-01 2>&1 || true)"
assert_contains "$OUT_BAD_PRIO" "[DEMO MASYARAKAT]" "Invalid priority rejected with [DEMO MASYARAKAT] error"

OUT_BAD_DATE1="$($BIN --db "$TEST_DB" add "Impossible Feb 30" "Desc" low 2026-02-30 2>&1 || true)"
assert_contains "$OUT_BAD_DATE1" "[DEMO MASYARAKAT]" "Impossible calendar date 2026-02-30 rejected"

OUT_BAD_DATE2="$($BIN --db "$TEST_DB" add "Non-leap year Feb 29" "Desc" low 2026-02-29 2>&1 || true)"
assert_contains "$OUT_BAD_DATE2" "[DEMO MASYARAKAT]" "Non-leap-year 2026-02-29 rejected"

OUT_LEAP_OK="$($BIN --db "$TEST_DB" add "Leap Year Task" "Valid Feb 29 in 2028" low 2028-02-29 2>&1)"
assert_contains "$OUT_LEAP_OK" "Congratulations!" "Valid leap-year date 2028-02-29 accepted"

OUT_BAD_ID="$($BIN --db "$TEST_DB" complete banana 2>&1 || true)"
assert_contains "$OUT_BAD_ID" "bukan angka yang valid" "Non-numeric task ID 'banana' rejected gracefully"

OUT_MISSING_ID="$($BIN --db "$TEST_DB" delete 999 2>&1 || true)"
assert_contains "$OUT_MISSING_ID" "tidak ditemukan" "Non-existent task ID #999 rejected gracefully"

OUT_UNWRITABLE="$($BIN --db "/proc/impossible_dir/tasks.sawitdb" add "Should Fail Save" "Desc" low NONE 2>&1 || true)"
assert_contains "$OUT_UNWRITABLE" "GAGAL SIMPAN" "Unwritable database path reports GAGAL SIMPAN error honestly"
assert_not_contains "$OUT_UNWRITABLE" "Congratulations!" "Unwritable save never pretends task creation succeeded"

# ----------------------------------------------------------------------------
# 9. Dynamic Heap Reallocation (>16 tasks via beli/jual)
# ----------------------------------------------------------------------------
echo ""
echo "[Suite 9] Dynamic Memory Expansion (beli/jual beyond initial capacity of 16)"

for i in $(seq 1 18); do
    $BIN --db "$TEST_DB" add "Bulk Task $i" "Testing dynamic heap expansion via beli()" low NONE >/dev/null
done
OUT_BULK_STATS="$($BIN --db "$TEST_DB" stats 2>&1)"
assert_contains "$OUT_BULK_STATS" "Total Tasks Created      : 21" "All 21 tasks stored and persisted across dynamic heap reallocation"

# ----------------------------------------------------------------------------
# 10. Interactive Menu Mode End-to-End Simulation (Piped Stdin)
# ----------------------------------------------------------------------------
echo ""
echo "[Suite 10] Full Interactive Menu Session Simulation"

rm -f "$TEST_DB"
INTERACTIVE_INPUT=$(cat <<'EOF'

invalid_menu_text
99
1
2
Interactive Task Alpha
Created inside interactive menu
invalid_priority
high
2026-02-30
2026-12-15
3
1
Interactive Task Alpha (Edited)

low
2026-12-20
4
1
1
6
2
7
8
1
8
2
8
3
8
4
5
1
1
y
1
0
EOF
)

OUT_INTERACTIVE="$($BIN --db "$TEST_DB" <<<"$INTERACTIVE_INPUT" 2>&1)"
assert_contains "$OUT_INTERACTIVE" "Professional Procrastination Management System™" "Interactive mode displays application title banner"
assert_contains "$OUT_INTERACTIVE" "Input 'invalid_menu_text' bukan angka menu yang sah!" "Interactive menu validates non-numeric menu input"
assert_contains "$OUT_INTERACTIVE" "Menu #99 tidak terdaftar!" "Interactive menu validates out-of-range menu number"
assert_contains "$OUT_INTERACTIVE" "Prioritas 'invalid_priority' tidak valid!" "Interactive task creation re-prompts on invalid priority"
assert_contains "$OUT_INTERACTIVE" "Tanggal '2026-02-30' tidak sah!" "Interactive task creation re-prompts on invalid calendar date"
assert_contains "$OUT_INTERACTIVE" "History has been successfully rewritten! Task #1 updated." "Interactive task editing updates task"
assert_contains "$OUT_INTERACTIVE" "Incredible. You actually did something. Scientists are investigating." "Interactive completion marks task done"
assert_contains "$OUT_INTERACTIVE" "bukaSuara(stdout) berhasil!" "Interactive Sawit Bureaucracy Lab tests bungkam/bukaSuara"
assert_contains "$OUT_INTERACTIVE" "Task eliminated. Your problems have been reduced by exactly one." "Interactive task deletion removes task #1"
assert_contains "$OUT_INTERACTIVE" "[SAVE OK] All 0 task(s) safely persisted" "Interactive exit saves state cleanly"

# Test interactive combined filter, overdue filter, keyword search, purge completed, and oversized line handling
LONG_LINE="$(python3 -c 'print("A" * 1500)')"
INTERACTIVE_ADV=$(cat <<EOF
2
Overdue High Task
Needs urgent panic
3
2026-01-10
2
Done Low Task
Already finished somehow
1
NONE
4
2
1
6
4
1
3
6
5
6
6
panic
$LONG_LINE
5
2
0
EOF
)

OUT_ADV="$($BIN --db "$TEST_DB" <<<"$INTERACTIVE_ADV" 2>&1)"
assert_contains "$OUT_ADV" "Overdue High Task" "Interactive combined filter (Pending + High) & Overdue filter locate matching task"
assert_contains "$OUT_ADV" "bukan angka menu yang sah!" "Oversized (>1500 chars) input line drained safely without corrupting subsequent menu inputs"
assert_contains "$OUT_ADV" "Evidence of your productivity has been cleanly shredded." "Interactive purge completed tasks removes only completed tasks"
assert_contains "$OUT_ADV" "[SAVE OK] All 1 task(s) safely persisted" "Remaining pending task preserved after purging completed tasks"

echo ""
echo "=============================================================================="
printf " ALL QA TESTS COMPLETED: %d PASSED, %d FAILED\n" "$PASSED" "$FAILED"
echo "=============================================================================="
