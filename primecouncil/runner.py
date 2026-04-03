#!/usr/bin/env python3
"""
PrimeCouncil Runner — Thin mechanical executor.
Handles folder creation, packet writing, reviewer invocation, and output persistence.
Claude calls this. Claude still owns all thinking, synthesis, and decisions.
"""

import argparse
import datetime
import json
import os
import subprocess
import sys

# Base paths
RUNS_DIR = "primecouncil/runs"
SCRIPTS_DIR = "primecouncil/scripts"
TEMPLATES_DIR = "primecouncil/packets/templates"


def get_today():
    return datetime.date.today().strftime("%Y-%m-%d")


def find_next_task_number():
    """Find the next sequential task number across all runs."""
    if not os.path.exists(RUNS_DIR):
        return 1
    existing = os.listdir(RUNS_DIR)
    max_num = 0
    for name in existing:
        parts = name.split("-task-")
        if len(parts) == 2:
            try:
                num = int(parts[1].split("-")[0])
                max_num = max(max_num, num)
            except ValueError:
                pass
    return max_num + 1


def make_task_id(label):
    """Generate task ID: YYYY-MM-DD-task-NNN-slug"""
    import re
    num = find_next_task_number()
    slug = label.lower().replace(" ", "-").replace("_", "-")
    slug = re.sub(r'[^a-z0-9-]', '', slug)  # keep only safe chars
    slug = re.sub(r'-+', '-', slug).strip('-')  # collapse repeated hyphens
    slug = "-".join(slug.split("-")[:4])  # keep slug short
    slug = slug or "task"  # fallback if sanitization empties the slug
    return f"{get_today()}-task-{num:03d}-{slug}"


# ─── INIT ─────────────────────────────────────────────────

def cmd_init(args):
    """Create a new task with folder structure and task.md"""
    task_id = make_task_id(args.label)
    task_dir = os.path.join(RUNS_DIR, task_id)
    round_dir = os.path.join(task_dir, "round-01")

    os.makedirs(round_dir, exist_ok=True)

    # Write task.md
    task_md = f"""# Task Metadata

- Task ID: {task_id}
- Task label: {args.label}
- Mode: {args.mode.upper()}
- Status: active
- Start date: {get_today()}
- Rounds completed: 0
- Objective: {args.objective if args.objective else '[To be filled by Claude]'}
"""
    with open(os.path.join(task_dir, "task.md"), "w", encoding="utf-8") as f:
        f.write(task_md)

    result = {
        "status": "ok",
        "task_id": task_id,
        "task_dir": task_dir,
        "round_dir": round_dir,
    }
    print(json.dumps(result, indent=2))


# ─── SAVE ─────────────────────────────────────────────────

def cmd_save(args):
    """Save a file (first-pass, synthesis, recommendation, etc.) to the task/round folder."""
    if args.impl and args.round is not None:
        print(json.dumps({"status": "error", "message": "Cannot use both --round and --impl"}))
        sys.exit(1)

    task_dir = os.path.join(RUNS_DIR, args.task_id)
    if not os.path.exists(task_dir):
        print(json.dumps({"status": "error", "message": f"Task dir not found: {task_dir}"}))
        sys.exit(1)

    # Determine target path
    if args.impl:
        target_dir = os.path.join(task_dir, "implementation-review")
    elif args.round:
        target_dir = os.path.join(task_dir, f"round-{args.round:02d}")
    else:
        target_dir = task_dir
    os.makedirs(target_dir, exist_ok=True)

    filepath = os.path.join(target_dir, args.filename)

    # Content from --content arg or stdin
    if args.content:
        content = args.content
    else:
        content = sys.stdin.read()

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

    result = {
        "status": "ok",
        "file": filepath,
    }
    print(json.dumps(result, indent=2))


# ─── REVIEW ───────────────────────────────────────────────

