#!c:\Python27 python
# -*- coding: iso-8859-1 -*-

# All Distribution of the Software and/or Modifications, as Source Code or Object Code,
# must be, as a whole, under the terms of the European Space Agency Public License  v2.0.
# If You Distribute the Software and/or Modifications as Object Code, You must:
# (a) provide in addition a copy of the Source Code of the Software and/or
# Modifications to each recipient; or
# (b) make the Source Code of the Software and/or Modifications freely accessible by reasonable
# means for anyone who possesses the Object Code or received the Software and/or Modifications
# from You, and inform recipients how to obtain a copy of the Source Code.

# The Software is provided to You on an as is basis and without warranties of any
# kind, including without limitation merchantability, fitness for a particular purpose,
# absence of defects or errors, accuracy or non-infringement of intellectual property
# rights.
# Except as expressly set forth in the "European Space Agency Public License  v2.0",
# neither Licensor nor any Contributor shall be liable, including, without limitation, for direct, indirect,
# incidental, or consequential damages (including without limitation loss of profit),
# however caused and on any theory of liability, arising in any way out of the use or
# Distribution of the Software or the exercise of any rights under this License, even
# if You have been advised of the possibility of such damages.
#

# Some command line examples:
# run_vhdl_tests_123.py testcases_123.csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL modelsim
# run_vhdl_tests_123.py synthesis_params_123.csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL synplify
# run_vhdl_tests_123.py synthesis_params_123.csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL ise
# run_vhdl_tests_123.py synthesis_params_123.csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL vivado
# run_vhdl_tests_123.py synthesis_params_123_e.csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL brave
# run_vhdl_tests_123.py synthesis_params_123.csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL dc
# run_vhdl_tests_123.py testcases_123_post_syn.csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL modelsim-ps XC5VFX130T
# run_vhdl_tests_123.py testcases_123_post_syn.csv ../images/raw ../images/compressed ../images/reference ../ ../../CCSDS121IP-VHDL synplify-ps XC5VFX130T


#How to run this script
#  run_vhdl_tests_123.py 
#(1) *.csv file containing the desired parameters
#(2) path to the folder containing the raw images that will be compressed during the simulation
#(3) path to the folder where the compressed images will be stored
#(4) path to the folder containing the reference compressed images
#(5) IP core database folder CCSDS123
#(6) IP core database folder CCSDS121
#(7) select one among the possible options: 
#modelsim --> generates TCL scripts for simulations
#synplify --> generates TCL scripts for synthesis with synplify
#ise --> generates TCL scripts for synthesis with ise
#vivado --> generates TCL scripts for synthesis with vivado
#dc --> generates TCL scripts for synthesis with dc (Design Compiler)
#modelsim-ps --> generates TCL scripts for post-synthesis simulations
#synplify-ps --> generates TCL scripts for synthesis with synplify, stores post-synthesis model
#(7) if specified, select on which technology to perform the synthesis or post-synthesis simulations (applicable to options: 
# modelsim-ps, synplify-ps. It can be one among these options
#XC5VFX130T
#XQR5VFX130
#A3PE3000
#RTAX4000S
#RT4G4150

############################ New by Antonio ################################
# Now the parameter HMAXBURST is configured from the csv file instead of being set to a fixed value
############################################################################

import sys, os, csv, glob, filecmp, shutil
from shutil import copyfile
from os.path import sep

if __name__ == "__main__":
  #print len(sys.argv)
  print('*****************************************\n')
  if len(sys.argv) < 6:
    raise Exception('Error, the command line for running the tests is: run_vhdl_tests_123.py (1) csv_parameters_file (2) original_img_folder (3) compressed_img_folder (4) reference_img_folder (5) IP core 123 database folder (6) IP core 121 database folder (7) modelsim')
  try:
    print('Opening csv configuration file: ' + sys.argv[1] + '\n')
    csv_file_handle = open(sys.argv[1], 'rb')
  except IOError as e:
    print "I/O error({0}): {1}".format(e.errno, e.strerror)
    raise Exception('Error in opening file ' + sys.argv[1])
  if not os.path.exists(sys.argv[2]):
    print ('Folder ' + sys.argv[3] + ' not existing -> It will be automatically created')
    comp_folder = sys.argv[3]
    os.makedirs(comp_folder)
  if not os.path.exists(sys.argv[3]):
    csv_file_handle.close()
    raise Exception('Folder ' + sys.argv[3] + ' not existing')
  if not os.path.exists(sys.argv[4]):
    csv_file_handle.close()
    raise Exception('Folder ' + sys.argv[4] + ' not existing')
  if not os.path.exists(sys.argv[5]):
    csv_file_handle.close()
    raise Exception('Folder ' + sys.argv[5] + ' not existing')
  if not os.path.exists(sys.argv[6]):
    csv_file_handle.close()
    raise Exception('Folder ' + sys.argv[6] + ' not existing')
  gen_simulation = False
  gen_synplify = False
  gen_ise = False
  gen_vivado = False
  gen_dc = False
  gen_post_syn = False
  gen_brave = False
  print('*****************************************\n')
  if len(sys.argv) >= 8:
    if sys.argv[7]== "modelsim" or sys.argv[7]== "modelsim-ps":
      gen_simulation = True
      print "Generating parameters files (*.vhd) and simulation files for QuestaSim (*.do)"
    elif sys.argv[7] == "synplify" or sys.argv[7] == "synplify-ps":
      gen_synplify = True
      print "Generating parameters files (*.vhd) and synthesis scripts for Synplify (*.tcl)"
    elif sys.argv[7] == "ise":
      gen_ise = True
      print "Generating parameters files (*.vhd) and synthesis scripts for ISE (*.tcl)"
    elif sys.argv[7] == "vivado":
      gen_vivado = True
      print "Generating parameters files (*.vhd) and synthesis scripts for Vivado (*.tcl)"
    elif sys.argv[7] == "dc":
      gen_dc = True
      print "Generating parameters files (*.vhd) and synthesis scripts for Design Compiler (*.tcl)"
    elif sys.argv[7] == "brave":
      gen_brave = True
      print "Generating parameters files (*.vhd) and synthesis scripts for NanoXplore NanoXmap (*.py)"
  elif len(sys.argv) == 7:
    print "Generating only parameters files"
  imp_names = ['XC5VFX130T', 'XQR5VFX130', 'A3PE3000', 'RTAX4000S', 'RT4G4150','NX1H35S','NX1H140TSP']
  technologies = ['Virtex5', 'QProRVirtex5', 'ProASIC3E', 'Axcelerator', 'RTG4','NG-MEDIUM','NG-LARGE']
  # Modified by AS: imp_names_print not required anymore
  #imp_names_print = ['XC5VFX130T, ', 'XQR5VFX130, ', 'A3PE3000, ', 'RTAX4000S, ', 'RT4G4150','NX1H35S','NX1H140TSP']
  # Modified by AS: Brave fpga technologies not supported yet for ps-simulations
  imp_names_ps = imp_names[0:5]
  technologies_ps = technologies[0:5]
  #####################
  if len(sys.argv) > 7:
    if sys.argv[7] == "modelsim-ps" or sys.argv[7] == "synplify-ps":
      gen_post_syn = True
      print('*****************************************\n')
      print "You have selected to generate scripts for post-synthesis simulations\n"
      print('*****************************************\n')
    if sys.argv[7] == "modelsim-ps" and  len(sys.argv) == 8:
      # Modified by AS: Brave fpga technologies not supported yet for ps-simulations
      raise Exception ('Technology selection is required for post-syntehsis simulations, please choose among: ' + ', '.join(imp_names_ps) + '\n' + 'Example: ' + sys.argv[0] + ' ' + sys.argv[1] + ' ' + sys.argv[2] + ' ' + sys.argv[3] + ' ' + sys.argv[4] + ' ' + sys.argv[5] + ' ' + sys.argv[6] + ' ' + sys.argv[7] + ' XC5VFX130T\n')
    if len(sys.argv) == 9:
      #print "9 arguments!!!!!"
      # Modified by AS: Brave fpga technologies not supported yet for ps-simulations
      if not sys.argv[8] in imp_names_ps:
        raise Exception ('Selected implementation name is not valid, please choose among: ' + ', '.join(imp_names_ps) + '\n' + 'Example: ' + sys.argv[0] + ' ' + sys.argv[1] + ' ' + sys.argv[2] + ' ' + sys.argv[3] + ' ' + sys.argv[4] + ' ' + sys.argv[5] + ' ' + sys.argv[6] + ' ' + sys.argv[7] + ' XC5VFX130T\n')
      #######################
      else:
        print ('Selected technology is ' + sys.argv[8] + '. Scripts will be created to run synthesis or simulations for this technology only:\n')
        imp_names_ps = [imp_names[imp_names.index(sys.argv[8])]]
        technologies_ps = [technologies[imp_names.index(sys.argv[8])]]
        print imp_names_ps
        print technologies_ps
    else:
      if not gen_dc and gen_post_syn == True:
        # Modified by AS: Display of target technologies fixed
        print ('Target technology not specified. Scripts will be created to run synthesis on: '+ ', '.join(imp_names_ps) + '.\n')
  raw_folder = os.path.abspath(sys.argv[2])
  compressed_folder = os.path.abspath(sys.argv[3])
  reference_folder = os.path.abspath(sys.argv[4]) 
  database_folder = os.path.abspath(sys.argv[5])
  database_121_folder = os.path.abspath(sys.argv[6])
################################################################################
#Generate basic scripts for synthesis or simulations
################################################################################
  try:
    print('Opening list of targets\n')
    csv_file_handle = open(os.path.join(database_folder, 'src', 'shyloc_123', 'targets_list.csv'), 'rb')
    csv_file_handle_block = open(os.path.join(database_121_folder, 'src', 'shyloc_121', 'targets_list.csv'), 'rb')
  except IOError as e:
    print "I/O error({0}): {1}".format(e.errno, e.strerror)
    print "Incomplete database: the csv list of targets does not exist"
    raise Exception('Error in opening file ' + database_folder + 'targets_list.csv')
  csv_reader = csv.reader(csv_file_handle, delimiter=',')
  if gen_simulation:
    print('***Preparing *.do files for modelsim.......\n')
    ########################################################################
    # Generate setGRLIB.do file
    ########################################################################
    destination_folder = os.path.join(database_folder , 'modelsim', 'tb_scripts')
    if not os.path.exists(destination_folder):
      print ("Creating folder for simulation/synthesis scripts: " + destination_folder)
      os.makedirs(destination_folder)
    filename_scripts = os.path.join(database_folder , 'modelsim', 'tb_scripts', 'setGRLIB.do')
    file_scripts = open(filename_scripts, 'w')
    synList = ['grlib $GRLIB/lib/grlib/stdlib/version.vhd',
           'grlib $GRLIB/lib/grlib/stdlib/config_types.vhd',
           'grlib $GRLIB/lib/grlib/stdlib/config.vhd',
           'grlib $GRLIB/lib/grlib/stdlib/stdlib.vhd',
           'grlib $GRLIB/lib/grlib/stdlib/stdio.vhd',
           'grlib $GRLIB/lib/grlib/stdlib/testlib.vhd',
           'grlib $GRLIB/lib/grlib/amba/amba.vhd',
           'grlib $GRLIB/lib/grlib/amba/devices.vhd',
           'grlib $GRLIB/lib/grlib/amba/defmst.vhd',
           'techmap $GRLIB/lib/techmap/gencomp/gencomp.vhd',
           'techmap $GRLIB/lib/techmap/inferred/memory_inferred.vhd',
           'techmap $GRLIB/lib/techmap/maps/allmem.vhd',
           'techmap $GRLIB/lib/techmap/maps/syncram.vhd',
           'gaisler $GRLIB/lib/gaisler/misc/misc.vhd']

    cmdList = ''
    for f in synList:
      cmdList = cmdList + "vcom -work %s\n" % (f)
           
    file_scripts.write(cmdList)
    file_scripts.close()    
    ########################################################################
    # Generate testbench.do file
    ########################################################################
    destination_folder = os.path.join(database_folder , 'modelsim', 'tb_scripts')
    if not os.path.exists(destination_folder):
      print ("Creating folder for simulation/synthesis scripts: " + destination_folder)
      os.makedirs(destination_folder)
    filename_scripts = os.path.join(database_folder , 'modelsim', 'tb_scripts', 'testbench.do')
    file_scripts = open(filename_scripts, 'w')
    synList = ['work $SRC/src/tb/ahbtbp.vhd',
           'work $SRC/src/tb/ahbtbs.vhd',
           'work $SRC/src/tb/ahbtbm.vhd',
           'work $SRC/src/tb/ahbctrl.vhd',
           'work $SRC/src/tb/ccsds_ahbtbp.vhd',
           'work $SRC/src/tb/ccsds_shyloc_tb.vhd']
    cmdList = ''
    for f in synList:
      cmdList = cmdList + "vcom -work %s\n" % (f)
           
    file_scripts.write(cmdList)
    file_scripts.close()
    ########################################################################
    # Generate testbench_shyloc.do file
    ########################################################################
    destination_folder = os.path.join(database_folder , 'modelsim', 'tb_scripts')
    if not os.path.exists(destination_folder):
      print ("Creating folder for simulation/synthesis scripts: " + destination_folder)
      os.makedirs(destination_folder)
    filename_scripts = os.path.join(database_folder , 'modelsim', 'tb_scripts', 'testbench_shyloc.do')
    file_scripts = open(filename_scripts, 'w')
    synList = ['work $SRC/src/tb/ahbtbp.vhd',
           'work $SRC/src/tb/ahbtbs.vhd',
           'work $SRC/src/tb/ahbtbm.vhd',
           'work $SRC/src/tb/ahbctrl.vhd',
           'work $SRC/src/tb/ccsds_ahbtbp.vhd',
           'work $SRC/src/tb/shyloc/ccsds_shyloc_tb.vhd']
    
    cmdList = ''
    for f in synList:
      cmdList = cmdList + "vcom -work %s\n" % (f)

    #file_scripts.write('vcom $SRC/src/tb/ahbtbp.vhd\n'+
  # 'vcom $SRC/src/tb/ahbctrl.vhd\n'+
  # 'vcom $SRC/src/tb/ahbtbs.vhd\n' +
  # 'vcom $SRC/src/tb/ahbtbm.vhd\n' +
  # 'vcom $SRC/src/tb/ccsds_ahbtbp.vhd\n' +
  # 'vcom ')
    file_scripts.write(cmdList)
    file_scripts.close()
