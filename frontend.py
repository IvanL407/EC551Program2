"""Front end: equation parser + SSA conversion."""
import re
from dataclasses import dataclass

LINE_RE = re.compile(r'^([A-Za-z_]\w*)\s*=\s*(\w+)\s*([+\-*])\s*(\w+)$')


@dataclass
class Op:
    idx: int        # position in program order
    dest: str       # SSA name (e.g. X_2)
    orig: str       # original variable name (X)
    kind: str       # '+', '-', '*'
    a: str          # operand: SSA name, input name, or integer literal
    b: str


def is_const(tok):
    return tok.isdigit()


def parse_equations(text):
    """Return [(lineno, dest, a, op, b)]. Blank lines and # or // comments ignored."""
    eqs = []
    for n, raw in enumerate(text.splitlines(), 1):
        line = re.split(r'#|//', raw)[0].strip().rstrip(';').strip()
        if not line:
            continue
        m = LINE_RE.match(line)
        if not m:
            raise SyntaxError(f"line {n}: expected 'X = A <+|-|*> B', got: {raw.strip()!r}")
        dest, a, op, b = m.groups()
        if is_const(dest):
            raise SyntaxError(f"line {n}: cannot assign to a constant")
        eqs.append((n, dest, a, op, b))
    if not eqs:
        raise SyntaxError("no equations found")
    if len(eqs) > 20:
        print(f"warning: {len(eqs)} equations (assignment assumes <= 20)")
    return eqs


def to_ssa(eqs):
    """Rename every assignment to a fresh version X_1, X_2, ...
    Reads resolve to the latest version; names read before any assignment are primary inputs.
    Returns (ops, inputs, final_map) where final_map: original name -> last SSA name."""
    current, version, inputs, ops = {}, {}, [], []

    def resolve(tok):
        if is_const(tok):
            return tok
        if tok in current:
            return current[tok]
        if tok not in inputs:
            inputs.append(tok)
        return tok

    for i, (_, dest, a, op, b) in enumerate(eqs):
        ra, rb = resolve(a), resolve(b)          # resolve operands BEFORE renaming dest
        version[dest] = version.get(dest, 0) + 1
        name = f"{dest}_{version[dest]}"
        current[dest] = name
        ops.append(Op(i, name, dest, op, ra, rb))
    return ops, inputs, dict(current)


def ssa_text(ops, inputs, final_map):
    lines = ["# SSA form", "# inputs: " + ", ".join(inputs)]
    lines += [f"{o.dest} = {o.a} {o.kind} {o.b}" for o in ops]
    lines.append("# final values: " + ", ".join(f"{k} -> {v}" for k, v in final_map.items()))
    return "\n".join(lines) + "\n"