def cmd_review(args):
    """Write packet files and run reviewer scripts."""
    if not args.impl and args.round is None:
        print(json.dumps({"status": "error", "message": "Must provide --round N or --impl"}))
        sys.exit(1)
    if args.impl and args.round is not None:
        print(json.dumps({"status": "error", "message": "Cannot use both --round and --impl"}))
        sys.exit(1)
    if getattr(args, 'codex_only', False) and getattr(args, 'gemini_only', False):
        print(json.dumps({"status": "error", "message": "Cannot use both --codex-only and --gemini-only"}))
        sys.exit(1)

    run_codex = not getattr(args, 'gemini_only', False)
    run_gemini = not getattr(args, 'codex_only', False)

    task_dir = os.path.join(RUNS_DIR, args.task_id)

    # Validate task exists
    if not os.path.exists(task_dir):
        print(json.dumps({"status": "error", "message": f"Task dir not found: {task_dir}"}))
        sys.exit(1)

    # Support implementation-review folder via --impl flag
    if args.impl:
        review_dir = os.path.join(task_dir, "implementation-review")
    else:
        review_dir = os.path.join(task_dir, f"round-{args.round:02d}")
    os.makedirs(review_dir, exist_ok=True)

    # Get packet content from --content or stdin
    if args.content:
        packet_body = args.content
    else:
        packet_body = sys.stdin.read()

    # Fix #1: Write both packets with correct reviewer-specific focus lines
    codex_focus = "**Reviewer focus:** Depth of reasoning, hidden assumptions, structural weaknesses."
    gemini_focus = "**Reviewer focus:** UX/human considerations, alternative framing, unconventional ideas."

    packet_codex_path = os.path.join(review_dir, "packet-codex.md")
    packet_gemini_path = os.path.join(review_dir, "packet-gemini.md")

    codex_raw_path = os.path.join(review_dir, "codex-output-raw.md")
    gemini_raw_path = os.path.join(review_dir, "gemini-output-raw.md")
    codex_review_path = os.path.join(review_dir, "codex-review.md")
    gemini_review_path = os.path.join(review_dir, "gemini-review.md")

    # Write packets only for reviewers being run
    reviewers_to_write = []
    if run_codex:
        reviewers_to_write.append((packet_codex_path, codex_focus))
    if run_gemini:
        reviewers_to_write.append((packet_gemini_path, gemini_focus))

    for pkt_path, focus in reviewers_to_write:
        lines = packet_body.split("\n")
        has_existing_focus = any(l.strip().startswith("**Reviewer focus:**") for l in lines)

        output_lines = []
        focus_inserted = False
        for line in lines:
            if has_existing_focus and line.strip().startswith("**Reviewer focus:**"):
                output_lines.append(focus)
                focus_inserted = True
            else:
                output_lines.append(line)
                if not has_existing_focus and not focus_inserted and line.strip().startswith("#"):
                    output_lines.append("")
                    output_lines.append(focus)
                    focus_inserted = True

        if not focus_inserted:
            output_lines.insert(0, focus)

        with open(pkt_path, "w", encoding="utf-8") as f:
            f.write("\n".join(output_lines))

    # Clear stale review files only for reviewers being run
    # Also clean up skipped reviewer's old files to prevent misleading state
    stale_files = []
    if run_codex:
        stale_files.extend([codex_raw_path, codex_review_path])
    else:
        # Skipped: remove old artifacts so round state is clean
        for old in [packet_codex_path, codex_raw_path, codex_review_path]:
            if os.path.exists(old):
                os.remove(old)
    if run_gemini:
        stale_files.extend([gemini_raw_path, gemini_review_path])
    else:
        # Skipped: remove old artifacts so round state is clean
        for old in [packet_gemini_path, gemini_raw_path, gemini_review_path]:
            if os.path.exists(old):
                os.remove(old)
    for stale in stale_files:
        if os.path.exists(stale):
            os.remove(stale)

    results = {"status": "ok", "review_dir": review_dir, "reviewers": {}}

    # Run Codex
    if run_codex:
        codex_script = os.path.join(SCRIPTS_DIR, "review-codex.sh")
        try:
            subprocess.run(
                ["bash", codex_script, packet_codex_path, codex_raw_path],
                timeout=300,
                check=False,
            )
            if os.path.exists(codex_review_path):
                results["reviewers"]["codex"] = {"status": "ok", "review": codex_review_path}
            elif os.path.exists(codex_raw_path):
                results["reviewers"]["codex"] = {"status": "degraded", "raw": codex_raw_path}
            else:
                results["reviewers"]["codex"] = {"status": "failed"}
        except subprocess.TimeoutExpired:
            results["reviewers"]["codex"] = {"status": "timeout"}
        except Exception as e:
            results["reviewers"]["codex"] = {"status": "error", "message": str(e)}
    else:
        results["reviewers"]["codex"] = {"status": "skipped"}

    # Run Gemini
    if run_gemini:
        gemini_script = os.path.join(SCRIPTS_DIR, "review-gemini.sh")
        try:
            subprocess.run(
                ["bash", gemini_script, packet_gemini_path, gemini_raw_path],
                timeout=300,
                check=False,
            )
            if os.path.exists(gemini_review_path):
                results["reviewers"]["gemini"] = {"status": "ok", "review": gemini_review_path}
            elif os.path.exists(gemini_raw_path):
                results["reviewers"]["gemini"] = {"status": "degraded", "raw": gemini_raw_path}
            else:
                results["reviewers"]["gemini"] = {"status": "failed"}
        except subprocess.TimeoutExpired:
            results["reviewers"]["gemini"] = {"status": "timeout"}
        except Exception as e:
            results["reviewers"]["gemini"] = {"status": "error", "message": str(e)}
    else:
        results["reviewers"]["gemini"] = {"status": "skipped"}

    print(json.dumps(results, indent=2))