########################################################################
# Generate ip_core.do file
########################################################################
    destination_folder = os.path.join(database_folder , 'modelsim', 'tb_scripts')
    if not os.path.exists(destination_folder):
      print ("Creating folder for simulation/synthesis scripts: " + destination_folder)
      os.makedirs(destination_folder)
    file_script = open (os.path.join(destination_folder, 'ip_core.do'), 'w')
    file_script_block = open (os.path.join(destination_folder, 'ip_core_block.do'), 'w')
  elif gen_synplify:
    print('***Preparing *.tcl files for synplify.......\n')
    destination_folder = os.path.join(database_folder, 'synthesis', 'syn_scripts', 'synplify')
    if not os.path.exists(destination_folder):
      print ("Creating folder for simulation/synthesis scripts: " + destination_folder)
      os.makedirs(destination_folder)
    file_script = open (os.path.join(destination_folder, 'add_ip_core.tcl'), 'w')
    file_script.write('puts "Adding IP core VHDL files"\n')
  elif gen_ise:
    print('***Preparing *.tcl files for ise.......\n')
    destination_folder = os.path.join(database_folder, 'synthesis' , 'syn_scripts', 'ise')
    if not os.path.exists(destination_folder):
      print ("Creating folder for simulation/synthesis scripts: " + destination_folder)
      os.makedirs(destination_folder)
    file_script = open (os.path.join(destination_folder, 'add_ip_core.tcl'), 'w')
    file_script.write('puts "Adding IP core VHDL files"\n')
  elif gen_vivado:
    print('***Preparing *.tcl files for VIVADO.......\n')
    destination_folder = os.path.join(database_folder, 'synthesis' , 'syn_scripts', 'VIVADO')
    if not os.path.exists(destination_folder):
      print ("Creating folder for simulation/synthesis scripts: " + destination_folder)
      os.makedirs(destination_folder)
    file_script = open (os.path.join(destination_folder, 'add_ip_core.tcl'), 'w')
    file_script.write('puts "Adding IP core VHDL files"\n')
  elif gen_brave:
    print('***Preparing *.py files for nanoxmap.......\n')
    destination_folder = os.path.join(database_folder, 'synthesis' , 'syn_scripts', 'brave')
    if not os.path.exists(destination_folder):
        print ("Creating folder for simulation/synthesis scripts: " + destination_folder)
        os.makedirs(destination_folder)
    file_script = open (os.path.join(destination_folder, 'add_ip_core.py'), 'w')
    file_script.write("#Adding IP core VHDL files\n")
  elif gen_dc:
    print('***Preparing *.tcl files for Design Compiler.......\n')
    scripts_folder = os.path.join(database_folder, 'synthesis', 'syn_scripts', 'dc')
    if not os.path.exists(scripts_folder):
      print ("Creating folder for simulation/synthesis scripts: " + scripts_folder)
      os.makedirs(scripts_folder)
    file_script = open (os.path.join(scripts_folder, 'add_ip_core.tcl'), 'w')
    file_script.write('puts "Adding IP core VHDL files"\n')
  ########################################################################
  # Read list of targets and generate script ip_core.do
  ########################################################################
  csv_reader = csv.reader(csv_file_handle, delimiter=',')
  csv_reader.next()
  csv_reader.next()
  # Get libraries
  ip_libraries = set()
  for row in csv_reader:
    ip_libraries.add(row[3])
    #
    if gen_simulation:
      # Defaults
      vcmd   = 'vcom'
      vflags   = '-93 -quiet  -check_synthesis'
      covflags = '-nocoverfec -cover sbcf3 -coverexcludedefault'
      
      # Check if it's a VHDL or a Verilog source, based on the file extension
      fileType = row[1].split('.')[-1].rstrip()
      if fileType == 'vhd':
        pass
      elif fileType == 'v':
        vcmd = 'vlog'
        vflags = '-quiet '
      else:
         print "Unkown file type: " + fileType
         print row

      # Coverage Flags
      if row[2] == "y":
        covflags = ''
         
      # Process remaining rows
      vstr = "%s %s -work %s %s $SRC/src/%s\n" % (vcmd, vflags, row[3], covflags, row[1])
      file_script.write(vstr)
    elif gen_synplify:
      file_script.write('add_file -lib ' + row[3]+ ' -vhdl $SRC/src/'+ row[1] +'\n')
    elif gen_ise:
      file_script.write('xfile add $SRC/src/'+ row[1] +' -lib_vhdl ' + row[3] + '\n')
    elif gen_vivado:
      file_script.write('add_files -norecurse $SRC/src/' + row[1] + '\n')
      file_script.write('set_property library ' + row[3] + ' [get_files  $SRC/src/' + row[1] + ']' + '\n')
    elif gen_brave:
          database_folder_changed = database_folder.replace(sep, '/')
          file_script.write("nano123.addFile('"+row[3]+"',os.path.join(SRC,'src','"+row[1]+"'))\n")
    elif gen_dc:
      file_script.write('analyze -f VHDL -library ' + row[3]+ ' $SRC/src/'+ row[1] +'\n')
  csv_file_handle.close()
  #file_script.close()
  #
  # Design Compiler requires the libraries to be created before
  if gen_dc:
    file_script_libs = open (os.path.join(scripts_folder, 'setupLibs.tcl'), 'w')
    ip_buff = "# Create the libraries\n"
    ip_buff += 'puts "Creating the libraries"\n'
    for l in ip_libraries:
      ip_buff += 'catch {sh mkdir ${RESULTS_DIR}/elab/' + l + '}\n'
      ip_buff += 'define_design_lib ' + l + ' -path ${RESULTS_DIR}/elab/' + l + '\n\n'
    file_script_libs.write(ip_buff)
    file_script_libs.close()
  ########################################################################
  # End of Generate ip_core.do file
  ########################################################################
  ########################################################################
  # Read list of targets and generate script ip_core_block.do
  ########################################################################
  csv_reader = csv.reader(csv_file_handle_block, delimiter=',')
  csv_reader.next()
  csv_reader.next()
  for row in csv_reader:
    if gen_simulation:
      if row[3] != "shyloc_utils":
        if row[2] == "y":
          file_script_block.write('vcom -93 -quiet -check_synthesis -work ' + row[3] + ' ' + '$SRC121/src/'+ row[1] +'\n')
        else:
          file_script_block.write('vcom -93 -quiet -check_synthesis -work ' + row[3] + ' ' + '-nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/'+ row[1] +'\n')
    #elif gen_synplify:
    # file_script_block.write('add_file -lib ' + row[3]+ ' -vhdl $SRC121/src/'+ row[1] +'\n')
    #elif gen_ise:
    # file_script_block.write('xadd $SRC121/src/'+ row[1] +'\n')
  csv_file_handle_block.close()
  ########################################################################
  # End of Read list of targets and generate script ip_core_block.do
  ########################################################################
