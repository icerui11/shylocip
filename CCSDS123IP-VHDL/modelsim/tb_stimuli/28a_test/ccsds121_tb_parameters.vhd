

library ieee;
use ieee.std_logic_1164.all;
library shyloc_121;
use shyloc_121.ccsds121_parameters.all;
library shyloc_utils;
 use shyloc_utils.shyloc_functions.all;

package ccsds121_tb_parameters is

-- TEST: 28a_test
   constant test_id: integer := 0;

   constant clk_ip: time :=100 ns;
   constant EN_RUNCFG_G: integer := shyloc_121.ccsds121_parameters.EN_RUNCFG;
   constant RESET_TYPE: integer := shyloc_121.ccsds121_parameters.RESET_TYPE;

   constant HSINDEX_121: integer := shyloc_121.ccsds121_parameters.HSINDEX_121;
   constant HSCONFIGADDR_121: integer := shyloc_121.ccsds121_parameters.HSCONFIGADDR_121;
   constant HSADDRMASK_121: integer := shyloc_121.ccsds121_parameters.HSADDRMASK_121;

   constant Nx_tb: integer := 7;
   constant Ny_tb: integer := 8;
   constant Nz_tb: integer := 5;
   constant D_tb: integer := 16;
   constant ENDIANESS_tb: integer := 1;
   constant IS_SIGNED_tb: integer := 0;
   constant J_tb: integer := 16;
   constant REF_SAMPLE_tb: integer := 256;
   constant CODESET_tb: integer := 0;
   constant W_BUFFER_tb : integer := 32;
   constant BYPASS_tb: integer := 0;
   constant PREPROCESSOR_tb: integer := 1;
   constant DISABLE_HEADER_tb: integer :=0;
   constant stim_file: string := "STIMULI\raw\28a_test\allones_h8w7b5_16uint_be.bil";
   constant ref_file: string := "STIMULI\reference\28a_test\comp_28.esa.esa";
   constant out_file: string := "STIMULI\28a_test\comp_28.esa.vhd";
   constant D_G_tb : integer := shyloc_121.ccsds121_parameters.D_GEN;
   constant W_BUFFER_G_tb : integer := shyloc_121.ccsds121_parameters.W_BUFFER_GEN;
   constant N_SAMPLES_G_tb : integer := (Nx_tb*Ny_tb*Nz_tb);
   constant W_N_SAMPLES_G_tb : integer := log2(N_SAMPLES_G_tb);
   constant CODESET_G_tb : integer := shyloc_121.ccsds121_parameters.CODESET_GEN;
   constant N_K_G_tb: integer := get_n_k_options (D_G_tb, CODESET_G_tb);
   constant W_K_G_tb: integer := maximum(3,log2(N_K_G_tb)+1);
   constant W_NBITS_K_G_tb: integer := get_k_bits_option(W_BUFFER_G_tb, CODESET_G_tb, W_K_G_tb);

end ccsds121_tb_parameters;
