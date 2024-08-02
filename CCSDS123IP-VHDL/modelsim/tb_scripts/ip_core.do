vcom -93 -quiet  -check_synthesis -work shyloc_utils  $SRC/src/shyloc_utils/amba.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils  $SRC/src/shyloc_utils/shyloc_functions.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/reg_bank_inf.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/reg_bank_tech.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/reg_bank.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils  $SRC/src/shyloc_utils/edac-0-7-src/edac-decl-0-7.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils  $SRC/src/shyloc_utils/edac-0-7-src/edac-body-0-7.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils  $SRC/src/shyloc_utils/edac-0-7-src/edac-rtl.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/fixed_shifter.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/barrel_shifter.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils  $SRC/src/shyloc_utils/bitpackv2.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/toggle_sync.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/reset_sync.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/fifop2_base.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils  $SRC/src/shyloc_utils/fifop2_edac.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_utils -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_utils/fifop2.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123  $SRC/src/shyloc_123/ccsds123_constants.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123  $SRC/src/shyloc_123/config123_package.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123  $SRC/src/shyloc_123/ccsds123_shyloc_interface.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/clip.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/create_cdwv2.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ff.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/fifo_ctr_funcs.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/finished_gen.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/header123_gen.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ld_2d_fifo.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ld_2d_fifo_bil.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/localdiff_shift.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/localdiffv3.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/localsumv2.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/map2stagesv2.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/mult.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/mult_acc2stagesv2.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/opcode_update.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/packing_top_123.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/predictor2stagesv2.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/record_2d_fifo.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ro_update_mathv3_diff.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/count_updatev2.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/sample_comp.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/sample_fsm.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/sample_top.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/wei_2d_fifo.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/weight_update_shyloc.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/weight_update_shyloc_top.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/adder.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/n_adders.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/n_adders_top.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds_ahb_types.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ahb_utils.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123  $SRC/src/shyloc_123/ccsds123_ahbs.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ahbtbm_ctrl_bi.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ahbtbm_ctrl_bsq.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123  $SRC/src/shyloc_123/ccsds123_ahb_mst.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/async_fifo_write_ctrl.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/async_fifo_read_ctrl.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/async_fifo_synchronizer_g.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/async_fifo_ctrl.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/async_fifo.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds_fsm_shyloc_bip.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds_fsm_shyloc_bip_mem.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds_fsm_shyloc_bil.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds_fsm_shyloc_bil_mem.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds_fsm_shyloc_bsq.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds123_clk_adapt.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds123_config_core.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds123_dispatcher.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/mult_acc_shyloc.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds_comp_shyloc_bip.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds_comp_shyloc_bip_mem.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds_comp_shyloc_bil.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds_comp_shyloc_bil_mem.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds_comp_shyloc_bsq.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/predictor_shyloc.vhd
vcom -93 -quiet  -check_synthesis -work shyloc_123 -nocoverfec -cover sbcf3 -coverexcludedefault $SRC/src/shyloc_123/ccsds123_top.vhd
vcom -93 -quiet  -check_synthesis -work post_syn_lib  $SRC/src/post_syn/ccsds123_top_wrapper.vhd
