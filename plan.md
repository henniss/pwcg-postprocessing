# Bugfix plan

Scope: **bugfixes only**, kept as conservative as possible — minimal diffs,
no behavior changes beyond correcting the specific defect, no refactors, no
new features. Candidates from `research.md` that would require a judgment
call about *new* intended behavior (rather than restoring the clearly-intended
behavior) are listed at the bottom as explicitly **not planned**, with the
reasoning for leaving them alone.

Each fix below has been verified against the actual code/shell semantics
(not just inferred from reading) before being included.

---

## Fix 1 — Backup/restore never actually backs up or restores anything

**File:** `core.sh` (lines 186, 197, 198)
**Severity:** High. This is the tool's entire safety net — "make a backup
before touching the mission, restore it if a component fails" — and it is
currently a no-op.

**Root cause:** `missionBase` is set once, early, from the *original dragged
file's* basename, extension included (e.g. `Foo.mission`, or `_Foo.mission`
for the underscore-rerun workflow). It is never updated. `makeBackup` and
`restoreBackup` both glob on `"${missionBase}".*` (e.g. pattern
`Foo.mission.*`), intending to catch every sibling file of the mission
(`Foo.mission`, `Foo.eng`, ...). But because `missionBase` already contains
the `.mission` extension, the glob requires a *literal second dot* after
`.mission`, which no real file has. Confirmed empirically:

```
$ bash -c 'missionBase="Foo.mission"; for x in "${missionBase}".*; do echo "$x"; done'
Foo.mission.*          # unexpanded — no match, passed through literally
```

versus the pattern that's actually needed (what `missionCore#_` already
correctly resolves to elsewhere in the same file, e.g. the `mission=`/
`subtitles=` assignments):

```
$ bash -c 'missionCore="Foo"; for x in "${missionCore}".*; do echo "$x"; done'
Foo.eng
Foo.mission
```

So today, every call:
- `makeBackup`'s `cp "${mdir}/${missionBase}".* "${backups}"` fails with
  "No such file or directory" and copies nothing.
