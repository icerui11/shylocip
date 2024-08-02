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
set lib_exists [file exists shyloc_121]
if $lib_exists==1 {vdel -all -lib shyloc_121}
vlib shyloc_121
set lib_exists [file exists shyloc_utils]
if $lib_exists==1 {vdel -all -lib shyloc_utils}
vlib shyloc_utils
set lib_exists [file exists shyloc_123]
if $lib_exists==1 {vdel -all -lib shyloc_123}
vlib shyloc_123
set lib_exists [file exists post_syn_lib]
if $lib_exists==1 {vdel -all -lib post_syn_lib}
vlib post_syn_lib
vcom -work shyloc_123 -93 -explicit  $SRC/modelsim/tb_stimuli/28a_test/ccsds123_parameters.vhd
vcom -work shyloc_121 -93 -explicit  $SRC/modelsim/tb_stimuli/28a_test/ccsds121_parameters.vhd
do $SRC/modelsim/tb_scripts/ip_core.do
do $SRC/modelsim/tb_scripts/ip_core_block.do
vcom -work work -93 -explicit $SRC/modelsim/tb_stimuli/28a_test/ccsds123_tb_parameters.vhd
vcom -work work -93 -explicit $SRC/modelsim/tb_stimuli/28a_test/ccsds121_tb_parameters.vhd
do $SRC/modelsim/tb_scripts/testbench_shyloc.do
vsim -coverage work.ccsds_shyloc_tb(arch) -voptargs=+acc=bcglnprst+ccsds_shyloc_tb
#do waves/wave_shyloc.do
onbreak {resume}
run -all