# ─── NEW ROUND ────────────────────────────────────────────

def cmd_new_round(args):
    """Create the next round folder for an existing task."""
    task_dir = os.path.join(RUNS_DIR, args.task_id)
    if not os.path.exists(task_dir):
        print(json.dumps({"status": "error", "message": f"Task dir not found: {task_dir}"}))
        sys.exit(1)

    # Find next round number
    existing = [d for d in os.listdir(task_dir) if d.startswith("round-")]
    next_num = len(existing) + 1
    round_dir = os.path.join(task_dir, f"round-{next_num:02d}")
    os.makedirs(round_dir, exist_ok=True)

    result = {
        "status": "ok",
        "round": next_num,
        "round_dir": round_dir,
    }
    print(json.dumps(result, indent=2))


# ─── STATUS ───────────────────────────────────────────────

def cmd_status(args):
    """Show current state of a task."""
    task_dir = os.path.join(RUNS_DIR, args.task_id)
    if not os.path.exists(task_dir):
        print(json.dumps({"status": "error", "message": f"Task dir not found: {task_dir}"}))
        sys.exit(1)

    # Task-root files (task.md, task-summary.md, etc.)
    root_files = [f for f in os.listdir(task_dir) if os.path.isfile(os.path.join(task_dir, f))]

    # Round folders
    rounds = sorted([d for d in os.listdir(task_dir) if d.startswith("round-")])
    files_per_round = {}
    for r in rounds:
        round_path = os.path.join(task_dir, r)
        files_per_round[r] = os.listdir(round_path)

    # Implementation-review folder
    impl_dir = os.path.join(task_dir, "implementation-review")
    impl_files = None
    if os.path.exists(impl_dir):
        impl_files = os.listdir(impl_dir)

    result = {
        "status": "ok",
        "task_id": args.task_id,
        "task_root_files": root_files,
        "rounds": len(rounds),
        "files": files_per_round,
    }
    if impl_files is not None:
        result["implementation_review"] = impl_files

    print(json.dumps(result, indent=2))


# ─── LIST ─────────────────────────────────────────────────