- `restoreBackup`'s `mv "${mdir}/${missionBase}".* "${trash}"` and
  `cp -n -f "${backups}/${missionBase}".* "${mdir}"` both fail the same way
  — the corrupted/partially-processed mission is never moved aside, and the
  backup (which doesn't exist anyway) is never copied back.

Both functions run as `( set -e; ... )` subshells whose exit status is never
checked by the caller, and the caller is in `set +e` at every call site, so
none of this surfaces as a hard failure — only a `cp`/`mv` stderr line that
looks like routine noise. This also explains why `test.sh` always sets
`NO_RESTORE=true`: the one path that would exercise `restoreBackup` is
disabled in the test harness, so this has never been caught by testing.

**Fix:** Replace `${missionBase}` with `${missionCore#_}` (the existing,
already-correct "basename without extension, without leading underscore"
expression used two lines above for `mission=`/`subtitles=`) at the three
glob sites:

- `makeBackup`: `cp "${mdir?}/${missionBase?}".* "${backups?}"` →
  `cp "${mdir?}/${missionCore#_}".* "${backups?}"`
- `restoreBackup`: `mv "${mdir?}/${missionBase?}".* "${trash}"` →
  `mv "${mdir?}/${missionCore#_}".* "${trash}"`
- `restoreBackup`: `cp -n -f "${backups?}/${missionBase?}".* "${mdir?}"` →
  `cp -n -f "${backups?}/${missionCore#_}".* "${mdir?}"`

No other variable, control flow, or script is touched. `missionBase` is
still used as before for the campaign-name extraction (line 115), which is
unaffected.

**Risk:** Very low. This only changes which files a glob matches; the
intended set of files (the mission's own siblings) is unchanged from what
the surrounding code already clearly intends (it's the same expression used
two lines later in the same file for the same purpose).

**Verification plan:**
1. In a scratch campaign directory, create a dummy `Foo.mission`/`Foo.eng`
   pair, run the pipeline up through `makeBackup`, and confirm
   `backups/Foo.mission` and `backups/Foo.eng` now actually appear (they do
   not today).
2. Force a component to fail (e.g. temporarily make a component's `apply`
   return 1) and confirm `restoreBackup` now actually moves the modified
   files to `trash/` and copies the backup back into place, leaving the
   mission byte-identical to its pre-run state (it does not today).
3. Re-run `test.sh` (which still passes `NO_RESTORE=true`, so this is just a
   regression check that normal processing is unaffected) to confirm nothing
   else broke.

---

## Fix 2 — Underscore-rerun file globs over-match and warn spuriously

**File:** `core.sh` (lines 94–102)
**Severity:** Low/moderate. Only affects the manual "drop a `_Foo.mission`
to re-apply edits" workflow (`test.sh`/history commit `3a92ccc`), not normal
drag-and-drop use.

**Root cause:**
```bash
if [[ $missionCore =~ ^_.* ]]; then
    rm "${missionDir}/${missionCore#_}"*
    for f in "${missionDir}/${missionCore}"*; do
        ...
    done
fi
```
Both globs are **unanchored prefix matches** (no delimiter between the core
name and the trailing `*`). Two concrete problems:

1. If the campaign directory contains another file whose name happens to
   start with the same text (e.g. processing `Foo` while a `Foo 2.mission`
   sits in the same directory — plausible, since PWCG missions are often
   sequentially named), `rm "${missionDir}/Foo"*` deletes it too, and the
   `for f in "${missionDir}/_Foo"*` loop can likewise pick up and overwrite
   unrelated underscore-prefixed files.
2. On the very first use (no pre-existing non-underscored `Foo.*` yet), the
   `rm` glob doesn't match anything; since `nullglob` isn't set, bash passes
   the literal unexpanded pattern to `rm`, which prints a "No such file or
   directory" error every time — harmless, but looks like a real failure.

**Fix:** Anchor both globs on a literal trailing dot, matching the same
"basename then a dot then an extension" shape used correctly elsewhere in
this file, and guard the `rm` so it's simply skipped when there's nothing to
remove:

```bash
if [[ $missionCore =~ ^_.* ]]; then
    echo "stripping leading underscore from filename"
    shopt -s nullglob
    old=( "${missionDir}/${missionCore#_}".* )
    shopt -u nullglob
    (( ${#old[@]} > 0 )) && rm "${old[@]}"
    for f in "${missionDir}/${missionCore}".*; do
        echo "$f"
        x="$(basename "${f}")"
        cp "${missionDir}/${x}" "${missionDir}/${x#_}"
    done
fi
```

Only two things change: a literal `.` is added before each trailing `*` (so
`Foo*` becomes `Foo.*`, matching only genuine `Foo.<ext>` siblings), and the
`rm` is pre-expanded into an array behind a scoped `nullglob` so it's a no-op
instead of an error when nothing matches yet. The loop body is untouched.

**Risk:** Low. For the only shape of input this feature is documented/used
with (a single `_Foo.mission` + `_Foo.eng` pair dropped next to the existing
`Foo.mission` + `Foo.eng`), the matched file sets before and after this
change are identical — the change only removes over-matching on unrelated
same-prefix files and the spurious first-run error.

**Verification plan:** Using `test.sh`-style fixtures, create `Foo.mission`/
`Foo.eng` plus an unrelated `Foo 2.mission` in the same scratch directory,
drop `_Foo.mission` (simulating a manual edit), and confirm only `Foo.*` is
replaced and `Foo 2.mission` is left untouched; also confirm no spurious `rm`
error appears on a fresh directory that has no pre-existing `Foo.*` yet.

---

## Fix 3 (optional — flagging for a decision, not assumed)

**File:** `components/05_timers.sh`
**Severity:** Low / unconfirmed. This is a latent risk spotted by reading the
code, not a defect I've reproduced against real data.

**Observation:** The player's and escort's own flights are excluded from
random takeoff-delay reassignment via a byte-exact `comm -3` diff between
flight names parsed out of the mission file and `$PLAYER_FLIGHT`/
`$ESCORT_FLIGHT` (parsed from the subtitle briefing text). Everywhere else in
this codebase, flight-name matching is treated as case-insensitive
(`shopt -s nocasematch`/`nocaseglob` in `core.sh`). If the mission's
`Name = "Flight X"` field and the subtitle's rendering of that same name
ever differ only in case (or incidental whitespace), `comm` would fail to
exclude it, and the player's own flight could be given a random delay —
exactly what this exclusion exists to prevent.

**Why I'm not including it by default:** I have no concrete evidence this
mismatch actually occurs with real PWCG output (both strings plausibly come
from the same underlying data in PWCG, so casing may always agree in
practice). A "conservative" fix here is also slightly less surgical than
Fixes 1–2: it requires case-folding the `comm` comparison *and* adding `-i`
to the later `grep -F` lookup that re-locates each eligible flight by name,
so two call sites move together.

**Proposed fix, if wanted:**
```bash
eligible="$(comm -3 <(tr '[:upper:]' '[:lower:]' < "$tempfile" | sort) \
                    <(echo "$exempt" | tr '[:upper:]' '[:lower:]' | sort))"
...
ln=$(grep -i -F -n -m 1 "Name = \"Flight $f\";" "${mission}" | cut -d ':' -f 1)
```
This folds case only for comparison purposes; it doesn't change what names
end up in `eligible` beyond fixing the exclusion check itself.

**Let me know whether to include this one** — happy to add it to the same
patch if you want full coverage, or leave it out if you'd rather not touch
code without a confirmed repro.

---

## Considered and explicitly NOT planned

To be clear about what's deliberately out of scope rather than overlooked:

- **`01_block_durability.sh` aborts the whole mission on one unrecognized
  block.** This looks harsh, but it's a deliberate fail-loud guard against
  silently applying a wrong/default durability value — "fixing" it means
  picking new behavior (skip the block? assume some default?), which isn't a
  conservative bugfix, it's a design decision.
- **`74_artillery.sh`'s "can still fire while being killed" bug and
  `04_escort.sh`'s "ECFCT_ID doesn't seem to work" comment.** Both are
  author-acknowledged issues in multi-step in-game MCU event timing. There's
  no code-reading-only fix available with confidence; resolving these
  requires in-game iteration the way the ~15 prior escort/artillery commits
  already did, and a wrong guess risks making mission logic silently worse.
- **Campaign-name detection** (`campaign=$(echo ${missionBase} | cut -d ' '
  -f 1)`) **silently falling back to "no campaign" for multi-word campaign
  names.** A real gap, but any fix changes matching behavior rather than
  restoring clearly-intended behavior, and risks changing campaign
  resolution for installs where it currently works by coincidence.
- **`PIPE=$(mktemp -u)` + `mkfifo` TOCTOU.** Technically a race condition,
  but irrelevant in this tool's actual threat model (local, single-user,
  no untrusted input); not worth touching.
- **`02_tac_codes.sh`'s unfinished dead-pilot-pruning / auto-assignment.**
  Explicitly called out in the script's own comments as a planned rework,
  not a bug — it's a missing feature, not incorrect behavior.

---

## Suggested order of work

1. Fix 1 (backup/restore) — highest value, lowest risk, do first.
2. Fix 2 (underscore-rerun globs) — small, independent, safe to bundle.
3. Decide on Fix 3 and either include it in the same pass or skip it.

All three fixes are independent of each other and can be applied as a single
small patch to `core.sh` (+ optionally `components/05_timers.sh`), tested via
`test.sh` plus the manual scenarios described above.
