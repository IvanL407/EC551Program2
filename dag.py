"""Dependency DAG over SSA ops."""

class DAG:
    def __init__(self, ops):
        self.ops = ops
        self.producer = {o.dest: o.idx for o in ops}
        self.preds = {o.idx: sorted({self.producer[s] for s in (o.a, o.b) if s in self.producer})
                      for o in ops}
        self.succs = {o.idx: [] for o in ops}
        for i, ps in self.preds.items():
            for p in ps:
                self.succs[p].append(i)

    def critical_path_len(self):
        """Number of cycles on the longest dependency chain (1-cycle ops)."""
        depth = {}
        for o in self.ops:            # program order is already topological in SSA
            depth[o.idx] = 1 + max((depth[p] for p in self.preds[o.idx]), default=0)
        return max(depth.values())

    def to_dot(self):
        out = ["digraph dag {", "  rankdir=TB;"]
        for o in self.ops:
            out.append(f'  n{o.idx} [label="{o.dest}\\n{o.a} {o.kind} {o.b}", shape=circle];')
        for i, ps in self.preds.items():
            for p in ps:
                out.append(f"  n{p} -> n{i};")
        out.append("}")
        return "\n".join(out) + "\n"