#Read parameters for simulation or synthesis and generate corresponding *.vhd and *.do or *.tcl for each test case
  csv_file_handle = open(sys.argv[1], 'rb')
  if gen_simulation:
    stimuli_folder = os.path.join(database_folder, 'modelsim', "tb_stimuli")
  else:
    stimuli_folder = os.path.join(database_folder, 'synthesis', 'premap_parameters')
  csv_reader = csv.reader(csv_file_handle, delimiter=',')
  csv_reader.next()
  csv_reader.next()
  print('*****************************************\n')
  for row in csv_reader:
    print(' Test: ' + row[0] + ';'),
    ########################################################################
    # Generate file ccsds123_parameters.vhd
    ########################################################################
    destination_folder = os.path.join(stimuli_folder, row[0])
    if not os.path.exists(destination_folder):
      os.makedirs(destination_folder)
    #print('***Preparing Generic Parameters file ccsds123_parameters.vhd.......\n')
    destination_folder_param = os.path.join(destination_folder, 'ccsds123_parameters.vhd')
    file_gen_param = open (destination_folder_param, 'w')
    #content of file ccsds123_parameters.vhd
    file_gen_param.write('\n\nlibrary ieee;\nuse ieee.std_logic_1164.all;\nuse ieee.numeric_std.all;\n')
    file_gen_param.write('package ccsds123_parameters is\n')
    file_gen_param.write('\n-- TEST: ' + row [0]  + '\n')
    file_gen_param.write('\n--SYSTEM\n')
    set = row[10]
    file_gen_param.write('  constant EN_RUNCFG: integer  := ' + row[11] +';')
    file_gen_param.write('        --! --! (0) Disables runtime configuration; (1) Enables runtime configuration.\n')
    file_gen_param.write('  constant RESET_TYPE : integer := ' + row[12] +';')
    file_gen_param.write('        --! (0) Asynchronous reset; (1) Synchronous reset.\n')
    file_gen_param.write('  constant EDAC: integer  :=  ' + row[13] +';')
    file_gen_param.write('          --! (0) Inhibits EDAC implementation; (1) EDAC is implemented.\n')
    if row[9] == "bip":
      file_gen_param.write('  constant PREDICTION_TYPE: integer := 0;')
    elif row[9] == "bsq":
      file_gen_param.write('  constant PREDICTION_TYPE: integer := 2;')
    elif row[9] == "bip-mem":
      file_gen_param.write('  constant PREDICTION_TYPE: integer := 1;')
        # Modified by AS: bil-mem architecture included in the prediction_type options
    elif row[9] == "bil-mem":
      file_gen_param.write('  constant PREDICTION_TYPE: integer := 4;')
        ##########################
    else:       # bil
      file_gen_param.write('  constant PREDICTION_TYPE: integer := 3;')
    file_gen_param.write('          --! (0) BIP-base architecture; (1) BIP-mem architecture; (2) BSQ architecture; (3) BIL architecture; (4) BIL-mem architecture.\n')
    file_gen_param.write('  constant ENCODING_TYPE: integer  := ' + row[15] +';')
    file_gen_param.write('      --! (0) Only pre-processor is implemented (external encoder can be attached); (1) Sample-adaptive encoder implemented.\n')
    file_gen_param.write('--AHB\n')
    file_gen_param.write('\n--slave\n')
    file_gen_param.write('  constant HSINDEX_123: integer := 1;')
    file_gen_param.write('              --! AHB slave index.\n')
    file_gen_param.write('  constant HSCONFIGADDR_123: integer := 16#200#;')
    file_gen_param.write('        --! ADDR field of the AHB Slave.\n')
    file_gen_param.write('  constant HSADDRMASK_123: integer := 16#FFF#;')
    file_gen_param.write('        --! MASK field of the AHB slave.\n')
    file_gen_param.write('\n--master\n')
    file_gen_param.write('  constant HMINDEX_123: integer := 1;')
    file_gen_param.write('              --! AHB master index.\n')
      # Modified by AS: HMAXBURST read from the csv file if the field has a valid value
    if (row[76] and (int(row[76]) > 0) and (int(row[76]) <= 16)):
      file_gen_param.write('  constant HMAXBURST_123: integer := ' + row[76] + ';')
    elif (row[76] and (int(row[76]) == 0)):
      file_gen_param.write('  constant HMAXBURST_123: integer := 16;')
    else: # invalid HMAXBURST config means that ahb bursts are disabled
      file_gen_param.write('  constant HMAXBURST_123: integer := 1;')
        #####################
    file_gen_param.write('            --! AHB master burst beat limit.\n')
    file_gen_param.write('  constant ExtMemAddress_GEN: integer := ' + row[63] + ';')
    file_gen_param.write('        --! External memory address.\n')
    file_gen_param.write('\n--IMAGE')
    if (row[10] == '0'):
      if ((row[4] == row[55] or row[4] == "N/A") and (row[3] == row[54] or row[3] == "N/A") and (row[5] == row[56] or row[5] == "N/A") and (row[6] == row[57] or row[6] == "N/A") and (row[8] == row[59] or row[8] == "N/A") or (row[7] == row[58] or row[7] == "N/A")):
        file_gen_param.write('\n  constant Nx_GEN: integer := ' + row[4] + ';')
        file_gen_param.write('          --! Maximum allowed number of samples in a line.\n')
        file_gen_param.write('  constant Ny_GEN: integer := ' + row[3] + ';')
        file_gen_param.write('          --! Maximum allowed number of samples in a row.\n')
        file_gen_param.write('  constant Nz_GEN: integer := ' + row[5] + ';')
        file_gen_param.write('          --! Maximum allowed number of bands.\n')
        file_gen_param.write('  constant D_GEN: integer := ' + row[6] + ';')
        file_gen_param.write('            --! Maximum dynamic range of the input samples.\n')
        file_gen_param.write('  constant IS_SIGNED_GEN: integer := ')
        if row[7] == "uint":
          file_gen_param.write('0;')
        else: 
          file_gen_param.write('1;')
        file_gen_param.write('        --! (0) Unsigned samples; (1) Signed samples.\n')
        if row[8] == "le":
          file_gen_param.write('  constant ENDIANESS_GEN: integer := 0;')
        else:
          file_gen_param.write('  constant ENDIANESS_GEN: integer := 1;')
        file_gen_param.write('        --! (0) Little-Endian; (1) Big-Endian.\n\n')
      else: 
        raise Exception('Image configuration is not consistent for test_id: '  + row[0] + ' (EN_RUNCFG = 0).')
    else: 
      file_gen_param.write('\n  constant Nx_GEN: integer := ' + row[55] + ';')
      file_gen_param.write('          --! Maximum allowed number of samples in a line.\n')
      file_gen_param.write('  constant Ny_GEN: integer := ' + row[54] + ';')
      file_gen_param.write('          --! Maximum allowed number of samples in a row.\n')
      file_gen_param.write('  constant Nz_GEN: integer := ' + row[56] + ';')
      file_gen_param.write('          --! Maximum allowed number of bands.\n')
      file_gen_param.write('  constant D_GEN: integer := ' + row[57] + ';')
      file_gen_param.write('            --! Maximum dynamic range of the input samples.\n')
      file_gen_param.write('  constant IS_SIGNED_GEN: integer := ')
      if row[58] == "uint":
        file_gen_param.write('0;')
      else: 
        file_gen_param.write('1;')
      file_gen_param.write('        --! (0) Unsigned samples; (1) Signed samples.\n')
      if row[59] == "le":
        file_gen_param.write('  constant ENDIANESS_GEN: integer := 0;')
      else:
        file_gen_param.write('  constant ENDIANESS_GEN: integer := 1;')
      file_gen_param.write('        --! (0) Little-Endian; (1) Big-Endian.\n\n')
    file_gen_param.write('  constant DISABLE_HEADER_GEN: integer := ' + row[16] + ';')
    file_gen_param.write('      --! Selects whether to disable (1) or not (0) the header.\n')
     #file_gen_param.write('  constant W_ADDR_IN_IMAGE: integer := 16;\n')
    file_gen_param.write('\n--PREDICTOR\n')
    file_gen_param.write('  constant P_MAX: integer := ' + row[18] + ';')
    file_gen_param.write('            --! Number of bands used for prediction.\n')
    file_gen_param.write('  constant PREDICTION_GEN: integer := ' + row[19] + ';')
    file_gen_param.write('        --! Full (0) or reduced (1) prediction.\n')
    file_gen_param.write('  constant LOCAL_SUM_GEN: integer := ' + row[20] + ';')
    file_gen_param.write('        --! Neighbour (0) or column (1) oriented local sum.\n')
    file_gen_param.write('  constant OMEGA_GEN: integer := ' + row[21] + ';')
    file_gen_param.write('          --! Weight component resolution.\n')
    file_gen_param.write('  constant R_GEN: integer := ' + row[22] + ';')
    file_gen_param.write('            --! Register size.\n\n')
    file_gen_param.write('  constant VMAX_GEN: integer := ' + row[23] + ';')
    file_gen_param.write('          --! Factor for weight update.\n')
    file_gen_param.write('  constant VMIN_GEN: integer := ' + row[24] + ';')
    file_gen_param.write('          --! Factor for weight update.\n')
    file_gen_param.write('  constant T_INC_GEN: integer := ' + row[25] + ';')
    file_gen_param.write('          --! Weight update factor change interval.\n')
    file_gen_param.write('  constant WEIGHT_INIT_GEN: integer := 0;')
    file_gen_param.write('        --! Weight initialization mode.\n')
    file_gen_param.write('  constant ENCODER_SELECTION_GEN: integer := ' + row[61] + ';')
    file_gen_param.write('    --! (0) Disables encoding; (1) Selects sample-adaptive coder; (2) Selects external encoder (Block-Adaptive).\n')
    file_gen_param.write('  constant INIT_COUNT_E_GEN: integer := ' + row[28] + ';')
    file_gen_param.write('      --! Initial count exponent.\n')
    file_gen_param.write('  constant ACC_INIT_TYPE_GEN: integer := ' + row[29] + ';')
    file_gen_param.write('      --! Accumulator initialization type.\n')
    file_gen_param.write('  constant ACC_INIT_CONST_GEN: integer := ' + row[30] + ';')
    file_gen_param.write('      --! Accumulator initialization constant.\n')
    file_gen_param.write('  constant RESC_COUNT_SIZE_GEN: integer := ' + row[31] + ';')
    file_gen_param.write('      --! Rescaling counter size.\n')
    file_gen_param.write('  constant U_MAX_GEN: integer := ' + row[32] + ';')
    file_gen_param.write('          --! Unary length limit.\n')
    file_gen_param.write('  constant W_BUFFER_GEN: integer := ' + row[17] + ';')
    file_gen_param.write('        --! Bit width of the output buffer.\n\n')
    file_gen_param.write('  constant Q_GEN: integer := 5;')
    file_gen_param.write('                      --! Weight initialization resolution.\n')
     # Modified by AS: generating CWI parameters with default values
    file_gen_param.write('  constant CWI_GEN: integer := 0;')
    file_gen_param.write('                      --! Custom Weight Initialization mode.\n\n')
    #######################
    file_gen_param.write('  constant TECH: integer := ' + row[75] + ';')
    file_gen_param.write('            --! Selects the memory type.\n\n')
    file_gen_param.write('end ccsds123_parameters;\n')
    file_gen_param.close()
    ########################################################################
    # End of Generate file ccsds123_parameters.vhd
    ########################################################################
    #create a copy of the generated file in the database folder: ensures consistency
    copyfile(destination_folder_param, os.path.join(database_folder, 'ccsds123_parameters.vhd'))
    if gen_simulation:
      ########################################################################
      # Generate file ccsds123_tb_parameters.vhd
      ########################################################################
      #print('***Preparing Testbench Parameters file ccsds123_tb_parameters.......\n')
      destination_folder = os.path.join(stimuli_folder, row[0])
      destination_folder_param = os.path.join(destination_folder, 'ccsds123_tb_parameters.vhd')
      file_conf_param = open (destination_folder_param, 'w')
      file_conf_param.write('\n\nlibrary ieee;\nuse ieee.std_logic_1164.all;\nlibrary shyloc_123;\nuse shyloc_123.ccsds123_parameters.all;\nlibrary shyloc_utils;\n use shyloc_utils.shyloc_functions.all;\n\n')
      file_conf_param.write('package ccsds123_tb_parameters is\n')
      raw_file = os.path.join(raw_folder, row[2])
      file_conf_param.write('     constant stim_file: string :="' + raw_file +'";\n')
      ref_file = os.path.join(reference_folder, row[62])
      file_conf_param.write('     constant ref_file: string := "' + ref_file + '";\n')
      file_name = row[62] + ".vhd"
      file_conf_param.write('     constant out_file: string := "' + compressed_folder + '\\' + file_name + '";\n')
      
      file_conf_param.write('\n-- TEST: ' + row [0]  + '\n')
      if row[0] == "04_test" or row[0] == "04_testPS" or row[0] == "04_Test" or row[0] == "04_TestPS":
        file_conf_param.write('     constant test_id: integer := 4;\n\n')
      elif row[0] == "05_test" or row[0] == "05_Test":
        file_conf_param.write('     constant test_id: integer := 5;\n\n')
      elif row[0] == "09_test" or row[0] == "09_testPS" or row[0] == "09_Test" or row[0] == "09_TestPS":
        file_conf_param.write('     constant test_id: integer := 9;\n\n')     
        # Modified by AS: test indexes updated               
      elif row[0] == "62_test" or row[0] == "62_Test":
        file_conf_param.write('     constant test_id: integer := 62;\n\n')
      elif row[0] == "63_test" or row[0] == "63b_test" or row[0] == "64_test" or row[0] == "64b_test" or row[0] == "65_test" or row[0] == "66_test" or row[0] == "63_Test" or row[0] == "63b_Test" or row[0] == "64_Test" or row[0] == "64b_Test" or row[0] == "65_Test" or row[0] == "66_Test":
        file_conf_param.write('     constant test_id: integer := 63;\n\n')
      elif row[0] == "67_test" or row[0] == "67b_test" or row[0] == "68_test" or row[0] == "68b_test" or row[0] == "69_test" or row[0] == "70_test" or row[0] == "67_Test" or row[0] == "67b_Test" or row[0] == "68_Test" or row[0] == "68b_Test" or row[0] == "69_Test" or row[0] == "70_Test":
        file_conf_param.write('     constant test_id: integer := 67;\n\n')
      ######################################
      # Modified by AS: New test behaviours with test_id = 80 and 83 included
      elif row[0] == "80_test" or row[0] == "80a_test" or row[0] == "81_test" or row[0] == "81a_test" or row[0] == "82_test" or row[0] == "80_Test" or row[0] == "80a_Test" or row[0] == "81_Test" or row[0] == "81a_Test" or row[0] == "82_Test":
        file_conf_param.write('     constant test_id: integer := 80;\n\n')
      elif row[0] == "83_test" or row[0] == "84_test" or row[0] == "85_test" or row[0] == "83_Test" or row[0] == "84_Test" or row[0] == "85_Test":
        file_conf_param.write('     constant test_id: integer := 83;\n\n')
        ######################################
      elif row[0] == "13_test" or row[0] == "13_testPS":
        file_conf_param.write('     constant test_id: integer := 2;\n\n')
      else:
        #if test is short, perform full sequence: error + wrong config...
        if int(row[3]) < 10 and int(row[4]) < 10 and int (row[5]) < 10:
          #print "condition met\n"
          file_conf_param.write('     constant test_id: integer := 10;\n\n')
        else:
          file_conf_param.write('     constant test_id: integer := 0;\n\n')
      file_conf_param.write('   constant test_identifier: string := "'+row[0]+'";                         --! Indicates the test identifiern\n\n')
      if row[0] == "71_test" or row[0] == "72_test" or row[0] == "73_test" or row[0] == "74_test" or row[0]== "75_test" or row[0] == "76_test":
        clk_ip123 = "20"
        file_conf_param.write('     constant clk_ip: time := 20 ns;\n\n')
      else:
        clk_ip123 = "100"
        file_conf_param.write('     constant clk_ip: time := 100 ns;\n\n')
      if row[9] == "bip":
        file_conf_param.write(' constant PREDICTION_TYPE_tb: integer := 0;\n')
      elif row[9] == "bsq":
        file_conf_param.write(' constant PREDICTION_TYPE_tb: integer := 2;\n')
      elif row[9] == "bip-mem":
        file_conf_param.write(' constant PREDICTION_TYPE_tb: integer := 1;\n')
      # Modified by AS: bil-mem architecture included in the prediction_type options
      elif row[9] == "bil-mem":
        file_conf_param.write('  constant PREDICTION_TYPE_tb: integer := 4;')
      ##########################
      else:
        file_conf_param.write(' constant PREDICTION_TYPE_tb: integer := 3;\n')
      file_conf_param.write(' constant ENCODING_TYPE_G_tb: integer :=' + row[15] +';\n')
      file_conf_param.write('\n constant HSINDEX_tb: integer := shyloc_123.ccsds123_parameters.HSINDEX_123;\n')
      file_conf_param.write(' constant HSCONFIGADDR_tb: integer := shyloc_123.ccsds123_parameters.HSCONFIGADDR_123;\n')
      file_conf_param.write('\n constant HSADDRMASK_tb: integer := shyloc_123.ccsds123_parameters.HSADDRMASK_123;\n')
      file_conf_param.write(' constant HMINDEX_tb: integer := shyloc_123.ccsds123_parameters.HMINDEX_123;\n')
      file_conf_param.write(' constant HMAXBURST_tb: integer := shyloc_123.ccsds123_parameters.HMAXBURST_123;\n')
      file_conf_param.write(' constant ExtMemAddress_G_tb: integer := shyloc_123.ccsds123_parameters.ExtMemAddress_GEN;\n')
      file_conf_param.write('\n constant EN_RUNCFG_G: integer := shyloc_123.ccsds123_parameters.EN_RUNCFG;\n')
      file_conf_param.write(' constant RESET_TYPE: integer := shyloc_123.ccsds123_parameters.RESET_TYPE;\n')
      if gen_post_syn == True:
        file_conf_param.write('   constant POST_SYN : integer := 1;                              --! Indicates whether the post-synthesis model should be instantiated (1) or not (0)\n')
      else:
        file_conf_param.write('   constant POST_SYN : integer := 0;                            --! Indicates whether the post-synthesis model should be instantiated (1) or not (0)\n')
      file_conf_param.write('\n constant D_G_tb: integer := shyloc_123.ccsds123_parameters.D_GEN;\n')
      file_conf_param.write(' constant W_BUFFER_G_tb: integer := shyloc_123.ccsds123_parameters.W_BUFFER_GEN;\n')
      file_conf_param.write('\n constant Nx_tb: integer := ' + row[4] + ';')
      file_conf_param.write('             --! Number of columns.\n')
      file_conf_param.write(' constant Ny_tb: integer := ' + row[3] + ';')
      file_conf_param.write('             --! Number of rows.\n')
      file_conf_param.write(' constant Nz_tb: integer := ' + row[5] + ';')
      file_conf_param.write('             --! Number of bands.\n')
      file_conf_param.write('\n constant DISABLE_HEADER_tb: integer := ' + row[34] + ';')
      file_conf_param.write('       --! Selects whether to disable (1) or not (0) the header generation.\n')
      file_conf_param.write(' constant ENCODER_SELECTION_tb: integer := ' + row[35] + ';')
      file_conf_param.write('     --! (0) Disables encoding; (1) Selects sample-adaptive coder; (2) Selects external encoder (block-adaptive).\n')
      file_conf_param.write(' constant D_tb: integer := ' + row[6] + ';')
      file_conf_param.write('             --! Dynamic range of the input samples.\n')
      file_conf_param.write(' constant IS_SIGNED_tb: integer := ')
      if row[7] == "uint":
        file_conf_param.write('0;')
      else: 
        file_conf_param.write('1;')
      file_conf_param.write('         --! (0) Unsigned samples; (1) Signed samples.\n')
      if row[8] == "le":
        file_conf_param.write(' constant ENDIANESS_tb: integer := 0;\n\n')
      else:
        file_conf_param.write(' constant ENDIANESS_tb: integer := 1;')
      file_conf_param.write('         --! (0) Little-Endian; (1) Big-Endian.\n\n')
      file_conf_param.write(' constant BYPASS_tb: integer := ' + row[36] + ';')
      file_conf_param.write('           --! (0) Compression; (1) Bypass Compression.\n')
      file_conf_param.write('\n constant P_tb: integer := ' + row[37] + ';')
      file_conf_param.write('             --! Number of bands used for prediction.\n')
      file_conf_param.write(' constant PREDICTION_tb: integer := ' + row[38] + ';')
      file_conf_param.write('         --! Full (0) or reduced (1) mode.\n')
      file_conf_param.write(' constant LOCAL_SUM_tb: integer := ' + row[39] + ';')
      file_conf_param.write('         --! Neighbour (0) or column (1) oriented local sum.\n')
      file_conf_param.write(' constant OMEGA_tb: integer := ' + row[40] + ';')
      file_conf_param.write('           --! Weight component resolution.\n')
      file_conf_param.write(' constant R_tb: integer := ' + row[41] + ';')
      file_conf_param.write('             --! Register size.\n')
      file_conf_param.write('\n constant VMAX_tb: integer := ' + row[42] + ';')
      file_conf_param.write('             --! Factor for weight update.\n')
      file_conf_param.write(' constant VMIN_tb: integer := ' + row[43] + ';')
      file_conf_param.write('           --! Factor for weight update.\n')
      file_conf_param.write(' constant TINC_tb: integer := ' + row[44] + ';')
      file_conf_param.write('           --! Weight update factor change interval.\n')
      file_conf_param.write(' constant WEIGHT_INIT_tb: integer := 0;')
      file_conf_param.write('         --! Weight initialization mode.\n')
      file_conf_param.write('\n constant INIT_COUNT_E_tb: integer := ' + row[47] + ';')
      file_conf_param.write('         --! Initial count exponent.\n')
      file_conf_param.write(' constant ACC_INIT_TYPE_tb: integer := ' + row[48] + ';')
      file_conf_param.write('       --! Accumulator initialization type.\n')
      file_conf_param.write(' constant ACC_INIT_CONST_tb: integer := ' + row[49] + ';')
      file_conf_param.write('       --! Accumulator initialization constant.\n')
      file_conf_param.write(' constant RESC_COUNT_SIZE_tb: integer := ' + row[50] + ';')
      file_conf_param.write('       --! Rescaling counter size.\n')
      file_conf_param.write(' constant U_MAX_tb: integer := ' + row[51] + ';')
      file_conf_param.write('           --! Unary length limit.\n')
      file_conf_param.write(' constant W_BUFFER_tb: integer := ' + row[53] + ';')
      file_conf_param.write('         --! Bit width of the output buffer.\n')
      file_conf_param.write('\n constant Q_tb: integer := 5;')
      file_conf_param.write('             --! Weight initialization resolution.\n\n')
      # Modified by AS: generating CWI tb parameters with default values
      file_conf_param.write('  constant WR_tb: integer := 1;')
      file_conf_param.write('                      --! Weight Reset.\n\n')
      file_conf_param.write('  constant CWI_tb: integer := 0;')
      file_conf_param.write('                      --! Custom Weight Initialization mode.\n\n')
      #######################
      file_conf_param.write(' constant W_NBITS_HEAD_G_tb : integer := 7;\n')
      file_conf_param.write(' constant W_LS_G_tb: integer := D_G_tb + 3;\n')
      file_conf_param.write('end ccsds123_tb_parameters;\n')
      file_conf_param.close()
      ########################################################################
      # End of Generate file ccsds123_tb_parameters.vhd
      ########################################################################
    if row[35] == "2":
      ########################################################################
      # Generate file ccsds121_parameters.vhd
      ########################################################################
      #print('***Preparing Generic Parameters file ccsds121_parameters.vhd.......\n')
      destination_folder_param = os.path.join(destination_folder, 'ccsds121_parameters.vhd')
      file_gen_param = open (destination_folder_param, 'w')
      #content of file ccsds121_parameters.vhd
      file_gen_param.write('\n\nlibrary ieee;\nuse ieee.std_logic_1164.all;\nuse ieee.numeric_std.all;\n\n')
      file_gen_param.write('package ccsds121_parameters is\n')
      file_gen_param.write('\n-- TEST: ' + row [0]  + '\n')
      set = row[9]
      file_gen_param.write('   constant EN_RUNCFG: integer  := ' + row[11] +';')
      file_gen_param.write('          --! (0) Disables runtime configuration; (1) Enables runtime configuration.\n')
      file_gen_param.write('   constant RESET_TYPE: integer :=  ' + row[12] +';')
      file_gen_param.write('          --! (0) Asynchronous reset; (1) Synchronous reset.\n')
      file_gen_param.write('   constant HSINDEX_121: integer := 3;')
      file_gen_param.write('          --! AHB slave index.\n')
      file_gen_param.write('   constant HSCONFIGADDR_121: integer := 16#100#;')
      file_gen_param.write('    --! ADDR field of the AHB Slave.\n')
      file_gen_param.write('   constant HSADDRMASK_121: integer := 16#FFF#;')
      file_gen_param.write('      --! MASK field of the AHB slave.\n')
      file_gen_param.write('   constant EDAC: integer := 0;')
      file_gen_param.write('              --! (0) Inhibits EDAC implementation; (1) EDAC is implemented.\n')
      file_gen_param.write('   constant Nx_GEN : integer := ' + row[55] +';')
      file_gen_param.write('          --! Maximum allowed number of samples in a line.\n')
      file_gen_param.write('   constant Ny_GEN : integer := ' + row[54] +';')
      file_gen_param.write('          --! Maximum allowed number of samples in a row.\n')
      file_gen_param.write('   constant Nz_GEN : integer := ' + row[56] +';')
      file_gen_param.write('          --! Maximum allowed number of bands.\n')
      file_gen_param.write('   constant D_GEN : integer := ' + row[57] +';')
      file_gen_param.write('            --! Maximum dynamic range of the input samples.\n')
      if row[58] == "uint":
        file_gen_param.write('   constant IS_SIGNED_GEN : integer := 0;')
      else:
        file_gen_param.write('   constant IS_SIGNED_GEN : integer := 1;')
        file_gen_param.write('              --! (0) Unsigned samples; (1) Signed samples.\n')
      if row[59] == "le":
         file_gen_param.write('   constant ENDIANESS_GEN : integer := 0;')
      else:
         file_gen_param.write('   constant ENDIANESS_GEN : integer := 1;')
      file_gen_param.write('        --! (0) Little-Endian; (1) Big-Endian.\n')
      file_gen_param.write('   constant J_GEN: integer := ' + row[67] + ';')
      file_gen_param.write('            --! Block Size.\n')
      file_gen_param.write('   constant REF_SAMPLE_GEN: integer := ' + row[69] + ';')
      file_gen_param.write('      --! Reference Sample Interval.\n')
      file_gen_param.write('   constant CODESET_GEN: integer := ' + row[68] + ';')
      file_gen_param.write('          --! Code Option.\n')
      file_gen_param.write('   constant W_BUFFER_GEN: integer := ' + row[70] + ';')
      file_gen_param.write('        --! Bit width of the output buffer.\n')
      file_gen_param.write('   constant PREPROCESSOR_GEN : integer := 1;')
      file_gen_param.write('      --! (0) Preprocessor is not present; (1) CCSDS123 preprocessor is present; (2) Any-other preprocessor is present.\n')
      file_gen_param.write('   constant DISABLE_HEADER_GEN : integer := 0;')
      file_gen_param.write('      --! Selects whether to disable (1) or not (0) the header.\n\n')
      file_gen_param.write('  constant TECH: integer := ' + row[75] + ';')
      file_gen_param.write('            --! Selects the memory type.\n\n')
      file_gen_param.write('\nend ccsds121_parameters;\n')
      file_gen_param.close()
      ########################################################################
      # End of Generate file ccsds121_parameters.vhd
      ########################################################################
      if gen_simulation:
        ########################################################################
        # Generate file ccsds121_tb_parameters.vhd
        ########################################################################
        #print('***Preparing Testbench Parameters file ccsds121_tb_parameters.......\n')
        destination_folder = os.path.join(stimuli_folder, row[0])
        destination_folder_param = os.path.join(destination_folder, 'ccsds121_tb_parameters.vhd')
        file_conf_param = open (destination_folder_param, 'w')
        file_conf_param.write('\n\nlibrary ieee;\nuse ieee.std_logic_1164.all;\nlibrary shyloc_121;\nuse shyloc_121.ccsds121_parameters.all;\nlibrary shyloc_utils;\n use shyloc_utils.shyloc_functions.all;\n\n')
        file_conf_param.write('package ccsds121_tb_parameters is\n')
        file_conf_param.write('\n-- TEST: ' + row [0]  + '\n')
        if row[0] == "04_Test":
          file_conf_param.write('   constant test_id: integer := 4;\n\n')
        elif row[0] == "07_Test":
          file_conf_param.write('   constant test_id: integer := 7;\n\n')
        elif row[0] == "14_Test":
          file_conf_param.write('   constant test_id: integer := 2;\n\n')
        elif row[0] == "05_Test":
          file_conf_param.write('   constant test_id: integer := 5;\n\n')
        else:
          file_conf_param.write('   constant test_id: integer := 0;\n\n')
        file_conf_param.write('   constant clk_ip: time :=' + clk_ip123 + ' ns;\n')
        file_conf_param.write('   constant EN_RUNCFG_G: integer := shyloc_121.ccsds121_parameters.EN_RUNCFG;\n')
        file_conf_param.write('   constant RESET_TYPE: integer := shyloc_121.ccsds121_parameters.RESET_TYPE;\n\n')
        file_conf_param.write('   constant HSINDEX_121: integer := shyloc_121.ccsds121_parameters.HSINDEX_121;\n')
        file_conf_param.write('   constant HSCONFIGADDR_121: integer := shyloc_121.ccsds121_parameters.HSCONFIGADDR_121;\n')
        file_conf_param.write('   constant HSADDRMASK_121: integer := shyloc_121.ccsds121_parameters.HSADDRMASK_121;\n\n')
        #select parameters for tb depending on EN_RUNCFG value?
        file_conf_param.write('   constant Nx_tb: integer := ' + row[4] +';\n')
        file_conf_param.write('   constant Ny_tb: integer := ' + row[3] +';\n')
        file_conf_param.write('   constant Nz_tb: integer := ' + row[5] +';\n')
        file_conf_param.write('   constant D_tb: integer := ' + row[6] +';\n')
        file_conf_param.write('   constant ENDIANESS_tb: integer := ')
