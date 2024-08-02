set lib_exists [file exists work]
if $lib_exists==1 {vdel -all -lib work}
vlib work
set lib_exists [file exists grlib]
if $lib_exists==1 {vdel -all -lib grlib}
vlib grlib
set lib_exists [file exists techmap]
if $lib_exists==1 {vdel -all -lib techmap}
vlib techmap
set lib_exists [file exists gaisler]
if $lib_exists==1 {vdel -all -lib gaisler}
vlib gaisler
do $SRC/modelsim/tb_scripts/setGRLIB.do
#set IP test parameters
set lib_exists [file exists shyloc_123]
if $lib_exists==1 {vdel -all -lib shyloc_123}
vlib shyloc_123
set lib_exists [file exists post_syn_lib]
if $lib_exists==1 {vdel -all -lib post_syn_lib}
vlib post_syn_lib
vcom -work shyloc_123 -93 -explicit  $SRC/modelsim/tb_stimuli/72_test/ccsds123_parameters.vhd
do $SRC/modelsim/tb_scripts/ip_core.do
#set tb test parameters
vcom -work work -93 -explicit $SRC/modelsim/tb_stimuli/72_test/ccsds123_tb_parameters.vhd
do $SRC/modelsim/tb_scripts/testbench.do
vsim -coverage work.ccsds_shyloc_tb(arch) -voptargs=+acc=bcglnprst+ccsds_shyloc_tb
onbreak {resume}
#do wave.do
run -all
