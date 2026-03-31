#!/usr/bin/env python3
"""Aggregate LekmapStartSpacing6P.log across many map gens. Rolls = each GenerateMap_lua_entry block."""

from __future__ import annotations

import argparse
import collections
import os.path
import re
import sys
from typing import Dict, List, Tuple


def default_log_path() -> str:
    home = os.path.expanduser("~")
    return os.path.join(
        home,
        "Library",
        "Application Support",
        "Sid Meier's Civilization 5",
        "Logs",
        "LekmapStartSpacing6P.log",
    )


def split_rolls(lines: List[str]) -> List[List[str]]:
    blocks: List[List[str]] = []
    cur: List[str] = []
    for line in lines:
        if "### LekMapGen GenerateMap_lua_entry" in line and cur:
            blocks.append(cur)
            cur = [line]
        else:
            cur.append(line)
    if cur:
        blocks.append(cur)
    return blocks


def inc(d: Dict[str, int], k: str, n: int = 1) -> None:
    d[k] = d.get(k, 0) + n


def first_match(pat: re.Pattern, block: List[str]) -> re.Match | None:
    for line in block:
        m = pat.search(line)
        if m:
            return m
    return None


RE_TUPLE_SEARCH = re.compile(r"### LekGlobalSix tupleSearch runId=\S+ status=(\S+)")
RE_SOLVER = re.compile(r"### LekGlobalSixChooseLocations runId=\S+ solver_return=(\w+)")
RE_BIAS = re.compile(
    r"### LekGlobalSix tupleBiasFeasibility runId=\S+ .*?decision=(\S+) reason=(\S+)"
)
RE_BIAS_SKIP_DETAIL = re.compile(r"detail=(\S+)")
RE_PHASE_END = re.compile(
    r"### LekGlobalSix tuplePhase end runId=\S+ .*?status=(\S+)(?: .*?last_fail=(\S+))?"
)
RE_LAST_FAIL = re.compile(r"last_fail=(\S+)")
RE_OK_DIAG = re.compile(r"### LekGlobalSix_OK diag runId=\S+ .*?first_fail=(\S+)")
RE_REGEN = re.compile(r"### LekGlobalSix mapRegen request runId=\S+ .*?reason=(\S+)")
RE_MIN_ELIG = re.compile(r"minEligRegionsAmongPlayers=(\d+)")
RE_LAYOUT_RESULT = re.compile(r"### LekGlobalSix mapRegen layout_result .*?outcome=(\S+)")
RE_REGEN_SUMMARY = re.compile(
    r"### LekGlobalSix mapRegen summary total_layouts_tried=(\d+) final_outcome=(\S+)"
)


def digest_block(block: List[str]) -> dict:
    r: dict = {
        "tuple_search": None,
        "solver_return": None,
        "bias_decisions": [],
        "phase_end_status": [],
        "phase_last_fail": [],
        "ok_first_fail": None,
        "regen_reasons": [],
        "min_elig_min": None,
    }
    m = first_match(RE_TUPLE_SEARCH, block)
    if m:
        r["tuple_search"] = m.group(1)
    m = first_match(RE_SOLVER, block)
    if m:
        r["solver_return"] = m.group(1)
    for line in block:
        mb = RE_BIAS.search(line)
        if mb:
            item = {"decision": mb.group(1), "reason": mb.group(2)}
            md = RE_BIAS_SKIP_DETAIL.search(line)
            if md:
                item["detail"] = md.group(1)
            r["bias_decisions"].append(item)
        mo = RE_OK_DIAG.search(line)
        if mo:
            r["ok_first_fail"] = mo.group(1)
        mr = RE_REGEN.search(line)
        if mr:
            r["regen_reasons"].append(mr.group(1))
        me = RE_MIN_ELIG.search(line)
        if me:
            v = int(me.group(1))
            if r["min_elig_min"] is None or v < r["min_elig_min"]:
                r["min_elig_min"] = v
    for line in block:
        if "### LekGlobalSix tuplePhase end" in line:
            mp = RE_PHASE_END.search(line)
            if mp:
                r["phase_end_status"].append(mp.group(1))
                lf = mp.group(2)
                if not lf:
                    mlf = RE_LAST_FAIL.search(line)
                    lf = mlf.group(1) if mlf else ""
                if lf and lf != "na":
                    r["phase_last_fail"].append(lf)
    return r