def cmd_list(args):
    """List all tasks with status, mode, last-modified, and summary availability."""
    if not os.path.exists(RUNS_DIR):
        print(json.dumps({"status": "ok", "tasks": []}))
        return

    tasks = []
    for name in sorted(os.listdir(RUNS_DIR)):
        task_dir = os.path.join(RUNS_DIR, name)
        if not os.path.isdir(task_dir):
            continue

        task_info = {"task_id": name}

        # Read status and mode from task.md
        task_md_path = os.path.join(task_dir, "task.md")
        if os.path.exists(task_md_path):
            with open(task_md_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("- Status:"):
                        task_info["status"] = line.split(":", 1)[1].strip()
                    elif line.startswith("- Mode:"):
                        task_info["mode"] = line.split(":", 1)[1].strip()
        if "status" not in task_info:
            task_info["status"] = "unknown"
        if "mode" not in task_info:
            task_info["mode"] = "unknown"

        # Last modified — most recent file modification in the task tree
        latest_mtime = 0
        for root, dirs, files in os.walk(task_dir):
            for f in files:
                fpath = os.path.join(root, f)
                mtime = os.path.getmtime(fpath)
                if mtime > latest_mtime:
                    latest_mtime = mtime
        if latest_mtime > 0:
            task_info["last_modified"] = datetime.datetime.fromtimestamp(
                latest_mtime
            ).strftime("%Y-%m-%d %H:%M")
        else:
            task_info["last_modified"] = "unknown"

        # Check for task-summary.md
        task_info["has_summary"] = os.path.exists(
            os.path.join(task_dir, "task-summary.md")
        )

        # Count rounds
        rounds = [d for d in os.listdir(task_dir) if d.startswith("round-")]
        task_info["rounds"] = len(rounds)

        tasks.append(task_info)

    print(json.dumps({"status": "ok", "tasks": tasks}, indent=2))


# ─── MAIN ─────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="PrimeCouncil Runner")
    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # init
    p_init = subparsers.add_parser("init", help="Create a new task")
    p_init.add_argument("--label", required=True, help="Short task label")
    p_init.add_argument("--mode", default="standard", help="standard or deep")
    p_init.add_argument("--objective", default="", help="Brief objective")

    # save
    p_save = subparsers.add_parser("save", help="Save a file to the task")
    p_save.add_argument("--task-id", required=True, help="Task ID")
    p_save.add_argument("--filename", required=True, help="File name (e.g. claude-first-pass.md)")
    p_save.add_argument("--round", type=int, default=None, help="Round number")
    p_save.add_argument("--impl", action="store_true", help="Save to implementation-review/ folder")
    p_save.add_argument("--content", default=None, help="Content (or pipe via stdin)")

    # review
    p_review = subparsers.add_parser("review", help="Write packets and run reviewers")
    p_review.add_argument("--task-id", required=True, help="Task ID")
    p_review.add_argument("--round", type=int, default=None, help="Round number (omit if --impl)")
    p_review.add_argument("--impl", action="store_true", help="Run as implementation review (uses implementation-review/ folder)")
    p_review.add_argument("--codex-only", action="store_true", help="Run only Codex reviewer")
    p_review.add_argument("--gemini-only", action="store_true", help="Run only Gemini reviewer")
    p_review.add_argument("--content", default=None, help="Packet body (or pipe via stdin)")

    # new-round
    p_newround = subparsers.add_parser("new-round", help="Create next round folder")
    p_newround.add_argument("--task-id", required=True, help="Task ID")

    # status
    p_status = subparsers.add_parser("status", help="Show task status")
    p_status.add_argument("--task-id", required=True, help="Task ID")

    # list
    subparsers.add_parser("list", help="List all tasks with status and summary info")

    args = parser.parse_args()

    if args.command == "init":
        cmd_init(args)
    elif args.command == "save":
        cmd_save(args)
    elif args.command == "review":
        cmd_review(args)
    elif args.command == "new-round":
        cmd_new_round(args)
    elif args.command == "status":
        cmd_status(args)
    elif args.command == "list":
        cmd_list(args)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()