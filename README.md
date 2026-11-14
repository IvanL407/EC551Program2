# EC551 Programming Assignment 2 - Hardware Synthesis (mini HLS tool)

This tool reads simple equations (`X = A + B`), turns them into SSA form, builds a DAG,
schedules it, and writes Verilog (datapath + FSM) that runs on the Nexys4 DDR board.

## Repository layout

```
hls.py            main program (command line)
frontend.py       equation parser + SSA renaming
dag.py            dependency DAG (+ Graphviz export)
scheduler.py      ASAP, ALAP, constrained ASAP/ALAP, custom scheduler
verilog_gen.py    binding of ops to units, Verilog generator, testbench generators
rtl/              hand written Verilog that never changes
  hls_fu.v          adder, subtractor, multiplier blocks
  debounce.v        button debounce + one pulse per press
  seg7_hex8.v       8 digit hex 7-segment driver
  top.v             top level for the board
constraints/      Nexys4DDR_Master.xdc (course master file, lines for our pins uncommented)
examples/         sample equation files
gen/              generated output for examples/spec_example.txt
sim/run_sim.sh    runs both testbenches with Icarus Verilog
```

## How the tool works

1. **Parse** - one equation per line, `dest = a op b`, op is `+`, `-` or `*`. Operands can be
   variables or integer constants. `#` and `//` comments are allowed.
2. **SSA** - every assignment gets a new name (`X_1`, `X_2`, ...). A variable that is read
   before it is assigned is a primary input.
3. **DAG** - one node per operation, an edge when one op uses the result of another.
4. **Schedule** - every op takes one cycle. Modes:
   - `asap` - as soon as possible, no limits
   - `casap` - ASAP with a max number of adders / subtractors / multipliers
   - `alap` - as late as possible, working back from `--latency` (default = critical path)
   - `calap` - ALAP with resource limits
   - `custom` - list scheduling where the op with the longest path after it goes first.
     With `--latency N` it also searches for the smallest number of units that still finishes in N cycles.
5. **Bind** - ops are assigned to unit instances (`add0`, `mul1`, ...). It picks the unit that
   needs the fewest new mux inputs.
6. **Generate** - `hls_core.v` has: one register per variable, one input mux pair per unit
   (selected by the FSM state), register write enables per state, and a counter style FSM
   (`IDLE -> 1 -> 2 -> ... -> L -> DONE`). The FSM only moves when `step` is pulsed.

## How to run

Needs Python 3 (no packages). Simulation needs Icarus Verilog. The board flow needs Vivado.

```
python3 hls.py examples/spec_example.txt                       # ASAP
python3 hls.py examples/wide.txt --mode casap --adders 1 --multipliers 1
python3 hls.py examples/wide.txt --mode alap --latency 6
python3 hls.py examples/wide.txt --mode custom --latency 5
python3 hls.py examples/reassign.txt --export-ssa --export-dot  # writes gen/ssa.txt, gen/dag.dot
python3 hls.py eq.txt --defaults A=5,B=3                        # reset values of the inputs
```

Other flags: `--subtractors N`, `--width N` (default 16), `--outdir DIR` (default `gen`).

Files written to `gen/`: `hls_core.v`, `tb_hls_core.v`, `testbench.v`, `schedule.txt`,
`switch_map.txt`, and `ssa.txt` / `dag.dot` if asked.

### Simulate

```
sim/run_sim.sh          # or: sim/run_sim.sh <outdir>
```

- `tb_hls_core.v` tests the generated core with 4 input sets against a Python model.
- `testbench.v` tests the whole board design through the pins only. It presses the (bouncy)
  buttons, sets switches, and reads the result back by decoding the 7-segment signals.

Both print `PASS` or `FAIL` lines.

### Put it on the board (Vivado)

1. Create a project for the Nexys4 DDR (xc7a100tcsg324-1).
2. Add `rtl/*.v` and `gen/hls_core.v` as design sources, top = `top`.
3. Add `gen/testbench.v` as a simulation source (optional).
4. Add `constraints/Nexys4DDR_Master.xdc`.
5. Generate bitstream and program. For new equations only `gen/hls_core.v` changes, so just
   rerun `hls.py` and regenerate the bitstream.

If you use `--width` other than 16, also set the `W` parameter of `top` to the same number.

## Board controls

| Control | What it does |
|---|---|
| BTNC | STEP. One press moves the FSM one state. This is the button "clock". |
| BTNU | LOAD. In IDLE, writes SW[7:0] into the input picked by SW[11:8]. |
| CPU_RESETN | Reset. FSM to IDLE, inputs back to the `--defaults` values. |
| SW[15:12] | Picks which adder / subtractor / multiplier is shown (right 4 digits). |
| SW[11:8] | Picks which variable register is shown (left 4 digits). Also the LOAD target. |
| SW[7:0] | Value to load (0 to 255). |
| 7-seg left 4 digits | selected variable register, hex |
| 7-seg right 4 digits | selected functional unit output, hex |
| LED[4:0] | FSM state. 0 = IDLE, 1..L = schedule cycle, L+1 = DONE |
| LED[14], LED[15] | IDLE, DONE |

The switch codes depend on the equations. `hls.py` prints the table and saves it in
`gen/switch_map.txt`.

During cycle `c` the selected unit shows the value it is computing right now. Pressing STEP
stores it in the result register and moves to the next cycle. A unit that is not used in the
current cycle shows the last value it produced.

Limits: 16 bit datapath, 8 bit switch inputs, 16 variables and 16 units selectable from the
switches, results shown in hex. Inputs that are not loaded keep their default value.

## 30 minute demo plan

| Time | What |
|---|---|
| 0 - 10 min | Overview of the flow (parse, SSA, DAG, schedule, bind, Verilog) and the repo. |
| 10 - 20 min | Verilog generation and test simulations. |
| 20 - 30 min | FPGA setup demonstrations, Questions. |


Notes for the live runs:

- A bitstream build takes about 2 to 3 minutes for this design, so the hand calculation and
  the simulation are done while Vivado runs.
- A bitstream for `examples/spec_example.txt` is built before the demo as a backup.
- To change only input values there is no rebuild: reset, set SW, press LOAD.
