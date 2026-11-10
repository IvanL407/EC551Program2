# Program the Nexys4 DDR over USB without the GUI.
# Run from the repo folder (board plugged in and switched on):
#   "C:\Xilinx\Vivado\2024.1\bin\vivado.bat" -mode batch -source program.tcl
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set dev [lindex [get_hw_devices xc7a100t*] 0]
current_hw_device $dev
refresh_hw_device -update_hw_probes false $dev
set_property PROGRAM.FILE {build/top.bit} $dev
program_hw_devices $dev
puts "PROGRAMMED: build/top.bit"
close_hw_target
disconnect_hw_server
close_hw_manager
