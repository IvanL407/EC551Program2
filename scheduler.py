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