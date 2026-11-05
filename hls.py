#!/usr/bin/env python3
"""EC551 PA2 -- mini HLS tool: equations -> SSA -> DAG -> schedule -> Verilog (datapath + FSM)."""
import argparse, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from frontend import parse_equations, to_ssa, ssa_text
from dag import DAG
import scheduler as S
import verilog_gen as V


def parse_defaults(s, inputs):
    d = {n: i + 1 for i, n in enumerate(inputs)}        # A=1, B=2, ... unless overridden
    if s:
        for kv in s.split(','):
            k, v = kv.split('=')
            if k.strip() not in d:
                sys.exit(f"--defaults: '{k}' is not an input ({', '.join(inputs)})")
            d[k.strip()] = int(v)
    return d


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('input', help='equation file')
    ap.add_argument('--mode', choices=['asap', 'casap', 'alap', 'calap', 'custom'], default='asap')
    ap.add_argument('--adders', type=int, help='max adders')
    ap.add_argument('--subtractors', type=int, help='max subtractors')
    ap.add_argument('--multipliers', type=int, help='max multipliers')
    ap.add_argument('--latency', type=int, help='latency bound (alap/calap) or target (custom)')
    ap.add_argument('--width', type=int, default=16, help='datapath width (default 16)')
    ap.add_argument('--defaults', help='demo values for inputs, e.g. A=3,B=5 (others default to 1,2,3..)')
    ap.add_argument('--outdir', default='gen')
    ap.add_argument('--export-ssa', nargs='?', const='ssa.txt', metavar='FILE',
                    help='write SSA form to FILE (default <outdir>/ssa.txt)')
    ap.add_argument('--export-dot', nargs='?', const='dag.dot', metavar='FILE', help='write DAG as Graphviz')
    a = ap.parse_args()

    try:
        eqs = parse_equations(open(a.input).read())
        ops, inputs, final = to_ssa(eqs)
        dag = DAG(ops)
        limits = {'+': a.adders, '-': a.subtractors, '*': a.multipliers}
        sched = S.run(a.mode, dag, limits, a.latency)
        S.validate(dag, sched, limits)
    except (SyntaxError, S.ScheduleError, AssertionError) as e:
        sys.exit(f"error: {e}")

    os.makedirs(a.outdir, exist_ok=True)
    path = lambda f: f if os.path.dirname(f) else os.path.join(a.outdir, f)
    ssa = ssa_text(ops, inputs, final)
    if a.export_ssa:
        open(path(a.export_ssa), 'w').write(ssa)
    if a.export_dot:
        open(path(a.export_dot), 'w').write(dag.to_dot())

    defaults = parse_defaults(a.defaults, inputs)
    core, fu_of, fu_list = V.emit_core(ops, inputs, dag, sched, a.width, defaults)
    open(os.path.join(a.outdir, 'hls_core.v'), 'w').write(core)
    open(os.path.join(a.outdir, 'tb_hls_core.v'), 'w').write(
        V.emit_testbench(ops, inputs, sched, a.width, defaults))
    smap = V.switch_map(ops, inputs, fu_of, fu_list, sched)
    open(os.path.join(a.outdir, 'switch_map.txt'), 'w').write(smap)
    sched_txt = S.schedule_table(dag, sched)
    open(os.path.join(a.outdir, 'schedule.txt'), 'w').write(sched_txt + "\n")

    print(ssa)
    print(f"mode={a.mode} limits={ {k: v for k, v in limits.items() if v} } -> {max(sched.values())} cycles, "
          f"units needed {S.usage(dag, sched)}")
    print(sched_txt)
    print("\ndemo defaults:", ", ".join(f"{k}={v}" for k, v in defaults.items()))
    print("\n" + smap)
    print(f"wrote {a.outdir}/hls_core.v, tb_hls_core.v, switch_map.txt, schedule.txt")


if __name__ == '__main__':
    main()