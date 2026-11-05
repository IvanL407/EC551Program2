"""Schedulers. Every op takes exactly one cycle; cycles are numbered from 1.

limits: {'+': n|None, '-': n|None, '*': n|None}   (None = unlimited)
All schedulers return {op_idx: cycle}.
"""
import itertools
from collections import defaultdict

KINDS = ('+', '-', '*')


class ScheduleError(Exception):
    pass


def _check_limits(dag, limits):
    for o in dag.ops:
        lim = limits.get(o.kind)
        if lim is not None and lim < 1:
            raise ScheduleError(f"need at least 1 unit for '{o.kind}' (limit={lim})")


# ---------- unconstrained ----------
def asap(dag):
    cyc = {}
    for o in dag.ops:
        cyc[o.idx] = 1 + max((cyc[p] for p in dag.preds[o.idx]), default=0)
    return cyc


def alap(dag, latency=None):
    cp = dag.critical_path_len()
    L = cp if latency is None else latency
    if L < cp:
        raise ScheduleError(f"latency bound {L} < critical path {cp}")
    cyc = {}
    for o in reversed(dag.ops):
        cyc[o.idx] = min((cyc[s] for s in dag.succs[o.idx]), default=L + 1) - 1
    return cyc


# ---------- generic list scheduler (forward or backward) ----------
def _list_schedule(dag, limits, prio, forward=True):
    _check_limits(dag, limits)
    nbr_before = dag.preds if forward else dag.succs
    slot, remaining, t = {}, {o.idx for o in dag.ops}, 1
    kind = {o.idx: o.kind for o in dag.ops}
    while remaining:
        used = defaultdict(int)
        ready = sorted((i for i in remaining
                        if all(n in slot and slot[n] < t for n in nbr_before[i])), key=prio)
        for i in ready:
            lim = limits.get(kind[i])
            if lim is None or used[kind[i]] < lim:
                slot[i] = t
                used[kind[i]] += 1
        remaining -= {i for i in ready if i in slot}
        t += 1
    return slot


def asap_constrained(dag, limits):
    return _list_schedule(dag, limits, prio=lambda i: i, forward=True)


def alap_constrained(dag, limits, latency=None):
    rev = _list_schedule(dag, limits, prio=lambda i: -i, forward=False)
    Lr = max(rev.values())
    L = Lr if latency is None else latency
    if L < Lr:
        raise ScheduleError(f"latency bound {L} infeasible with these limits (need >= {Lr})")
    return {i: L + 1 - t for i, t in rev.items()}


# ---------- custom: critical-path list scheduling + automatic resource minimisation ----------
def _cp_priority(dag):
    cp = {}
    for o in reversed(dag.ops):
        cp[o.idx] = 1 + max((cp[s] for s in dag.succs[o.idx]), default=0)
    return lambda i: (-cp[i], i)         # longest remaining path first


def custom(dag, limits, latency=None):
    """Critical-path priority list scheduling.
    With a latency target, search for the cheapest (fewest total FUs) allocation that meets it,
    honouring any explicit per-type limits as upper bounds."""
    prio = _cp_priority(dag)
    if latency is None:
        return _list_schedule(dag, limits, prio)
    count = {k: sum(1 for o in dag.ops if o.kind == k) for k in KINDS}
    present = [k for k in KINDS if count[k]]
    ranges = []
    for k in present:
        cap = count[k] if limits.get(k) is None else min(limits[k], count[k])
        ranges.append(range(1, cap + 1))
    for combo in sorted(itertools.product(*ranges), key=lambda c: (sum(c), c)):
        lim = dict(zip(present, combo))
        s = _list_schedule(dag, lim, prio)
        if max(s.values()) <= latency:
            return s
    raise ScheduleError(f"cannot meet latency {latency} with the given limits")


# ---------- helpers ----------
def run(mode, dag, limits, latency=None):
    if mode == 'asap':
        return asap(dag)
    if mode == 'alap':
        return alap(dag, latency)
    if mode == 'casap':
        return asap_constrained(dag, limits)
    if mode == 'calap':
        return alap_constrained(dag, limits, latency)
    if mode == 'custom':
        return custom(dag, limits, latency)
    raise ScheduleError(f"unknown mode {mode}")


def validate(dag, sched, limits):
    """Raise if dependencies or resource limits are violated."""
    for o in dag.ops:
        assert sched[o.idx] >= 1, f"{o.dest} scheduled before cycle 1"
        for p in dag.preds[o.idx]:
            assert sched[p] < sched[o.idx], f"dependency violated {dag.ops[p].dest} -> {o.dest}"
    use = defaultdict(int)
    for o in dag.ops:
        use[(sched[o.idx], o.kind)] += 1
    for (c, k), n in use.items():
        lim = limits.get(k)
        assert lim is None or n <= lim, f"cycle {c}: {n} '{k}' ops > limit {lim}"


def usage(dag, sched):
    """Max concurrent ops of each kind (= number of FUs needed)."""
    per = defaultdict(int)
    for o in dag.ops:
        per[(sched[o.idx], o.kind)] += 1
    return {k: max((n for (c, kk), n in per.items() if kk == k), default=0) for k in KINDS}


def schedule_table(dag, sched):
    L = max(sched.values())
    lines = []
    for c in range(1, L + 1):
        ops = [o for o in dag.ops if sched[o.idx] == c]
        lines.append(f"cycle {c}: " + ", ".join(f"{o.dest}={o.a}{o.kind}{o.b}" for o in ops))
    return "\n".join(lines)