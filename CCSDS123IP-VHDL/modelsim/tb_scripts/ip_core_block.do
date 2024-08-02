vcom -93 -quiet -check_synthesis -work shyloc_121 $SRC121/src/shyloc_121/ccsds121_constants.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 $SRC121/src/shyloc_121/config121_package.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/splitter.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/optcoder.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/lkcomp.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/header121_shyloc.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/sndextension.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/packing_top.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/fscoderv2.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/lkoptions.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 $SRC121/src/shyloc_121/ccsds121_shyloc_interface.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/ccsds121_clk_adapt.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 $SRC121/src/shyloc_121/ccsds121_ahbs.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/ccsds121_shyloc_comp.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/ccsds121_shyloc_fsm.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/ccsds121_blockcoder_top.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/ccsds121_predictor_comp.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/ccsds121_predictor_fsm.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/ccsds121_predictor_top.vhd
vcom -93 -quiet -check_synthesis -work shyloc_121 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC121/src/shyloc_121/ccsds121_shyloc_top.vhd
vcom -93 -quiet -check_synthesis -work post_syn_lib $SRC121/src/post_syn/ccsds121_top_wrapper.vhd
