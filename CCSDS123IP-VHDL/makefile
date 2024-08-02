csv_sim = testcases_123_e_all
csv_syn = synthesis_params_123_e
tech    = XC5VFX130T
tech_name = (Virtex5)
tech_list = XC5VFX130T, XQR5VFX130, A3PE3000, RTAX4000S, RT4G4150

help:
		@echo Please select target:
		@echo        make ccsds123: to run simulations
		@echo        make synplify: to run syntehsis with Synplify
		@echo        make ise: to run syntehsis with ISE
		@echo        make brave: to run synthesis with NanoXmap (Not supported in Windows)
		@echo        make dc: to run synthesis with Design Compiler
		@echo        make ccsds123_ps: to generate post-synthesis models with Synplify and run post-synthesis simulations
		@echo        make scripts_ccsds123: to generate only scripts for simulations
		@echo        make scripts_synplify: to generate only scripts for syntehsis with Synplify
		@echo        make scripts_ise: to generate only scripts for syntehsis with ISE
		@echo        make scripts_brave: to generate only scripts for synthesis with NanoXmap (Not supported in Windows)
		@echo        make scripts_dc: to generate only scripts for synthesis with Design Compiler
		@echo        make clean: to delete files generated for simulation
		@echo By default, configurations for simulation tests and synthesis runs are taken from files $(csv_sim).csv and $(csv_syn).csv respectively. To use an alternative configuration file, please assign its name (without extension) either to variable csv_sim (for simulation) or csv_syn (for synthesis) when executing any make target
		@echo Post-synthesis simulations are run using the target technology $(tech) $(tech_name) by default. Alternative target technologies can be selected by assigning variable tech when executing post-synthesis targets. Supported synthesis technologies are: $(tech_list)
ccsds123:
		@echo "Generate simluation scripts for testcases in $(csv_sim).csv and run simulations"
		cd verification_scripts && \
		python run_vhdl_tests_123.py $(csv_sim).csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL modelsim
		set savedDir [pwd]
		cd modelsim && \
		$(subs / \\ MODEL_TECH)vsim -c -do sim.do -do tb_scripts/all_tests.do -do end.do | grep -E "# Simulation finished,*|**** Verification report*" && \
		cd .. 
synplify:
		@echo "Generate synthesis scripts for configurations in $(csv_syn).csv and run synthesis with Synplify"
		cd verification_scripts && \
		python run_vhdl_tests_123.py $(csv_syn).csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL synplify
		set savedDir [pwd]
		cd synthesis/syn_scripts/synplify && \
		synplify_premier -batch all_synplify.tcl 
ise:
		@echo "Generate synthesis scripts for configurations in $(csv_syn).csv and run synthesis with ISE"
		cd verification_scripts && \
		python run_vhdl_tests_123.py $(csv_syn).csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL ise
		set savedDir [pwd]
		cd synthesis/syn_scripts/ise && \
		xtclsh all_ise.tcl
		
brave:
		@echo "Generate synthesis scripts for configurations in $(csv_syn).csv and run synthesis with NanoXmap"
		cd verification_scripts && \
		python run_vhdl_tests_123.py $(csv_syn).csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL brave
		set savedDir [pwd]
		cd synthesis/syn_scripts/brave && \
		nxpython3 all_nanoxplore.py
		
dc: scripts_dc
		@echo "Generate synthesis scripts for configurations in $(csv_syn).csv and run synthesis with Design Compiler"
		set savedDir [pwd]
		cd synthesis/syn_scripts/dc && \
		dc_shell -f all_dc.tcl