#        if row[8] == "le":
#         file_conf_param.write('0;\n')
#       else:
#ENDIANESS   OF 121 WHEN WORKING AS AN EXTERNAL ENCODER ALWAYS SET TO 1 (BIG ENDIAN)
        file_conf_param.write('1;\n')
        #if row[7] == "uint":
        # file_conf_param.write('0;\n')
        #else:
        # file_conf_param.write('1;\n')
        file_conf_param.write('   constant IS_SIGNED_tb: integer := ')
#121 BLOCK CODER WORKS WITH MAPPED (UNSIGNED) RESIDUALS WHEN IT IS THE EXTERNAL ENCODER OF THE 123 IP
        file_conf_param.write('0;\n')
        file_conf_param.write('   constant J_tb: integer := ' + row[71] + ';\n')
        file_conf_param.write('   constant REF_SAMPLE_tb: integer := ' + row[73] + ';\n')
        file_conf_param.write('   constant CODESET_tb: integer := ' + row[72] + ';\n')
        file_conf_param.write('   constant W_BUFFER_tb : integer := ' + row[74] + ';\n')
        file_conf_param.write('   constant BYPASS_tb: integer := 0;\n')
        file_conf_param.write('   constant PREPROCESSOR_tb: integer := 1;\n')
        file_conf_param.write('   constant DISABLE_HEADER_tb: integer :=' + row[34] + ';\n')
        file_conf_param.write('   constant stim_file: string := "STIMULI\\raw\\' + row[0] + '\\' + row[2] +'";\n')
        file_name = row[62] + ".esa"
        file_conf_param.write('   constant ref_file: string := "STIMULI\\reference\\' + row[0] + '\\' + file_name + '";\n')
        file_name = row[62] + ".vhd"
        file_conf_param.write('   constant out_file: string := "STIMULI\\' + row[0] + '\\' + file_name + '";\n')
        file_conf_param.write('   constant D_G_tb : integer := shyloc_121.ccsds121_parameters.D_GEN;\n   constant W_BUFFER_G_tb : integer := shyloc_121.ccsds121_parameters.W_BUFFER_GEN;\n   constant N_SAMPLES_G_tb : integer := (Nx_tb*Ny_tb*Nz_tb);\n')
        file_conf_param.write('   constant W_N_SAMPLES_G_tb : integer := log2(N_SAMPLES_G_tb);\n   constant CODESET_G_tb : integer := shyloc_121.ccsds121_parameters.CODESET_GEN;\n   constant N_K_G_tb: integer := get_n_k_options (D_G_tb, CODESET_G_tb);\n')
        file_conf_param.write('   constant W_K_G_tb: integer := maximum(3,log2(N_K_G_tb)+1);\n   constant W_NBITS_K_G_tb: integer := get_k_bits_option(W_BUFFER_G_tb, CODESET_G_tb, W_K_G_tb);\n');
        file_conf_param.write('\nend ccsds121_tb_parameters;\n')
        file_conf_param.close()
        ########################################################################
        # End of Generate file ccsds121_tb_parameters.vhd
        ########################################################################
    #generating scripts for simulation
    if gen_simulation:
      ########################################################################
      # Generate file *.do files for CCSDS123+CCSDS121
      ########################################################################
      if (os.path.exists(raw_file) and os.path.exists(ref_file)):
        if not 'test_id_2perform' in locals():
          test_id_2perform = [row[0]]
        else:
          test_id_2perform.append(row[0])
        #print "Generating scripts for simulation: " + raw_file + '\n'
        parameters_folder = os.path.join(stimuli_folder, row[0])
        if gen_post_syn == True: 
          filename_scripts = os.path.join(database_folder , 'modelsim','tb_scripts', row[0] + '_ps.do')
        else:
          filename_scripts = os.path.join(database_folder , 'modelsim','tb_scripts', row[0] + '.do')
        file_scripts = open(filename_scripts, 'w')
        
        if row[35] == "2":
          #CCSDS123 + CCSDS121
          file_scripts.write ('set lib_exists [file exists work]\n'+
          'if $lib_exists==1 {vdel -all -lib work}\n'+
          'vlib work\n'+
          'set lib_exists [file exists grlib]\n' +
                    'if $lib_exists==1 {vdel -all -lib grlib}\n' +
          'vlib grlib\n' +
              'set lib_exists [file exists techmap]\n' +
                    'if $lib_exists==1 {vdel -all -lib techmap}\n' +
          'vlib techmap\n' +
          'set lib_exists [file exists gaisler]\n' +
                    'if $lib_exists==1 {vdel -all -lib gaisler}\n' +
          'vlib gaisler\n' +
          'do $SRC/modelsim/tb_scripts/setGRLIB.do\n' +
          '#set IP test parameters\n' +
          'set lib_exists [file exists shyloc_121]\n'+
          'if $lib_exists==1 {vdel -all -lib shyloc_121}\n'+
          'vlib shyloc_121\n' +
          'set lib_exists [file exists shyloc_utils]\n'+
          'if $lib_exists==1 {vdel -all -lib shyloc_utils}\n'+
          'vlib shyloc_utils\n' +
          'set lib_exists [file exists shyloc_123]\n'+
          'if $lib_exists==1 {vdel -all -lib shyloc_123}\n'+
          'vlib shyloc_123\n'+
          'set lib_exists [file exists post_syn_lib]\n'+
          'if $lib_exists==1 {vdel -all -lib post_syn_lib}\n' +
          'vlib post_syn_lib\n'
          'vcom -work shyloc_123 -93 -explicit  ' + '$SRC/modelsim/tb_stimuli/'+ row[0] + '/ccsds123_parameters.vhd\n' + 
          'vcom -work shyloc_121 -93 -explicit  ' + '$SRC/modelsim/tb_stimuli/'+ row[0] + '/ccsds121_parameters.vhd\n')
          if gen_post_syn == False: 
            file_scripts.write ('do $SRC/modelsim/tb_scripts/ip_core.do\n' +
            'do $SRC/modelsim/tb_scripts/ip_core_block.do\n')
          else:
            imp_names = imp_names_ps
            if not (os.path.exists(os.path.join(database_folder, 'src', 'post_syn', ''.join(imp_names), row[0], 'ccsds123_top_wrapper.vhm/ccsds123_top_wrapper.vhm'))):
              if not 'not_test_id_2perform' in locals():
                not_test_id_2perform = [row[0]]
              else:
                not_test_id_2perform.append(row[0])
              print ('Post-synthesis model not found, please generate it first using the command synplify-ps and running the synthesis/n + The test ' + row[0] + ' will not be performed \n')
            file_scripts.write ('do $SRC/modelsim/tb_scripts/ip_core.do\n' + 'do $SRC/modelsim/tb_scripts/ip_core_block.do\n' + 
            'set lib_exists [file exists post_syn_lib]\n'+
            'if $lib_exists==1 {vdel -all -lib post_syn_lib}\n' +
            'vlib post_syn_lib\n'
            'vcom -93 -check_synthesis -work post_syn_lib ' + '$SRC/src/post_syn/'+ ''.join(imp_names) +'/'+ row[0] + '/ccsds123_top_wrapper.vhm/ccsds123_top_wrapper.vhm\n')
          file_scripts.write ('vcom -work work -93 -explicit ' + '$SRC/modelsim/tb_stimuli/'+ row[0] + '/ccsds123_tb_parameters.vhd\n' + 
          'vcom -work work -93 -explicit ' + '$SRC/modelsim/tb_stimuli/'+ row[0] + '/ccsds121_tb_parameters.vhd\n' +
          'do $SRC/modelsim/tb_scripts/testbench_shyloc.do\n' + 
          'vsim -coverage work.ccsds_shyloc_tb(arch) -voptargs=+acc=bcglnprst+ccsds_shyloc_tb\n' + 
          '#do waves/wave_shyloc.do\n' + 
          'onbreak {resume}\n' + 'run -all\n')
          file_scripts.close()
        else:
          #CCSDS123 only
          #print "Simulation requested!!"
          file_scripts.write ('set lib_exists [file exists work]\n'+
          'if $lib_exists==1 {vdel -all -lib work}\n'+
          'vlib work\n'+
          'set lib_exists [file exists grlib]\n' +
                    'if $lib_exists==1 {vdel -all -lib grlib}\n' +
          'vlib grlib\n' +
          'set lib_exists [file exists techmap]\n' +
          'if $lib_exists==1 {vdel -all -lib techmap}\n' +
          'vlib techmap\n' +                              
          'set lib_exists [file exists gaisler]\n' +
          'if $lib_exists==1 {vdel -all -lib gaisler}\n' +
          'vlib gaisler\n' +
          'do $SRC/modelsim/tb_scripts/setGRLIB.do\n' +
          '#set IP test parameters\n' + 
          'set lib_exists [file exists shyloc_123]\n'+
          'if $lib_exists==1 {vdel -all -lib shyloc_123}\n'+
          'vlib shyloc_123\n' +
          'set lib_exists [file exists post_syn_lib]\n'+
          'if $lib_exists==1 {vdel -all -lib post_syn_lib}\n' +
          'vlib post_syn_lib\n'
          'vcom -work shyloc_123 -93 -explicit  ' + '$SRC/modelsim/tb_stimuli/'+ row[0] + '/ccsds123_parameters.vhd\n') 
          if gen_post_syn == False:
            #print "writing ipcore.do"
            file_scripts.write ('do $SRC/modelsim/tb_scripts/ip_core.do\n')
          else:
            imp_names = imp_names_ps
            if not (os.path.exists(os.path.join(database_folder, 'src', 'post_syn', ''.join(imp_names), row[0], 'ccsds123_top_wrapper.vhm'))):
              if not 'not_test_id_2perform' in locals():
                not_test_id_2perform = [row[0]]
              else:
                not_test_id_2perform.append(row[0])
              print ('Post-synthesis model not found, please generate it first using the command synplify-ps and running the synthesis/n + The test ' + row[0] + 'will not be performed \n')
            file_scripts.write ('do $SRC/modelsim/tb_scripts/ip_core.do\n' +
            'set lib_exists [file exists post_syn_lib]\n'+
            'if $lib_exists==1 {vdel -all -lib post_syn_lib}\n' +
            'vlib post_syn_lib\n'
            'vcom -93 -check_synthesis -work post_syn_lib ' + '$SRC/src/post_syn/'+ ''.join(imp_names)+'/'+ row[0] + '/ccsds123_top_wrapper.vhm/ccsds123_top_wrapper.vhm\n' )
          #print "writing the rest"
          file_scripts.write ('#set tb test parameters\n' + 
          'vcom -work work -93 -explicit '+ '$SRC/modelsim/tb_stimuli/'+ row[0] + '/ccsds123_tb_parameters.vhd\n' +
          'do $SRC/modelsim/tb_scripts/testbench.do\n' +
          'vsim -coverage work.ccsds_shyloc_tb(arch) -voptargs=+acc=bcglnprst+ccsds_shyloc_tb\n'
          'onbreak {resume}\n' + '#do wave.do\n' + 'run -all\n')
        ########################################################################
        # End of Generate file *.do files for CCSDS123+CCSDS121
        ########################################################################
      else:
        if not 'not_test_id_2perform' in locals():
          not_test_id_2perform = [row[0]]
        else:
          not_test_id_2perform.append(row[0])
        print("Can't perform simulation, since there are missing files (check raw file and reference file).")
    elif gen_synplify: 
      #print ("gen synplify detected")
      ########################################################################
            # Generate file *.tcl files for synplify
      ########################################################################
      filename_scripts = os.path.join(database_folder , 'synthesis', 'syn_scripts', 'synplify', row[0] + '.tcl')
      if gen_post_syn == True:
        imp_names = imp_names_ps
        technologies = technologies_ps
      database_folder_changed = database_folder.replace(sep, '/')
      file_scripts = open(filename_scripts, 'w')
      destination_folder = os.path.join(database_folder , 'synthesis', 'syn_scripts', 'synplify')
      database_folder_changed = database_folder.replace(sep, '/')
      destination_folder_changed = destination_folder.replace(sep, '/')
      file_scripts.write(
      'puts "Cleaning project"\n'
      'project_file -remove *.vhd\n'
      'project_file -remove *.fdc\n'
      'puts "Adding restriction files"\n'
      'add_file -fpga_constraint "ccsds123_project.fdc"\n'
      'puts "Adding configuration files"\n'
      '#add_file -vhdl '+ '$SRC/synthesis/premap_parameters/' + row[0] + '/ccsds_shyloc_global_parameters.vhd\n' + 
      'add_file '+ '-lib shyloc_123' +  ' -vhdl '+ '$SRC/synthesis/premap_parameters/' + row[0] + '/ccsds123_parameters.vhd\n'
      'source $SRC/synthesis/syn_scripts/synplify/add_ip_core.tcl\n')
      #imp_names = ['XC5VFX130T', 'XQR5VFX130', 'A3PE3000', 'A3PE3000L', 'RTAX2000S', 'RTAX4000S', 'RT4G4150', 'XC6VLX240T']
      #imp_names = ['XC5VFX130T', 'XQR5VFX130', 'RT4G4150']
      #technologies = ['Virtex5', 'QProRVirtex5', 'ProASIC3E', 'ProASIC3L', 'Axcelerator', 'Axcelerator', 'RTG4', 'Virtex6']
      #technologies = ['Virtex5', 'QProRVirtex5', 'RTG4']
      #imp_names = ['XC5VFX130T', 'RT4G4150']
      #technologies = ['Virtex5', 'RTG4']
      # Modified by AS: loop boundaries modified to properly work for both synthesis and ps-simulations
      for target in range(len(imp_names[0:5])):
        file_scripts.write(
        'impl -add ' + imp_names[target] + '_' + row[0] + '\n'
        'impl -name ' + imp_names[target] + '_'  + row[0] +' -movedir\n'
        'set_option -frequency 150\n' + 
        'set_option -symbolic_fsm_compiler 1\n' +
        'set_option -use_fsm_explorer 1\n'
        'set_option -technology ' + technologies[target] + '\n' +
        'set_option -part ' + imp_names[target] + ' \n')
        if imp_names[target] == 'XC6VLX240T':
          file_scripts.write('set_option -package FF1759\n' +
          'set_option -speed_grade -2\n')
        if gen_post_syn == False:
          file_scripts.write(
          'set_option -top_module shyloc_123.ccsds123_top\n' + 
          'puts "Running synthesis with configuration :'+ row[0] +'"\n' +
          'if {[catch {project -run} errormsg]} {\n' +
          'puts "No implementation"\n' +
          '} else {' +
          # Modified by AS: -dir flag added to glob tcl commands to properly locate target files
          'file copy -force ' + '[glob -dir ' + destination_folder_changed + '/' + imp_names[target] + '_' + row[0] +'/ *.srr] ' + destination_folder_changed +'/report/' + imp_names[target] + '_' + row[0] + '_synplify.srr\n'+
          'file copy -force ' + '[glob -dir ' + destination_folder_changed + '/' + imp_names[target] + '_' + row[0] +'/synlog/report/ ' + '*mapper_timing_report.xml] ' + destination_folder_changed +'/report/' + imp_names[target] + '_' + row[0] + '_synplify_fpga_mapper_timing_report.xml\n'+
          'file copy -force ' + '[glob -dir ' + destination_folder_changed + '/' + imp_names[target] + '_' + row[0] +'/synlog/report/ ' + '*mapper_area_report.xml] ' + destination_folder_changed +'/report/' + imp_names[target] + '_' + row[0] + '_synplify_fpga_mapper_area_report.xml\n'+
          ####################################################
          '}\nputs "Log file stored in: ' +
          '$SRC/synthesis/syn_scripts/synplify/report/' + imp_names[target] + '_' + row[0] + '.srr"\n'
          )
        else: 
          if not (os.path.exists(os.path.join(database_folder, 'src', 'post_syn', imp_names[target], row[0]))):
            os.makedirs(os.path.join(database_folder, 'src', 'post_syn', imp_names[target], row[0]))
          file_scripts.write (
          'set_option -top_module post_syn_lib.ccsds123_top_wrapper\n' + 
          'set_option -write_vhdl 1\n' + 
          'puts "Running synthesis with configuration :'+ row[0] +'"\n' +
          'if {[catch {project -run} errormsg]} {\n' +
          'puts "No implementation"\n' +
          '} else {' +
          # Modified by AS: -dir flag added to glob tcl commands to properly locate target files
          'file copy -force ' + '[glob -dir ' + destination_folder_changed + '/' + imp_names[target] + '_' + row[0] +'/ *.srr] ' + destination_folder_changed +'/report/' + imp_names[target] + '_' + row[0] + '_synplify.srr\n'+
          'file copy -force '+ '[glob -dir ' + destination_folder_changed + '/' + imp_names[target] + '_' + row[0] +'/ *.vhm]  ' + '$SRC/src/post_syn/'+imp_names[target]+'/'+row[0]+'/ccsds123_top_wrapper.vhm}' 
          ####################################################
        )
      file_scripts.close()
      ########################################################################
            # End of Generate file *.tcl files for synplify
      ########################################################################
    elif gen_ise:
      ########################################################################
            # Generate file *.tcl files for ise
      ########################################################################
      filename_scripts = os.path.join(database_folder , 'synthesis', 'syn_scripts', 'ise', row[0] + '.tcl')
      database_folder_changed = database_folder.replace(sep, '/')
      file_scripts = open(filename_scripts, 'w')
      file_scripts.write(
      'puts "Cleaning project"\n'
      'xfile remove [ search **.*vhd* -type file ]\n'
      'puts "Adding configuration files"\n'
      'xfile add $SRC/synthesis/premap_parameters/' + row[0] + '/ccsds123_parameters.vhd -lib_vhdl shyloc_123\n'
      'source $SRC/synthesis/syn_scripts/ise/add_ip_core.tcl\n'
      'project set top ccsds123_top')
      file_scripts.close()
      ########################################################################
            # End of Generate file *.tcl files for ise
      ########################################################################
    elif gen_vivado: 
      ########################################################################
            # Generate file *.tcl files for vivado
      ########################################################################
      filename_scripts = os.path.join(database_folder , 'synthesis', 'syn_scripts', 'vivado', row[0] + '.tcl')
      database_folder_changed = database_folder.replace(sep, '/')
      file_scripts = open(filename_scripts, 'w')
      destination_folder = os.path.join(database_folder , 'synthesis', 'syn_scripts', 'vivado')
      database_folder_changed = database_folder.replace(sep, '/')
      destination_folder_changed = destination_folder.replace(sep, '/')
      file_scripts.write(
      'puts "Cleaning project"\n'
      'remove_files [get_files]\n'
      'puts "Adding configuration files"\n'
      'add_files -norecurse '+ '$SRC/synthesis/premap_parameters/' + row[0] + '/ccsds123_parameters.vhd\n'
      'set_property library shyloc_123 [get_files  $SRC/synthesis/premap_parameters/' + row[0] + '/ccsds123_parameters.vhd]\n'
      'source $SRC/synthesis/syn_scripts/VIVADO/add_ip_core.tcl\n')
      imp_names = ['ZC706', 'zedboard']
      technologies = ['xc7z045ffg900-2', 'xc7z020clg484-1']
      for target in range(len(imp_names)):
        file_scripts.write('create_run ' + imp_names[target] + '_' + row[0] + ' -part ' + technologies[target] + ' ' + '-flow {Vivado Synthesis 2016}\n')
        file_scripts.write(
        'if {[catch {launch_runs ' + imp_names[target] + '_' + row[0] + ' -jobs 4} errormsg]} {\n' +
        'puts "No implementation"\n' +
        '} else {' +
        'puts "Implementation"}\n')
      file_scripts.close()
      ########################################################################
      # End of Generate file *.tcl files for vivado
      ########################################################################
    elif gen_brave: 
      ########################################################################
      # Generate file *.py scripts for Nanoxmap
      ########################################################################
      for target in range(5,7):
        filename_scripts = os.path.join(database_folder , 'synthesis', 'syn_scripts', 'brave', row[0] + '_' + technologies[target] + '.py')
        database_folder_changed = database_folder.replace(sep, '/')
        file_scripts = open(filename_scripts, 'w')
        file_scripts.write(
                'import os\n' +
                'import sys\n' +
                'import shutil\n' +
                'from os import path\n'	+
                'from nxmap import *\n' +

                "REPORTS_DIR = os.path.join('report','"+row[0]+"')\n" +
                "RESULTS_DIR = os.path.join('results','"+row[0]+"')\n" +
                'SRC="' + database_folder_changed + '"\n' +
                'dir = os.path.dirname(os.path.realpath(__file__))\n' +
                'sys.path.append(dir)\n' +
                
                "#Generating output and report folders\n" +
                "if ((not os.path.exists(REPORTS_DIR)) or (not os.path.isdir(REPORTS_DIR))):\n" +
                "\tos.mkdir(REPORTS_DIR)\n" +
                "\tprintText(REPORTS_DIR + ' folder generated')\n" +
                "if ((not os.path.exists(RESULTS_DIR)) or (not os.path.isdir(RESULTS_DIR))):\n" +
                "\tos.mkdir(RESULTS_DIR)\n" +
                "\tprintText(RESULTS_DIR + ' folder generated')\n" +
                
                '#Creating new NanoXmap project\n' +
                'nano123 = createProject(dir)\n' +
                "nano123.setVariantName('"+technologies[target]+"')\n" +
                
                "nano123.setTopCellName('shyloc_123','ccsds123_top')\n" +
                '#Adding configuration files...\n' +
                "nano123.addFile('shyloc_123',os.path.join(SRC, 'synthesis','premap_parameters','"+row[0]+"','ccsds123_parameters.vhd'))\n" +
                "exec(open('add_ip_core.py').read())\n" +

                "nano123.setOptions({'RoutingEffort':'Medium','ManageUnconnectedOutputs':'Ground','ManageUnconnectedSignals':'Ground','DefaultRAMMapping':'RAM','MappingEffort':'Medium','VariantAwareSynthesis':'Yes'})\n" +
                '#Executing the synthesis step...\n' +
                "nano123.save('ccsds123_brave_"+row[0]+'_'+technologies[target]+".nym')\n" +
                "if not nano123.synthesize():\n" +
                    "\tsys.exit(1)\n" +
                "nano123.save(os.path.join(RESULTS_DIR,'ccsds123_"+technologies[target]+"_synthesized.vhd'))\n" +
                '#Executing the implementation step...\n' +
                "if not nano123.place():\n" +
                    "\tsys.exit(1)\n" +
                "nano123.save(os.path.join(RESULTS_DIR,'ccsds123_"+technologies[target]+"_placed.vhd'))\n" +
                "if not nano123.route():\n" +
                    "\tsys.exit(1)\n" +
                "nano123.save(os.path.join(RESULTS_DIR,'ccsds123_"+technologies[target]+"_routed.vhd'))\n" +

                '#Generating reports...\n' +
                'nano123.reportInstances()\n'+
                'analyzer = nano123.createAnalyzer()\n'+
                'analyzer.launch()\n' +

                "if (os.path.exists('logs') and os.path.isdir('logs') and (REPORTS_DIR != 'logs')):\n" +
                '\tprintText("Saving synthesis reports")\n' +
                "\tdir_contents = os.scandir('logs')\n" +
                '\tfor entry in dir_contents:\n' +
                '\t\t(name,ext) = os.path.splitext(entry.name)\n' +
                "\t\tif ((ext == '.rpt') or (ext == '.timing')):\n" +
                "\t\t\tnew_filename = '"+technologies[target]+"_' + name + ext \n" +
                '\t\t\tshutil.copy(entry.path,os.path.join(REPORTS_DIR,new_filename))\n' +

                'nano123.destroy()\n' +
                "print ('Errors: ', getErrorCount())\n"+
                "print ('Warnings: ', getWarningCount())\n"
                )
        file_scripts.close()
      ########################################################################
      # End of Generate file *.py scripts for Nanoxmap
      ########################################################################
    elif gen_dc:
    ########################################################################
    # Generate file *.tcl files for dc
    ########################################################################
      filename_scripts = os.path.join(database_folder , 'synthesis', 'syn_scripts', 'dc', row[0] + '.tcl')
      database_folder_changed = database_folder.replace(sep, '/')
      file_scripts = open(filename_scripts, 'w')
      destination_folder = os.path.join(database_folder , 'synthesis', 'syn_scripts', 'dc')
      database_folder_changed = database_folder.replace(sep, '/')
      destination_folder_changed = destination_folder.replace(sep, '/')
      file_scripts.write(
        'source $SRC/synthesis/syn_scripts/dc/setupLibs.tcl\n' +
        'analyze -f VHDL -library shyloc_123 $SRC/synthesis/premap_parameters/' + row[0]+ '/ccsds123_parameters.vhd\n' +
        'source $SRC/synthesis/syn_scripts/dc/add_ip_core.tcl\n' +
        'elaborate -work shyloc_123 ${DESIGN_NAME}\n')
      file_scripts.close()
    ########################################################################
    # End of Generate file *.tcl files for dc
    ########################################################################            
  csv_file_handle.close()
