# Build the bitstream without the Vivado GUI (non-project mode).
# Run from the repo folder:
#   "C:\Xilinx\Vivado\2024.1\bin\vivado.bat" -mode batch -source build.tcl
# Output: build/top.bit
set part xc7a100tcsg324-1
file mkdir build

read_verilog { rtl/hls_fu.v rtl/debounce.v rtl/seg7_hex8.v rtl/top.v gen/hls_core.v }
read_xdc constraints/Nexys4DDR_Master.xdc

synth_design -top top -part $part
opt_design
place_design
route_design
report_utilization -file build/utilization.txt
report_timing_summary -file build/timing.txt
write_bitstream -force build/top.bit
puts "BUILD COMPLETE: build/top.bit"