ccsds123_ps:
		@echo "Generate synthesis scripts for configurations in $(csv_sim).csv and generate post-synthesis models with Synplify using target technology $(tech)"
		cd verification_scripts && \
		python run_vhdl_tests_123.py $(csv_sim).csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL synplify-ps $(tech)
		set savedDir [pwd]
		cd synthesis/syn_scripts/synplify && \
		synplify_premier -batch all_synplify.tcl
		@echo "Generate simluation scripts for testcases in $(csv_sim).csv and run post-synthesis simulations"
		set savedDir [pwd]
		cd verification_scripts && \
		python run_vhdl_tests_123.py $(csv_sim).csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL modelsim-ps $(tech)
		set savedDir [pwd]
		cd modelsim && \
		$(subs / \\ MODEL_TECH)vsim -c -do sim.do -do tb_scripts/all_tests.do -do end.do | grep -E "# Simulation finished,*|**** Verification report*"
scripts_ccsds123:
		@echo "Generate simluation scripts for testcases in $(csv_sim).csv"
		cd verification_scripts && \
		python run_vhdl_tests_123.py $(csv_sim).csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL modelsim
scripts_synplify:
		@echo "Generate synthesis scripts for configurations in $(csv_syn).csv to be used with Synplify"
		cd verification_scripts && \
		python run_vhdl_tests_123.py $(csv_syn).csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL synplify
scripts_ise:
		@echo "Generate synthesis scripts for configurations in $(csv_syn).csv to be used with ISE"
		cd verification_scripts && \
		python run_vhdl_tests_123.py $(csv_syn).csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL ise
scripts_brave:
		@echo "Generate synthesis scripts for configurations in $(csv_syn).csv to be used with NanoXmap"
		cd verification_scripts && \
		python run_vhdl_tests_123.py $(csv_syn).csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL brave
scripts_dc:
		@echo "Generate synthesis scripts for configurations in $(csv_syn).csv to be used with Design Compiler"
		cd verification_scripts && \
		python run_vhdl_tests_123.py $(csv_syn).csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL dc
scripts_ps:
		@echo "Generate scripts for post-synthesis simulation flow with technology $(tech) using configurations in $(csv_sim).csv"
		cd verification_scripts && \
		python run_vhdl_tests_123.py $(csv_sim).csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL synplify-ps $(tech)
		cd verification_scripts && \
		python run_vhdl_tests_123.py $(csv_sim).csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL modelsim-ps $(tech)
clean_sim:
	-rm -rf modelsim/transcript
	-rm -rf modelsim/gaisler modelsim/grlib modelsim/shyloc_123 modelsim/shyloc_121 modelsim/shyloc_utils modelsim/post_syn_lib modelsim/tb modelsim/techmap modelsim/transcript modelsim/vcover.log modelsim/work
	-rm -rf modelsim/tb_scripts/*.do
	-rm -rf modelsim/cover/*.ucdb
	-find ./modelsim/tb_stimuli/ -mindepth 1 ! -name 'README.txt' -exec rm -rf {} +
clean_syn:
	-rm -rf *~ *.log
	-find ./synthesis/premap_parameters/ -mindepth 1 ! -name 'README.txt' -exec rm -rf {} +
	-find ./synthesis/syn_scripts/synplify/ -mindepth 1 -maxdepth 2 ! \( -name 'all_synplify_par.tcl' -o -name 'ccsds123_project.prj' -o -name 'ccsds123_project.fdc'-o -name 'report' -o -name 'README.txt' \) -exec rm -rf {} +
	-find ./synthesis/syn_scripts/ise -mindepth 1 ! \( -name 'ccsds123_project.prj.xise' \) -exec rm -rf {} +
	-rm -f ./synthesis/syn_scripts/dc/*.tcl
	-find ./synthesis/syn_scripts/dc/base -mindepth 1 ! \( -name 'dc_setup.tcl' -o -name 'dc.tcl' -o -name 'README.txt' \) -exec rm -rf {} +
	-find ./synthesis/syn_scripts/dc/report -mindepth 1 ! \( -name 'README.txt' \) -exec rm -rf {} +
	-find ./synthesis/syn_scripts/dc/results -mindepth 1 ! \( -name 'README.txt' \) -exec rm -rf {} +
clean_all: clean_sim clean_syn
	-find ./src/post_syn/ -mindepth 1 ! \( -name 'ccsds123_top_wrapper.vhd' \) -exec rm -rf {} +