# Verification_report creation and coverage management
  if gen_simulation:
    ########################################################################
    # Generate all_tests.do
    ########################################################################
    csv_file_handle = open(sys.argv[1], 'rb')
    csv_reader = csv.reader(csv_file_handle, delimiter=',')
    destination_folder = os.path.join(database_folder , 'modelsim', 'tb_scripts')
    all_tests = open (os.path.join(destination_folder, 'all_tests.do'), 'w')
    database_folder_changed = database_folder.replace(sep, '/')
    database_121_folder_changed = database_121_folder.replace(sep, '/')
    stimuli_folder_c = stimuli_folder.replace(sep, '/')
    all_tests.write('set SRC ' + database_folder_changed + '\n')
    all_tests.write('set SRC121 ' + database_121_folder_changed + '\n')
    all_tests.write('set GRLIB ' + os.path.expandvars('$GRLIB').replace(sep, '/') + '\n')
    # Modified by AS: In post-synthesis simulations, call script to properly map required libraries
    if gen_post_syn == True:
      all_tests.write('do $SRC121/modelsim/tb_scripts/ps_libs.do\n')
    ########################
    all_tests.write('proc pause {{message "Hit Enter to continue ==> "}} {\n')
    all_tests.write('puts -nonewline $message\n')
    all_tests.write('flush stdout\n')
    all_tests.write('gets stdin\n}\n')
    all_tests.write('proc eval_result {SRC fp test_id} {\n')
    all_tests.write('set result_test [examine sim:/ccsds_shyloc_tb/sim_successful]\n')
    all_tests.write('if $result_test==TRUE {echo "Simulation finished, test $test_id PASSED"; puts $fp "$test_id passed";\n')
    all_tests.write('coverage report -file ' + stimuli_folder_c + '/$test_id/report_coverage.txt -byfile -assert -directive -cvg -codeAll;\n')
    all_tests.write('coverage report -file ' + stimuli_folder_c  + '/$test_id/report_coverage_details.txt -byfile -detail -assert -directive -cvg -codeAll;\n')
    cover_folder = os.path.join(database_folder , 'modelsim', 'cover')
    if not os.path.exists(cover_folder):
      print ("\n\nCreating folder for COVER results: " + cover_folder)
      os.makedirs(cover_folder)
    if not os.path.exists(cover_folder):
      print ("\n\nCreating folder for COVER results: " + cover_folder)
      os.makedirs(cover_folder)
    all_tests.write('set file /../cover/$test_id;\nappend file _cover.ucdb;\n')
    if gen_post_syn == True:
      all_tests.write('coverage save -assert -directive -cvg -codeAll -instance /ccsds_shyloc_tb/gen_syn/shyloc ' + cover_folder  + '$file; return false}\n')
    else:
      all_tests.write('coverage save -assert -directive -cvg -codeAll -instance /ccsds_shyloc_tb/gen_beh/shyloc ' + cover_folder  + '$file; return false}\n')
    all_tests.write('if $result_test==FALSE {echo "Simulation finished, test FAILED"; puts $fp "$test_id failed"; return true}}\n')
    all_tests.write('set fp [open "$SRC/modelsim/tb_scripts/verification_report.txt" w+]\n')
    all_tests.write('set quit_flag false\n')
    all_tests.write('set num_tests 0\n')
    csv_reader = csv.reader(csv_file_handle, delimiter=',')
    csv_reader.next()
    csv_reader.next()
    if 'test_id_2perform' in locals():
      for row in test_id_2perform:  
        ########################################################################
        ## Looking for old coverage reports files to delete
        cover_file = os.path.join(database_folder,'modelsim/tb_stimuli')
        cover_file = os.path.join(cover_file,row)
        cover_file = os.path.join(cover_file,'report_coverage.txt')
        if (os.path.exists(cover_file)):
          os.remove(cover_file)
        cover_file = os.path.join(database_folder,'modelsim/tb_stimuli')
        cover_file = os.path.join(cover_file,row)
        cover_file = os.path.join(cover_file,'report_coverage_details.txt')
        if (os.path.exists(cover_file)):
          os.remove(cover_file)
        ########################################################################
        ## Add command lines for the test script
        all_tests.write('if $quit_flag!=true {\n')
        if gen_post_syn == True:
          all_tests.write(' do $SRC/modelsim/tb_scripts/' + row + '_ps.do\n')
        else:
          all_tests.write(' do $SRC/modelsim/tb_scripts/' + row + '.do\n')
        all_tests.write(' onbreak resume\n') 
        all_tests.write(' set quit_flag [eval_result $SRC $fp ' + row + ']\n')  
        all_tests.write('}\n')
        all_tests.write('incr num_tests\n')
        all_tests.write('puts "End of Tests\tTotal Tests: $num_tests"\n')
      ########################################################################
      ## Looking for old coverage database files to delete
      cover_file = os.path.join(cover_folder,'merged_result.ucdb')
      if (os.path.exists(cover_file)):
        os.remove(cover_file)
      cover_file = os.path.join(cover_folder,'merged_result.txt')
      if (os.path.exists(cover_file)):
        os.remove(cover_file)
    if (os.path.exists(os.path.join(database_folder_changed,'modelsim','tb_scripts','verification_report_not_performed.txt'))):
      os.remove(os.path.join(database_folder_changed,'modelsim','tb_scripts','verification_report_not_performed.txt'))
    if 'not_test_id_2perform' in locals():
      for row in not_test_id_2perform:  
        ########################################################################
        ## Looking for old coverage reports files to delete
        cover_file = os.path.join(database_folder,'modelsim/tb_stimuli')
        cover_file = os.path.join(cover_file,row)
        cover_file = os.path.join(cover_file,'report_coverage.txt')
        if (os.path.exists(cover_file)):
          os.remove(cover_file)
        cover_file = os.path.join(database_folder,'modelsim/tb_stimuli')
        cover_file = os.path.join(cover_file,row)
        cover_file = os.path.join(cover_file,'report_coverage_details.txt')
        if (os.path.exists(cover_file)):
          os.remove(cover_file)
        ########################################################################
        ## Report simulation not performed
        result_file = open (os.path.join(database_folder_changed,'modelsim/tb_scripts/verification_report_not_performed.txt'), 'a')
        result_file.write(row + "\t: Can't perform simulation, since there are missing files (check raw file and reference file).\n")
        result_file.close()
        ########################################################################
        ## Looking for old coverage database files to delete
        cover_file = os.path.join(cover_folder, row)
        cover_file+= '_cover.ucdb'
        if (os.path.exists(cover_file)):
          os.remove(cover_file)
      ########################################################################
      ## Looking for old coverage database files to delete
      cover_file = os.path.join(cover_folder,'merged_result.ucdb')
      if (os.path.exists(cover_file)):
        os.remove(cover_file)
      cover_file = os.path.join(cover_folder,'merged_result.txt')
      if (os.path.exists(cover_file)):
        os.remove(cover_file)
    all_tests.write('quit -sim\nclose $fp\n')
    cover_folder_changed = cover_folder.replace(sep, '/')
    all_tests.write('vcover merge ' + cover_folder_changed + '/*.ucdb -out ' + cover_folder_changed + '/merged_result.ucdb\n')
    all_tests.write('vcover report ' + cover_folder_changed + '/merged_result.ucdb -file ' + cover_folder_changed + '/merged_result.txt')
    all_tests.close()
    ########################################################################
    # End of Generate all_tests.do
    ########################################################################
    csv_file_handle.close()
  if gen_synplify:
    ########################################################################
    # Generate all_synplify.do
    ########################################################################
    csv_file_handle = open(sys.argv[1], 'rb')
    csv_reader = csv.reader(csv_file_handle, delimiter=',')
    csv_reader.next()
    csv_reader.next()
    destination_folder = os.path.join(database_folder , 'synthesis', 'syn_scripts', 'synplify')
    database_folder_changed = database_folder.replace(sep, '/')
    destination_folder_changed = destination_folder.replace(sep, '/')
    all_synplify = open (os.path.join(destination_folder, 'all_synplify.tcl'), 'w')
    if not (os.path.exists(os.path.join(destination_folder_changed, 'ccsds123_project.prj'))):
      all_synplify.write('set SRC ' + database_folder_changed + '\n' +
      'project -new ' + destination_folder_changed +'/ccsds123_project.prj\n'
      'puts "Database directory set"\n'
      'set_option -technology Virtex5\n' + 
      'set_option -part XC5VFX130T\n' +
      'set_option -top_module shyloc_123.ccsds123_top\n' + 
      'set_option -frequency 150\n' + 
      'set_option -symbolic_fsm_compiler 1\n' +
      'set_option -use_fsm_explorer 1\n')
    else:
      all_synplify.write('set SRC ' + database_folder_changed + '\n' +
      'project -load ' + destination_folder_changed +'/ccsds123_project.prj\n')
    if not (os.path.exists(os.path.join(destination_folder_changed, 'report'))):
      os.makedirs(os.path.join(destination_folder_changed, 'report'))
    else:
      files = os.listdir(os.path.join(destination_folder_changed, 'report'))
      for iterator in files:
        if iterator != "README.txt":
          os.remove(os.path.join(destination_folder_changed, 'report', iterator))
    dirs = [d for d in os.listdir(destination_folder_changed) if os.path.isdir(os.path.join(destination_folder_changed, d))]
    for iterator in dirs:
      if iterator != "report":
        folder2delete = os.path.join(destination_folder_changed, iterator)
        folder2delete_changed = folder2delete.replace(sep, '/')
        shutil.rmtree(folder2delete_changed)
    all_synplify.write('set imp [impl -list]\n'
    'foreach c_imp $imp {\n'
    'impl -remove $c_imp\n'
    '}\n')
    csv_file_handle.seek(0)
    csv_reader.next()
    csv_reader.next()
    for row in csv_reader:
      all_synplify.write('run_tcl ' + '$SRC/synthesis/syn_scripts/synplify/' + row[0] + '.tcl\n'
      )
    all_synplify.write('project -save')
    all_synplify.close()
    csv_file_handle.close()
    ########################################################################
    # End of Generate all_synplify.do
    ########################################################################
  if gen_ise:
    ########################################################################
    # Generate all_ise.do
    ########################################################################
    csv_file_handle = open(sys.argv[1], 'rb')
    csv_reader = csv.reader(csv_file_handle, delimiter=',')
    csv_reader.next()
    csv_reader.next()
    destination_folder = os.path.join(database_folder , 'synthesis', 'syn_scripts', 'ise')
    database_folder_changed = database_folder.replace(sep, '/')
    destination_folder_changed = destination_folder.replace(sep, '/')
    all_ise = open (os.path.join(destination_folder, 'all_ise.tcl'), 'w')
    if not (os.path.exists(os.path.join(destination_folder_changed, 'ccsds123_project.prj.xise'))):
      all_ise.write('set SRC ' + database_folder_changed + '\n' +
      'project new ' + destination_folder_changed +'/ccsds123_project.prj\n'
      'puts "Database directory set"\n'
      'project set family virtex5\n'
      'project set device XC5VFX130T\n'
      'project set package ff1738\n'
      'project set speed -1\n'
      'project save\n'
      'lib_vhdl new shyloc_utils\n'
      'lib_vhdl new shyloc_123\n'
      'project set "Manual Compile Order" "true"\n'
      'project set "Other XST Command Line Options" "-use_new_parser yes"\n'
      'project set top ccsds123_top\n')
    else:
      all_ise.write('set SRC ' + database_folder_changed + '\n' +
      'project close\n'
      'project open ' + destination_folder_changed +'/ccsds123_project.prj\n')
    if not (os.path.exists(os.path.join(destination_folder_changed, 'report'))):
      os.makedirs(os.path.join(destination_folder_changed, 'report'))
    else:
      shutil.rmtree(os.path.join(destination_folder_changed, 'report'))
      os.makedirs(os.path.join(destination_folder_changed, 'report'))
    rep_f = os.path.join(destination_folder_changed, 'report')
    rep_f_c = rep_f.replace(sep, '/')
    for row in csv_reader:
      all_ise.write('source ' + '$SRC/synthesis/syn_scripts/ise/' + row[0] + '.tcl\n' +
      'puts "Running synthesis with configuration:' + row[0] + '"\n' +
      'process run "Synthesize - XST"\n')
    all_ise.write('project save')
    all_ise.close()
    csv_file_handle.close()
    ########################################################################
    # End of Generate all_ise.do
    ########################################################################
  if gen_vivado:
    ########################################################################
    # Generate all_vivado.do
    ########################################################################
    csv_file_handle = open(sys.argv[1], 'rb')
    csv_reader = csv.reader(csv_file_handle, delimiter=',')
    csv_reader.next()
    csv_reader.next()
    destination_folder = os.path.join(database_folder , 'synthesis', 'syn_scripts', 'VIVADO')
    database_folder_changed = database_folder.replace(sep, '/')
    destination_folder_changed = destination_folder.replace(sep, '/')
    all_vivado = open (os.path.join(destination_folder, 'all_vivado.tcl'), 'w')
    vivado_ptr = os.path.join(destination_folder_changed, 'shyloc_123_f.xpr')
    vivado_ptr_c = vivado_ptr.replace(sep, '/')
    if not (os.path.exists(vivado_ptr_c)):
      all_vivado.write('set SRC ' + database_folder_changed + '\n' +
      'create_project shyloc_123 ' + destination_folder_changed + ' -part xc7z045ffg900-2' + '\n' +
      'set_property board_part xilinx.com:zc706:part0:1.2 [current_project]' + '\n' +
      'set_property target_language VHDL [current_project]' + '\n' +
      'set_property simulator_language VHDL [current_project]' + '\n')
    else:
      all_vivado.write('set SRC ' + database_folder_changed + '\n' +
      'open_project ' + destination_folder_changed + '/shyloc_123.xpr\n')
    if not (os.path.exists(os.path.join(destination_folder_changed, 'report'))):
      os.makedirs(os.path.join(destination_folder_changed, 'report'))
    impl_folder = os.path.join(destination_folder_changed, 'shyloc_123.runs')
    for row in csv_reader:
      for target in range(len(imp_names)):
        dest = os.path.join(impl_folder, imp_names[target])
        dest_c = dest.replace(sep, '/')
        dest_c = dest_c + '_' + row[0] 
        if (os.path.exists(dest_c)):
          shutil.rmtree(dest_c)
    all_vivado.write('set imp [get_runs]\n'
    'set a synth_1\nforeach c_imp $imp {\nif {$c_imp != $a} {\ndelete_runs $c_imp}\n}\n') 
    csv_file_handle.seek(0)
    csv_reader.next()
    csv_reader.next()
    for row in csv_reader:
      all_vivado.write('source ' + '$SRC/synthesis/syn_scripts/VIVADO/' + row[0] + '.tcl\n'
      )
    all_vivado.close()
    csv_file_handle.close()
    ########################################################################
    # End of Generate all_vivado.do
    ########################################################################
    if gen_brave:
      ########################################################################
      # Generate all_nanoxplore.py
      ########################################################################
      csv_file_handle = open(sys.argv[1], 'rb')
      csv_reader = csv.reader(csv_file_handle, delimiter=',')
      csv_reader.next()
      csv_reader.next()
      destination_folder = os.path.join(database_folder , 'synthesis', 'syn_scripts', 'brave')
      database_folder_changed = database_folder.replace(sep, '/')
      destination_folder_changed = destination_folder.replace(sep, '/')
      if not (os.path.exists(os.path.join(destination_folder_changed, 'report'))):
        os.makedirs(os.path.join(destination_folder_changed, 'report'))
      if not (os.path.exists(os.path.join(destination_folder_changed, 'results'))):
        os.makedirs(os.path.join(destination_folder_changed, 'results'))
      all_brave = open (os.path.join(destination_folder, 'all_nanoxplore.py'), 'w')
      all_brave.write('import os, shutil\n')
      for row in csv_reader:
        for target in range(5,7):
          all_brave.write('os.system("python3 ' + row[0] + '_' + technologies[target] +'.py")\n')
          logString = os.path.join(destination_folder,'logs','general.log')
          newLogString = os.path.join(destination_folder,'report',row[0],'general_' + technologies[target] +'.log')
          commandString = "shutil.copy('" + logString + "','" + newLogString + "')\n"
          all_brave.write(commandString)
      all_brave.close()
      csv_file_handle.close()
      ########################################################################
      # End of all_nanoxplore.py
      ########################################################################
  if gen_dc:
  ########################################################################
  # Generate all_dc.do
  ########################################################################
    csv_file_handle = open(sys.argv[1], 'rb')
    csv_reader = csv.reader(csv_file_handle, delimiter=',')
    csv_reader.next()
    csv_reader.next()
    destination_folder = os.path.join(database_folder , 'synthesis', 'syn_scripts', 'dc')
    database_folder_changed = database_folder.replace(sep, '/')
    destination_folder_changed = destination_folder.replace(sep, '/')
    all_dc = open (os.path.join(destination_folder, 'all_dc.tcl'), 'w')
    all_dc.write('set SRC ' + database_folder_changed + '\n')
    all_dc.write('set_app_var search_path ". ' + destination_folder + '/base $search_path"\n') 
    if not (os.path.exists(os.path.join(destination_folder_changed, 'report'))):
      os.makedirs(os.path.join(destination_folder_changed, 'report'))
    else:
      files = os.listdir(os.path.join(destination_folder_changed, 'report'))
      files.remove("README.txt")
      for iterator in files:
        f = os.path.join(destination_folder_changed, 'report', iterator)
        if os.path.isdir(f) == True:
          shutil.rmtree(f)
        else:
          os.remove(f)
    dirs = [d for d in os.listdir(destination_folder_changed) if os.path.isdir(os.path.join(destination_folder_changed, d))]
    csv_file_handle.seek(0)
    csv_reader.next()
    csv_reader.next()
    for row in csv_reader:
      all_dc.write('puts "Starting Synthesis of ' + row[0] + '\\n"\n')
      all_dc.write('set TEST_ID ' + row[0] + '\n')
      #all_dc.write('redirect ' + row[0] + '_dc.log {source dc.tcl}\n')
      all_dc.write('source dc.tcl\n')
      all_dc.write('puts "Finished Synthesis of ' + row[0] + '\\n"\n')
      all_dc.write('remove_design -all\n')
      #all_dc.write('source ' + '$SRC/synthesis/syn_scripts/dc/' + row[0] + '.tcl\n')     
    all_dc.write('exit\n')
    all_dc.close()
    csv_file_handle.close()
  ########################################################################
  # End of Generate all_dc.do
  ########################################################################
