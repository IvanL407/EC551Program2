#!/bin/sh
# Simulate a generated design with Icarus Verilog.  usage: sim/run_sim.sh [gen_dir]
# 1) tb_hls_core.v : core only (4 input vectors)   2) testbench.v : whole board (buttons, switches, 7-seg)
set -e
cd "$(dirname "$0")/.."
G=${1:-gen}
iverilog -g2005 -o "$G/core.vvp" rtl/hls_fu.v "$G/hls_core.v" "$G/tb_hls_core.v"
vvp -n "$G/core.vvp"
iverilog -g2005 -o "$G/top.vvp" rtl/hls_fu.v rtl/debounce.v rtl/seg7_hex8.v rtl/top.v "$G/hls_core.v" "$G/testbench.v"
vvp -n "$G/top.vvp"