def roll_summary(block: List[str], d: dict) -> str:
    bias_lines = len(d["bias_decisions"])
    bias_any_skip = any(x.get("decision") == "skip_impossible" for x in d["bias_decisions"])
    bias_any_go = any(x.get("decision") == "proceed_dfs" for x in d["bias_decisions"])
    if bias_lines == 0:
        bg = "biasLog=absent"
    elif bias_any_skip and not bias_any_go:
        bg = "bias=all_skip"
    elif bias_any_go:
        bg = "bias=had_proceed_dfs"
    else:
        bg = "bias=mixed"
    ts = d["tuple_search"] or "no_tupleSearch_line"
    sr = d["solver_return"] or "?"
    return f"tuple={ts} solver={sr} {bg}"


def main() -> int:
    ap = argparse.ArgumentParser(description="Digest Lekmap placement logs across map gens.")
    ap.add_argument("logfile", nargs="?", default=None, help="Path to LekmapStartSpacing6P.log")
    ap.add_argument(
        "--per-roll",
        action="store_true",
        help="Print one summary line per roll (tupleSearch + solver + bias logging era).",
    )
    args = ap.parse_args()
    path = args.logfile or default_log_path()
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except OSError as e:
        print(e, file=sys.stderr)
        return 1

    raw_lines = [ln.rstrip("\n") for ln in lines]
    layout_outcome_hist: Dict[str, int] = {}
    for ln in raw_lines:
        mlr = RE_LAYOUT_RESULT.search(ln)
        if mlr:
            inc(layout_outcome_hist, mlr.group(1))
    summary_lines: List[Tuple[str, str]] = []
    for ln in raw_lines:
        ms = RE_REGEN_SUMMARY.search(ln)
        if ms:
            summary_lines.append((ms.group(1), ms.group(2)))

    rolls = split_rolls(raw_lines)
    tuple_status: Dict[str, int] = {}
    solver_status: Dict[str, int] = {}
    bias_decision: Dict[str, int] = {}
    bias_reason: Dict[str, int] = {}
    phase_status: Dict[str, int] = {}
    last_fail: Dict[str, int] = {}
    ok_first: Dict[str, int] = {}
    regen_reason: Dict[str, int] = {}
    min_elig_hist: Dict[str, int] = collections.Counter()
    rolls_with_tuple = 0

    roll_summaries: List[str] = []

    for block in rolls:
        if not any("ChooseLocations begin" in L for L in block):
            continue
        rolls_with_tuple += 1
        d = digest_block(block)
        if args.per_roll:
            roll_summaries.append(roll_summary(block, d))
        if d["tuple_search"]:
            inc(tuple_status, d["tuple_search"])
        if d["solver_return"]:
            inc(solver_status, d["solver_return"])
        for b in d["bias_decisions"]:
            inc(bias_decision, b["decision"])
            inc(bias_reason, b["reason"])
        for ps in d["phase_end_status"]:
            inc(phase_status, ps)
        for lf in d["phase_last_fail"]:
            inc(last_fail, lf)
        if d["ok_first_fail"]:
            inc(ok_first, d["ok_first_fail"])
        for rr in d["regen_reasons"]:
            inc(regen_reason, rr)
        if d["min_elig_min"] is not None:
            min_elig_hist[str(d["min_elig_min"])] += 1

    def dump(title: str, d: Dict[str, int]) -> None:
        if not d:
            return
        print(title)
        for k, v in sorted(d.items(), key=lambda kv: (-kv[1], kv[0])):
            print(f"  {k}: {v}")

    print(f"file: {path}")
    dump("mapRegen layout_result outcome (all lines)", layout_outcome_hist)
    if summary_lines:
        print("mapRegen summary (last lines in file win if multiple map gens appended)")
        for nt, fo in summary_lines[-5:]:
            print(f"  total_layouts_tried={nt} final_outcome={fo}")
    print(f"rolls (blocks with ChooseLocations): {rolls_with_tuple}")
    if roll_summaries:
        print("per-roll:")
        for i, s in enumerate(roll_summaries, 1):
            print(f"  {i}: {s}")
    dump("tupleSearch status", tuple_status)
    dump("LekGlobalSixChooseLocations solver_return", solver_status)
    dump("tupleBiasFeasibility decision", bias_decision)
    dump("tupleBiasFeasibility reason", bias_reason)
    dump("tuplePhase end status", phase_status)
    dump("tuplePhase last_fail (when present)", last_fail)
    dump("LekGlobalSix_OK first_fail", ok_first)
    dump("mapRegen request reason", regen_reason)
    if min_elig_hist:
        print("minEligRegionsAmongPlayers (min over tupleBias lines per roll)")
        for k, v in sorted(min_elig_hist.items(), key=lambda kv: int(kv[0])):
            print(f"  {k}: {v}")
    print(
        "\nNote: tupleBiasFeasibility was added recently; rolls with biasLog=absent still have tupleSearch/solver stats."
    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
