# Professional Procrastination Management System™ (PPMS) — Edisi Kebun Sawit

> *"Turning Today's Urgent Deadlines Into Next Month's Regrets!"*

A 100% functional, persistent, menu-driven and CLI-capable **Task Manager** written in [**SawitLang**](https://github.com/RedStoneCraftGG/SawitLang) (`.sawit` / `.sawitpp`), the satirical Indonesian palm-oil bureaucracy programming language.

The presentation is a comedy parody of procrastination and +62 bureaucracy, while the underlying engine is a rock-solid, zero-warning native application featuring atomic file persistence, real calendar & leap-year validation, dynamic tracked heap allocation (`beli`/`jual`), and a 63-assertion automated QA test suite.

---

## 1. Project Directory Structure

```text
tugasnyawit/
├── .sawit-project            # SawitLang project metadata marker (v0.2)
├── AMDAL.txt                 # SawitLang CMake build spec (validated via `./sawit audit AMDAL.txt`)
├── CMakeLists.txt            # CMake wrapper including AMDAL.txt
├── SuratIzinTanam            # SawitLang Makefile alias (`buildAliases` in SawitLang)
├── Makefile                  # Standard Makefile wrapper delegating to SuratIzinTanam
├── sawit                     # Compiled SawitLang transpiler/runner binary (linux/amd64)
├── sawit_runtime.h           # Official SawitLang C/C++ runtime header
├── src/
│   └── main.sawit            # Complete Task Manager implementation in SawitLang
├── data/
│   └── .gitkeep              # Directory for persistent database (`data/tasks.sawitdb`)
├── tests/
│   └── run_tests.sh          # End-to-end automated QA test suite (63 assertions)
├── toolchain/                # Upstream SawitLang compiler source (Go)
│   ├── go.mod
│   ├── main.go
│   ├── main_test.go
│   └── sawit_runtime.h
├── LICENSE                   # MIT License
└── README.md                 # Documentation, usage guide, test report, & limitations
```

---

## 2. SawitLang Language & Runtime Overview

Inspection of [`RedStoneCraftGG/SawitLang`](https://github.com/RedStoneCraftGG/SawitLang) (`main.go` and `sawit_runtime.h`) reveals that **SawitLang** is a token-based source-to-source transpiler written in Go that translates `.sawit` files into C (`.c`) and `.sawitpp` files into C++ (`.cpp`), automatically injecting `#include "sawit_runtime.h"` and invoking `gcc`/`clang` or `g++`/`clang++`.

### SawitLang Keywords & Runtime Functions Used in `src/main.sawit`

| Category | SawitLang Keyword / Helper | Transpiled Target | Usage in PPMS™ Task Manager |
|---|---|---|---|
| **Types** | `tandan`, `pertalite`, `pertamax`, `buah`, `panen`, `rodok`, `hutan`, `pelepah` | `int`, `float`, `double`, `char`, `bool`, `bool`, `void`, `std::string` | Task IDs, priorities, completion percentages, strings, flags |
| **Control Flow** | `kalauPanen`, `kalauTidak`, `rapat`, `kasus`, `muter`, `selama`, `pidato`...`janji`, `pulang`, `lanjutPidato`, `lanjutOmonOmon`, `setor`, `relokasi` | `if`, `else`, `switch`, `case`, `for`, `while`, `do`...`while`, `break`, `continue`, `continue`, `return`, `goto` | Menu routing, validation loops, task filtering, date parsing |
| **Structures & OOP** | `kopdes`, `perkebunan`, `jalanProduksi`, `lahanPribadi`, `lahanPejabat`, `wilayahKebun`, `bakarHutan`, `gusur` | `struct`, `class`, `public`, `private`, `protected`, `namespace`, `new`, `delete` | `kopdes Tugas`, `kopdes ManajerTugas`, and S++ `AuditorKebun` |
| **Preprocessor & Entry** | `imporBibit`, `RUU`, `PerPres`, `sesuai`, `hoaks`, `panenUtama` | `#include`, `#define`, `#define`, `true`, `false`, `main` | Header imports, constants, boolean literals, program entry point |
| **I/O Runtime** | `buzzer(...)`, `demoMasyarakat(...)`, `bungkam(...)`, `bukaSuara(...)`, `bersihkanLayar()` | `sawit_buzzer`, `sawit_demo_masyarakat`, `sawit_bungkam`, `sawit_buka_suara`, `sawit_bersihkan_layar` | Formatted UI output, `[DEMO MASYARAKAT]` error alerts, silent censorship mode, Boss Key screen clear |
| **Memory & Ledger** | `beli(bytes)`, `jual(ptr)`, `MBG(amount)`, `cair(amount)`, `pajak(val, pct)`, `nyawit(fn)` | `sawit_beli`, `sawit_jual`, `sawit_mbg`, `sawit_cair`, `sawit_pajak`, `sawit_nyawit` | Dynamic task array reallocation, Procrastination Economy Ledger, function-pointer excuse generator |

---

## 3. Installation & Execution Instructions

### Prerequisites
- **GCC** (`gcc` / `g++`) or **Clang** (`clang` / `clang++`) installed on `PATH`.
- The prebuilt `./sawit` compiler binary is included in the repository root.
  *(To rebuild `sawit` from source if needed: `cd toolchain && go build -o ../sawit .`)*

### Option A: Run Directly with the SawitLang Toolchain (`./sawit run`)
```bash
# Launch the interactive menu-driven Task Manager
./sawit run src/main.sawit

# Or run direct CLI subcommands via `--`
./sawit run src/main.sawit -- help
./sawit run src/main.sawit -- add "Write quarterly report" "Stare at blank spreadsheet for 4 hours" high 2026-11-15
./sawit run src/main.sawit -- list
./sawit run src/main.sawit -- stats
```

### Option B: Compile a Standalone Native Binary (`./sawit build` or `make`)
```bash
# Build using SawitLang CLI or SuratIzinTanam / Makefile
make build
# (Equivalent to: ./sawit build src/main.sawit -o bin/tugasnyawit)

# Launch Interactive Menu Mode
./bin/tugasnyawit

# Or use CLI Subcommands
./bin/tugasnyawit add "Fix production bug" "Blame it on cosmic rays" high tomorrow
./bin/tugasnyawit add "Clean desk" "" low 2026-12-01
./bin/tugasnyawit list
./bin/tugasnyawit complete 1
./bin/tugasnyawit edit 2 "Clean desk eventually" "Shove everything into a drawer" medium 2026-12-15
./bin/tugasnyawit filter-status pending
./bin/tugasnyawit filter-priority medium
./bin/tugasnyawit search "drawer"
./bin/tugasnyawit stats
./bin/tugasnyawit delete 2
```

### Verify `AMDAL.txt` Build Configuration & Run Automated Tests
```bash
./sawit audit AMDAL.txt
make test
```

---

## 4. Application Features

1. **Task Creation (`Create New Task` / `add`)**
   - Assigns an auto-incrementing unique ID that persists across restarts.
   - Captures **Title** (required, validated non-empty) and **Description** (auto-populates with a sarcastic default if left blank).
   - Assigns **Priority**: `Low` (`1`), `Medium` (`2`), or `High` (`3`) — accepts numbers or words (`low`/`medium`/`high`, `l`/`m`/`h`, `rendah`/`sedang`/`tinggi`).
   - Assigns **Due Date**: validates real calendar dates in `YYYY-MM-DD` format (including leap-year rules for February 29) and supports shortcuts (`today`, `tomorrow`, `+7`/`next-week`, or `none`).
   - Credits the SawitLang `MBG()` emotional debt ledger and prints:
     - `"Congratulations! You've officially created another responsibility."`
     - `"URGENT! Your laziness has reached critical levels."` (for High priority tasks).

2. **Task Management (`View`, `Edit`, `Complete/Incomplete`, `Delete`, `Filter & Search`)**
   - **View All Tasks**: Displays ID, completion status (`[DONE]` / `[PENDING]`), priority badge, due date with live status (`[OVERDUE! PANIC!]`, `[DUE TODAY!]`, `[Upcoming]`), creation timestamp, title, and description.
     - Empty state displays: `"Nothing to do. Suspicious. Are you sure you're being productive?"`
     - Pending tasks trigger: `"Your future self would like to file a complaint."`
   - **Edit Task Details**: Modify title, description, priority, or due date individually (press `Enter` on any field to keep its current value).
   - **Mark Completed / Incomplete**: Toggle or explicitly set task status to Completed (`"Incredible. You actually did something. Scientists are investigating."` + disburses `cair()` reward) or Incomplete (`pajak()` penalty).
   - **Delete / Purge Tasks**: Delete a specific task by ID with `y/n` confirmation (`"Task eliminated. Your problems have been reduced by exactly one."`) or purge all completed tasks at once.
   - **Filter & Search**: Filter by status (`pending` / `completed`), priority (`low` / `medium` / `high`), combined status + priority, overdue/due-today status, or case-insensitive keyword search across titles and descriptions.

3. **Task Statistics (`Task Statistics` / `stats`)**
   - Displays total tasks, completed tasks, and pending tasks.
   - Calculates exact completion and pending percentages (`pertamax` / `double` precision) with a 20-character ASCII progress bar (`[##########..........] 50.0%`).
   - Breaks down counts by priority (`HIGH`, `MEDIUM`, `LOW` — total, done, pending) and deadline status (`Overdue`, `Due Today`, `Upcoming`, `No Due Date`).
   - Displays the **SawitLang Procrastination Economy Ledger** (`MBG` allocated points, `cair` disbursed points, `pajak` tax penalties, and `pertalite` Laziness Index) plus an official diagnosis rank.

4. **Data Persistence (`data/tasks.sawitdb`)**
   - Automatically loads saved tasks on startup and persists every change immediately.
   - Escapes special characters (`|` -> `\p`, `\` -> `\\`, `\n` -> `\n`, `\r` -> `\r`) so arbitrary user text round-trips cleanly.
   - Uses **atomic writes** (`tasks.sawitdb.tmp` -> `fflush` -> `fclose` -> `rename` to `tasks.sawitdb`).
   - **Transactional honesty**: If saving to disk fails (e.g., read-only or invalid path), in-memory changes are rolled back immediately and `[DEMO MASYARAKAT] GAGAL SIMPAN` is reported on `stderr` — never pretending data was saved when it wasn't.

---

## 5. Summary of Tests Performed & Actual Results

The automated test suite (`tests/run_tests.sh`, run via `make test`) executes **63 end-to-end assertions** against the real SawitLang toolchain:

| Test Suite | What Was Tested | Result |
|---|---|---|
| **Suite 1: Toolchain & Build** | `./sawit audit AMDAL.txt`, `./sawit transpile`, `gcc -Wall -Wextra -Werror`, `g++ -Wall -Wextra -Werror`, `./sawit build`, `./sawit run` | **6 / 6 PASSED** |
| **Suite 2: Task Creation** | Creating Low/Medium/High priority tasks, `YYYY-MM-DD` & `tomorrow` due dates, empty description fallback, parody messages | **4 / 4 PASSED** |
| **Suite 3: Data Persistence** | Verifying `tasks.sawitdb` creation, reloading across separate process restarts, pipe `\|` character escaping, overdue detection | **6 / 6 PASSED** |
| **Suite 4: Complete / Uncomplete / Edit** | Marking completed, idempotent re-completion check, marking incomplete again, editing title/description/priority/due date & persisting | **7 / 7 PASSED** |
| **Suite 5: Filtering & Search** | Filtering by `completed`, `pending`, priority (`medium`), and case-insensitive substring search (`daydreaming`) | **8 / 8 PASSED** |
| **Suite 6: Task Statistics** | Verifying total count (`3`), completed (`1 / 33.33%`), pending (`2 / 66.67%`), and per-priority breakdown | **5 / 5 PASSED** |
| **Suite 7: Task Deletion** | Deleting task by ID, verifying parody output and recalculated stats (`2` total, `50.00%` done / `50.00%` pending) | **4 / 4 PASSED** |
| **Suite 8: Validation & Honesty** | Rejecting invalid priority, impossible date `2026-02-30`, non-leap `2026-02-29`, accepting leap `2028-02-29`, rejecting non-numeric ID `banana`, missing ID `999`, and verifying rollback + error when DB path `/proc/impossible_dir/tasks.sawitdb` is unwritable | **8 / 8 PASSED** |
| **Suite 9: Dynamic Heap (`beli`/`jual`)** | Creating 21 tasks (exceeding `KAPASITAS_AWAL = 16`) to verify tracked heap reallocation and persistence | **1 / 1 PASSED** |
| **Suite 10: Interactive Menu Simulation** | Full piped-stdin session exercising all menu options (`0`–`9`), invalid input recovery, >1500-char line draining, combined filters, `bungkam`/`bukaSuara`, `nyawit`, purge completed, and clean exit | **14 / 14 PASSED** |

**Total Automated QA Result:** `63 PASSED, 0 FAILED`

---

## 6. Known SawitLang Limitations & Workarounds

1. **Single-File Compilation Unit in `sawit build` / `sawit run`**
   - **Limitation**: In upstream `main.go`, `compile()` transpiles only a single `.sawit` file into a temporary directory (`.sawit-build-*/program.c`), writes `sawit_runtime.h` into that temp directory, and invokes the C compiler with `-I <tmpDir>` only. Relative `#include` directives to other `.sawit` files in `src/` are neither transpiled nor on the include path.
   - **Workaround**: `src/main.sawit` is architected as a clean, well-structured single-file compilation unit divided into 10 modular sections so `./sawit run src/main.sawit` and `./sawit build src/main.sawit` work out of the box without patching the upstream compiler.

2. **Unconditional Token Replacement Outside Strings/Comments**
   - **Limitation**: The SawitLang lexer replaces every identifier token matching its 36 keywords or 11 runtime functions regardless of syntactic context (e.g., naming a struct field `panen` or `tandan` transpiles to `bool` or `int`, causing a C syntax error).
   - **Workaround**: All struct fields, parameters, and local variables use descriptive compound identifiers (`statusSelesai`, `idTugas`, `daftarTugas`) that never collide with reserved SawitLang tokens.

3. **Executable Permission Bit on `sawit init`**
   - **Limitation**: Upstream `initProject()` copies the `sawit` binary using `os.Create()`, which defaults to `0644` permissions on Linux/macOS (missing `+x`).
   - **Workaround**: We set `chmod +x ./sawit` (`0755`) in the repository so `./sawit` can be executed directly.

4. **No Built-in Calendar or Database Library in `sawit_runtime.h`**
   - **Limitation**: `sawit_runtime.h` only provides console I/O wrappers, a tracked allocator (`beli`/`jual`), and an integer budget ledger (`MBG`/`cair`/`pajak`).
   - **Workaround**: Built a custom `YYYY-MM-DD` calendar validator (with leap-year calculation and `time.h` comparison) and an escaped, atomic-rename flat-file persistence engine (`SAWITDB_V1`) using standard C file I/O imported via `imporBibit`.
