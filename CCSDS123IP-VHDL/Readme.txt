***********************************************
***********  CCSDS 123 IP CORE  ***************
***********************************************

0. Requirements

0.1. Simulations require GRLIB 1.5.0-b4164; and the environment variables:
	- $GRLIB -> path to the folder where the GRLIB library is installed.
	- $MODEL_TECH -> path to the Questa/ModelSim libraries.
	- Your $PATH variable shall contain the path to the vsim command. 

0.2. Synthesis with Synplify requires:
	- Your $PATH variable shall contain the path to the synplify command.

0.3. Synthesis with ISE requires:
	- Your $PATH variable shall contain the path to the ise command. 
	
SIMULATIONS AND SYNTHESIS HAVE BEEN PERFORMED USING THE FOLLOWING SOFTWARE VERSIONS:
* QuestaSim 10.4c
* Synplify Premier with DP 2018.03
* Xilinx ISE 14.7

1. VHDL database:

CCSDS123IP-VHDL
+---images
¦   +---compressed
¦   +---raw
¦   +---reference
+---modelsim
¦   +---cover
¦   +---tb_scripts
¦   +---tb_stimuli
+---src
¦   +---post_syn
¦   +---shyloc_123
¦   +---shyloc_utils
¦   ¦   +---edac-0-7-src
¦   +---tb
¦       +---shyloc
+---synthesis
¦   +---premap_parameters
¦   +---syn_scripts
¦       +---synplify
¦           +---report
+---verification_scripts


2. To run simulations, first download the raw and reference images from: 

http://nasdsi.iuma.ulpgc.es/

Folder:

/TRPAO8032-shared/WP3/123/images

3. Launch the makefile:

For simulations:

$ make ccsds123

By default, simulation testcases are taken from file testcases_123_e_all.csv. To select an alternate configuration file, please assign the new configuration file name (without extension) to the variable "csv_sim" when invoking this target

For synthesis with Synplify:

$ make synplify

For synthesis with ISE:

$ make ise

For synthesis with Desogn Compiler:

$ make dc

For synthesis with NanoXmap:

$ make brave

By default, synthesis configurations are taken from file synthesis_params_123_e.csv. To select an alternate configuration file, please assign the new configuration file name (without extension) to the variable "csv_syn" when invoking any of these targets