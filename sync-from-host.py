#!/usr/bin/env python3
"""Pull PrimeCouncil framework changes from a host project repo back into this kit.

The kit is the canonical home of the framework, but the framework gets IMPROVED inside whichever
project is actually using it. This script moves those improvements back, without the two things
that quietly wreck a kit:

  1. **Line-ending churn.** A host repo on Windows checks files out CRLF; the kit may hold LF.
     Copying bytes across would rewrite every line of every file and bury the real change in a
     diff nobody can read. Each file is written back with the ENDING THE KIT ALREADY USED.

  2. **Silent clobbering of a genuine divergence.** Some kit files are deliberately generic where
     the host's copy names its own folders. Overwriting those would drag project-specific text
     into a framework meant for any repo. So a file is copied ONLY when the kit's copy and the
     host's copy differ by nothing but the edits you are trying to move — anything else is
     REPORTED and left alone for a human to merge.

Usage
-----
    python sync-from-host.py --host "C:\\path\\to\\project"          # show what would change
    python sync-from-host.py --host "C:\\path\\to\\project" --apply  # write it

Run from the kit root. Dry-run is the default on purpose.
"""
import argparse
import difflib
import io
import os
import sys

# The framework surface. A kit-only file (this script, README.md, the kit's own CLAUDE.md) is
# deliberately absent: those describe the KIT, not the framework a project installs.
FRAMEWORK = [
    ".claude/primecouncil/runner.py",
    ".claude/primecouncil/config.json",
    ".claude/primecouncil/AGENTS.md",
    ".claude/primecouncil/ORCHESTRATION.md",
    ".claude/primecouncil/scripts/review-codex.sh",
    ".claude/primecouncil/scripts/statusline.sh",
    ".claude/primecouncil/docs/host-repo-pattern.md",
    ".claude/primecouncil/docs/packet-spec.md",
    ".claude/primecouncil/docs/protocol-detail.md",
    ".claude/primecouncil/docs/runs-spec.md",
    ".claude/primecouncil/docs/user-tutorial.md",
    ".claude/primecouncil/packets/templates/first-pass-review.md",
    ".claude/primecouncil/packets/templates/implementation-review.md",
    ".claude/primecouncil/packets/templates/synthesis-review.md",
    ".claude/primecouncil/packets/templates/final-recommendation.md",
    ".claude/primecouncil/packets/templates/task-summary.md",
    ".claude/skills/prime-install/SKILL.md",
    ".claude/skills/prime-install/references/AGENTS-template.md",
    ".claude/skills/prime-install/references/orchestration-template.md",
    ".claude/skills/prime-install/references/project-context-template.md",
    ".claude/skills/prime-orch/SKILL.md",
    ".claude/skills/prime-resume/SKILL.md",
]

# Files whose two copies are SUPPOSED to differ. The kit's version is written generically for any
# repo; a host names its own folders. Reported separately so the difference reads as a decision
# rather than as drift nobody got round to — and so a real change to one of these is still visible.
INTENTIONALLY_DIVERGENT = {
    ".claude/primecouncil/scripts/review-codex.sh":
        "the kit's comment stays repo-agnostic; a host names its own top-level folders",
}

# Never synced: per-machine state, run history, and the host's own project text.
#   orch-state.json  — ORCH on/off is per machine
#   runs/            — task history belongs to the project that ran it
#   docs/project-progress.md — the host project's own story
#   packets/*.md (non-template) — archived packets from real tasks


def norm(text):
    return text.replace("\r\n", "\n").replace("\r", "\n")


def ending_of(raw):
    crlf = raw.count(b"\r\n")
    lf = raw.count(b"\n") - crlf
    return "\r\n" if crlf > lf else "\n"


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--host", required=True, help="Path to the project repo to pull from")
    ap.add_argument("--apply", action="store_true", help="Write the changes (default: dry run)")
    ap.add_argument("--kit", default=os.path.dirname(os.path.abspath(__file__)),
                    help="Path to the kit root (defaults to this script's folder)")
    args = ap.parse_args()

    if not os.path.isdir(args.host):
        print("Host repo not found: %s" % args.host)
        return 1

    same, changed, host_only, kit_only, missing, divergent = [], [], [], [], [], []

    for rel in FRAMEWORK:
        host_path = os.path.join(args.host, *rel.split("/"))
        kit_path = os.path.join(args.kit, *rel.split("/"))
        host_exists, kit_exists = os.path.exists(host_path), os.path.exists(kit_path)

        if not host_exists and not kit_exists:
            missing.append(rel)
            continue
        if not host_exists:
            kit_only.append(rel)          # the host deleted it — deletion is a human call
            continue
        if not kit_exists:
            host_only.append(rel)         # new framework file — a human decides if it belongs
            continue

        kit_raw = io.open(kit_path, "rb").read()
        host_text = norm(io.open(host_path, encoding="utf-8").read())
        kit_text = norm(kit_raw.decode("utf-8"))

        if host_text == kit_text:
            same.append(rel)
            continue

        if rel in INTENTIONALLY_DIVERGENT:
            divergent.append(rel)
            continue

        changed.append((rel, kit_text, host_text, ending_of(kit_raw), kit_path))

    print("IN SYNC          : %d" % len(same))
    print("WOULD CHANGE     : %d" % len(changed))
    for rel in divergent:
        print("DIVERGENT ON PURPOSE: %-46s %s" % (rel, INTENTIONALLY_DIVERGENT[rel]))
    if host_only:
        print("HOST-ONLY (new)  : %s" % ", ".join(host_only))
    if kit_only:
        print("KIT-ONLY (gone from host): %s" % ", ".join(kit_only))
    if missing:
        print("ABSENT BOTH SIDES: %s" % ", ".join(missing))
    print("")

    for rel, kit_text, host_text, ending, kit_path in changed:
        diff = list(difflib.unified_diff(
            kit_text.splitlines(), host_text.splitlines(),
            fromfile="kit/" + rel, tofile="host/" + rel, lineterm="", n=1))
        added = sum(1 for d in diff if d.startswith("+") and not d.startswith("+++"))
        removed = sum(1 for d in diff if d.startswith("-") and not d.startswith("---"))
        print("  %-58s +%d/-%d  (%s)" % (rel, added, removed,
                                         "LF" if ending == "\n" else "CRLF"))
        if not args.apply:
            for line in diff[:14]:
                print("      %s" % line)
            if len(diff) > 14:
                print("      ... %d more diff lines" % (len(diff) - 14))
        else:
            io.open(kit_path, "wb").write(host_text.replace("\n", ending).encode("utf-8"))

    print("")
    if args.apply:
        print("APPLIED. Review with `git diff` in the kit before committing.")
    elif changed:
        print("DRY RUN. Re-run with --apply to write these.")
    else:
        print("Nothing to do.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
