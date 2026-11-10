@echo off
rem Simulate with Vivado's simulator (xsim) on Windows.  usage: sim\run_xsim.bat [gen_dir]
rem 1) tb_hls_core.v : core only (4 input vectors)   2) testbench.v : whole board (buttons, switches, 7-seg)
setlocal
cd /d "%~dp0\.."
set G=%~1
if "%G%"=="" set G=gen
set VIV=C:\Xilinx\Vivado\2024.1\bin
if defined XILINX_VIVADO set VIV=%XILINX_VIVADO%\bin

echo ===== core testbench =====
call "%VIV%\xvlog.bat" rtl\hls_fu.v %G%\hls_core.v %G%\tb_hls_core.v
if errorlevel 1 goto fail
call "%VIV%\xelab.bat" tb_hls_core -s core_sim
if errorlevel 1 goto fail
call "%VIV%\xsim.bat" core_sim -R
if errorlevel 1 goto fail

echo ===== board testbench =====
call "%VIV%\xvlog.bat" rtl\hls_fu.v rtl\debounce.v rtl\seg7_hex8.v rtl\top.v %G%\hls_core.v %G%\testbench.v
if errorlevel 1 goto fail
call "%VIV%\xelab.bat" testbench -s top_sim
if errorlevel 1 goto fail
call "%VIV%\xsim.bat" top_sim -R
if errorlevel 1 goto fail
echo Look for the two PASS lines above.
exit /b 0

:fail
echo SIMULATION SCRIPT STOPPED ON AN ERROR (see message above)
exit /b 1
