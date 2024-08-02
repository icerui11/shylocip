--------------------------------------------------------------------------------
-- Company: IUMA, ULPGC
-- Author: Lucana Santos
-- e-mail: lsfalcon@iuma.ulpgc.es
--------------------------------------------------------------------------------

library ieee;
library std;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
---------------------------------------------


--!@file #ccsds_shyloc_tb_parameters.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Sitimuli and reference files for the SHyLoC compressor

package ccsds_shyloc_tb_parameters is 
  function str_2_lv (a : in string) return std_logic_vector;
--**********************************************************************************************--  
-- Test: Uncalibrated AVIRIS 
-- Size LxCxB: 4x4x5

  -- constant stim_file: string := "STIMULI\PRELIMINARY\BIP_IMAGE";
  -- constant ref_file: string  := "STIMULI\PRELIMINARY\out_4_4_5.bip";
  -- constant out_file: string  := "STIMULI\PRELIMINARY\HDL_out_4_4_5.bip";
  -- constant PREDICTION_TYPE_conf: integer := 1; 
  
  
  -- constant stim_file: string := "STIMULI\PRELIMINARY\BSQ_IMAGE";
  -- constant ref_file: string  := "STIMULI\PRELIMINARY\out_4_4_5.bsq";
  -- constant out_file: string  := "STIMULI\PRELIMINARY\HDL_out_4_4_5.bsq";
  -- constant PREDICTION_TYPE_conf: integer := 2;

  
  -- constant stim_file: string := "STIMULI\PRELIMINARY\BIL_IMAGE";
  -- constant ref_file: string  := "STIMULI\PRELIMINARY\out_4_4_5.bil";
  -- constant out_file: string  := "STIMULI\PRELIMINARY\HDL_out_4_4_5.bil";
  -- constant PREDICTION_TYPE_conf: integer := 3;
  
  
  -- constant Nx_conf: integer := 4;
  -- constant D_conf: integer := 16;
  -- constant IS_SIGNED_conf: integer := 0;
  -- constant DISABLE_HEADER_conf: integer := 0;
  -- constant ENCODER_SELECTION_conf: integer := 1;
  -- constant P_conf: integer := 3;
  -- constant BYPASS_conf: integer := 0;
  
  -- constant Ny_conf: integer := 4;
  -- constant PREDICTION_conf: integer := 0;
  -- constant LOCAL_SUM_conf: integer := 0;
  -- constant OMEGA_conf: integer := 13;
  -- constant R_conf: integer := 32;
  
  -- constant Nz_conf: integer := 5;
  -- constant VMAX_conf: integer := 3;
  -- constant VMIN_conf: integer := -1;
  -- constant TINC_conf: integer := 11;
  -- constant WEIGHT_INIT_conf: integer := 0;
  -- constant ENDIANESS_conf: integer := 1;
  
  -- constant INIT_COUNT_E_conf: integer := 1;
  -- constant ACC_INIT_TYPE_conf: integer := 0;
  -- constant ACC_INIT_CONST_conf: integer := 5;
  -- constant RESC_COUNT_SIZE_conf: integer := 6;
  -- constant U_MAX_conf: integer := 16;
  -- constant W_BUFFER_conf: integer := 32;

  -- constant Q_conf: integer := 5;
  -- constant ExtMemAddress_conf : std_logic_vector(31 downto 0) := x"40000000"; ---ahb interface---
--**********************************************************************************************--   

--**********************************************************************************************--  
-- Test: artifacts_h8w7b17_16uint_be
-- Size LxCxB: 7x8x16
--  06_set

  -- constant stim_file: string := "STIMULI\PRELIMINARY\artifacts_h8w7b17_16uint_be.bil";
  -- constant ref_file: string  := "STIMULI\PRELIMINARY\comp_46.esa";
  -- constant out_file: string  := "STIMULI\PRELIMINARY\comp_46.shyloc";
  -- constant PREDICTION_TYPE_conf: integer := 3;

  -- constant Nx_conf: integer := 7;
  -- constant Ny_conf: integer := 8;
  -- constant Nz_conf: integer := 17;
  
  -- constant D_conf: integer := 16;
  -- constant IS_SIGNED_conf: integer := 0;
  -- constant DISABLE_HEADER_conf: integer := 0;
  -- constant ENCODER_SELECTION_conf: integer := 1;
  -- constant P_conf: integer := 3;
  -- constant BYPASS_conf: integer := 0;
  
  -- constant PREDICTION_conf: integer := 0;
  -- constant LOCAL_SUM_conf: integer := 0;
  -- constant OMEGA_conf: integer := 13;
  -- constant R_conf: integer := 32;
  
  
  -- constant VMAX_conf: integer := 3;
  -- constant VMIN_conf: integer := -1;
  -- constant TINC_conf: integer := 11;
  -- constant WEIGHT_INIT_conf: integer := 0;
  
  -- constant ENDIANESS_conf: integer := 1;
  
  -- constant INIT_COUNT_E_conf: integer := 1;
  -- constant ACC_INIT_TYPE_conf: integer := 0;
  -- constant ACC_INIT_CONST_conf: integer := 5;
  -- constant RESC_COUNT_SIZE_conf: integer := 6;
  -- constant U_MAX_conf: integer := 16;
  -- constant W_BUFFER_conf: integer := 32;
  
  -- constant Q_conf: integer := 5;
  
--**********************************************************************************************--  
-- Test: UNCAL_AVIRISL16C16B21_u16b
-- Size LxCxB: 16x16x21
--  06_set_mod

   constant stim_file: string := "STIMULI\PRELIMINARY\UNCAL_AVIRISL16C16B21_u16b";
   constant ref_file: string  := "STIMULI\PRELIMINARY\ESA_comp.fl";
   constant out_file: string  := "STIMULI\PRELIMINARY\ESA_comp.shyloc";
   constant PREDICTION_TYPE_conf: integer := 2;
   constant ENCODER_SELECTION_conf: integer := 0;
   constant DISABLE_HEADER_conf: integer := 1;

   constant Nx_conf: integer := 16;
   constant Ny_conf: integer := 16;
   constant Nz_conf: integer := 21;
   constant ACC_INIT_CONST_conf: integer := 3;
   
--**********************************************************************************************--  
--**********************************************************************************************--  
-- Test: tiny_L16C16B21_u.bil
-- Size LxCxB: 16x16x21
--  06_set_mod

   -- constant stim_file: string := "STIMULI\PRELIMINARY\tiny_L16C16B21_u.bil";
   -- constant ref_file: string  := "STIMULI\PRELIMINARY\ESA_comp2.fl";
   -- constant out_file: string  := "STIMULI\PRELIMINARY\ESA_comp2.shyloc";
   -- constant PREDICTION_TYPE_conf: integer := 3;
   -- constant ENCODER_SELECTION_conf: integer := 1;
   -- constant DISABLE_HEADER_conf: integer := 0;

   -- constant Nx_conf: integer := 16;
   -- constant Ny_conf: integer := 16;
   -- constant Nz_conf: integer := 21;
   -- constant ACC_INIT_CONST_conf: integer := 3;
--**********************************************************************************************--  

--**********************************************************************************************--  
-- Test: airs_L16C16B21_u.bip
-- Size LxCxB: 16x16x21
--  06_set_mod

   -- constant stim_file: string := "STIMULI\PRELIMINARY\airs_L16C16B21_u.bip";
   -- constant ref_file: string  := "STIMULI\PRELIMINARY\ESA_comp3.fl";
   -- constant out_file: string  := "STIMULI\PRELIMINARY\ESA_comp3.shyloc";
  
   -- constant PREDICTION_TYPE_conf: integer := 1;
   -- constant ENCODER_SELECTION_conf: integer := 1;
   -- constant DISABLE_HEADER_conf: integer := 1;

   -- constant Nx_conf: integer := 16;
   -- constant Ny_conf: integer := 16;
   -- constant Nz_conf: integer := 21;
   -- constant ACC_INIT_CONST_conf: integer := 3;
--**********************************************************************************************--  
  
  -----------------------06_set_mod ---------------------------------
  constant D_conf: integer := 16;
  constant IS_SIGNED_conf: integer := 0;

  constant P_conf: integer := 3;
  constant BYPASS_conf: integer := 0;
  
  constant PREDICTION_conf: integer := 0;
  constant LOCAL_SUM_conf: integer := 0;
  constant OMEGA_conf: integer := 13;
  constant R_conf: integer := 32;
  
  constant VMAX_conf: integer := 3;
  constant VMIN_conf: integer := -1;
  constant TINC_conf: integer := 6;
  constant WEIGHT_INIT_conf: integer := 0;
  
  
  constant ENDIANESS_conf: integer := 1; ----1 means big endian; 0 means little (byte swap at the input)
  
  constant INIT_COUNT_E_conf: integer := 1;
  constant ACC_INIT_TYPE_conf: integer := 0;
  constant RESC_COUNT_SIZE_conf: integer := 6;
  constant U_MAX_conf: integer := 16;
  constant W_BUFFER_conf: integer := 32;
  
  constant Q_conf: integer := 1;
  -- Modified by AS: New configuration parameters for CWI --
  constant WR_conf: integer := 1;
  constant CWI_conf: integer = 0;
  ------------------------------------
  
  -----------------------/end 06_set_mod ---------------------------------

-----------------------COMMON GENERICS TO ALL TESTS ABOVE THIS LINE-----------------------
  constant ENCODING_TYPE_G: integer := 1;
  constant EN_RUNCFG_G: integer := 1;
  constant EDAC_G: integer  :=  0;
  constant RESET_TYPE_G: integer :=  0;
  constant AHB_MEM_G: integer :=  1;
  constant PREDICTION_TYPE_GEN: integer := PREDICTION_TYPE_conf;
  constant ENCODER_SELECTION: INTEGER := ENCODER_SELECTION_conf;
  
  constant Nx: integer := 256;
  constant Ny: integer := 256;
  constant Nz: integer := 256;
  constant D: integer := 16;
  constant IS_SIGNED_INT: integer := 0;
  constant DISABLE_HEADER: integer := 0;
  constant P: integer := 7;
  constant PREDICTION: integer := 0;
  constant LOCAL_SUM: integer := 0;
  constant OMEGA: integer := 19;
  constant R: integer := 64;
  
  constant VMAX: integer := 9;
  constant VMIN: integer := -6;
  constant TINC: integer := 11;
  constant WEIGHT_INIT: integer := 0;
  constant ENDIANESS: integer := 1;
  
  constant INIT_COUNT_E: integer := 8;
  constant ACC_INIT_TYPE: integer := 0;
  constant ACC_INIT_CONST: integer := 14;
  constant RESC_COUNT_SIZE: integer := 9;
  constant U_MAX: integer := 16;
  constant W_BUFFER: integer := 32;

  constant Q: integer := 1;
  -- Modified by AS: New configuration parameters for CWI --
  constant WR: integer := 1;
  constant CWI: integer := 1;
  ----------------------------
-----------------------COMMON GENERICS TO ALL TESTS ABOVE THIS LINE-----------------------  

--**********************************************************************************************--  
-- Test: Set07 - bsq, bip, bil

  -- constant stim_file: string := "STIMULI\PRELIMINARY\BIP_IMAGE";
  -- constant ref_file: string  := "STIMULI\PRELIMINARY\res07_bip.esa";
  -- constant out_file: string  := "STIMULI\PRELIMINARY\res07_bip.vhd";
  -- constant PREDICTION_TYPE_conf: integer := 1; 
  
  
  -- constant stim_file: string := "STIMULI\PRELIMINARY\BSQ_IMAGE";
  -- constant ref_file: string  := "STIMULI\PRELIMINARY\res07_bsq.esa";
  -- constant out_file: string  := "STIMULI\PRELIMINARY\res07_bsq.vhd";
  -- constant PREDICTION_TYPE_conf: integer := 2;

  
  -- constant stim_file: string := "STIMULI\PRELIMINARY\BIL_IMAGE";
  -- constant ref_file: string  := "STIMULI\PRELIMINARY\res07_bil.esa";
  -- constant out_file: string  := "STIMULI\PRELIMINARY\res07_bil.vhd";
  -- constant PREDICTION_TYPE_conf: integer := 3;
  
  ------------------ GENERIC AND RUNTIME --------------
  -- constant ENCODING_TYPE_G: integer  := 1;
  -- constant EN_RUNCFG_G: integer  := 1;
  
  -- constant EDAC_G: integer :=  0; --constant EDAC_G: integer := 1;
  -- constant RESET_TYPE_G: integer :=  1;
  -- constant AHB_MEM_G: integer :=  1;
  
  -- constant PREDICTION_TYPE_GEN: integer := PREDICTION_TYPE_conf;
  -- constant PREDICTION: integer := 0;
  -- constant LOCAL_SUM: integer := 1;
  -- constant P: integer := 3;
  
  
  
  -- constant Nx_conf: integer := 4;
  -- constant D_conf: integer := 16;
  -- constant IS_SIGNED_conf: integer := 0;
  -- constant DISABLE_HEADER_conf: integer := 1;
  -- constant ENCODER_SELECTION_conf: integer := 0;
  -- constant P_conf: integer := 0;
  -- constant BYPASS_conf: integer := 0;
  -- constant ENCODER_SELECTION: INTEGER := ENCODER_SELECTION_conf;
  
  -- constant Nx: integer := 1024;
  -- constant D: integer := 16;
  -- constant IS_SIGNED: integer := 0;
  -- constant DISABLE_HEADER: integer := 0;
  -- constant BYPASS: integer := 0;
  
  -- constant Ny_conf: integer := 4;
  -- constant PREDICTION_conf: integer := 1;
  -- constant LOCAL_SUM_conf: integer := 1;
  -- constant OMEGA_conf: integer := 16;
  -- constant R_conf: integer := 64;
  
  -- constant Ny: integer := 1024;
  -- constant OMEGA: integer := 19;
  -- constant R: integer := 64;
  
  -- constant Nz_conf: integer := 5;
  -- constant VMAX_conf: integer := 7;
  -- constant VMIN_conf: integer := -5;
  -- constant TINC_conf: integer := 7;
  -- constant WEIGHT_INIT_conf: integer := 0;
  -- constant ENDIANESS_conf: integer := 1;
  
  -- constant Nz: integer := 1024;
  -- constant VMAX: integer := 9;
  -- constant VMIN: integer := -6;
  -- constant TINC: integer := 11;
  -- constant WEIGHT_INIT: integer := 0;
  -- constant ENDIANESS: integer := 0;
  
  
  -- constant INIT_COUNT_E_conf: integer := 0;
  -- constant ACC_INIT_TYPE_conf: integer := 0;
  -- constant ACC_INIT_CONST_conf: integer := 0;
  -- constant RESC_COUNT_SIZE_conf: integer := 0;
  -- constant U_MAX_conf: integer := 0;
  -- constant W_BUFFER_conf: integer := 64;
  
  -- constant INIT_COUNT_E: integer := 8;
  -- constant ACC_INIT_TYPE: integer := 0;
  -- constant ACC_INIT_CONST: integer := 14;
  -- constant RESC_COUNT_SIZE: integer := 9;
  -- constant U_MAX: integer := 16;
  -- constant W_BUFFER: integer := 64;

  -- constant Q_conf: integer := 0;
  -- constant Q: integer := 0;

--**********************************************************************************************--
  
--**********************************************************************************************--  
-- Test: Test09 - bsq, bip, bil

  --constant stim_file: string := "STIMULI\PRELIMINARY\BIP_IMAGE";
  --constant ref_file: string  := "STIMULI\PRELIMINARY\set09_bip.esa";
  --constant out_file: string  := "STIMULI\PRELIMINARY\set09_bip.vhd";
  --constant PREDICTION_TYPE_conf: integer := 1; 
  
  -- constant stim_file: string := "STIMULI\PRELIMINARY\BSQ_IMAGE";
  -- constant ref_file: string  := "STIMULI\PRELIMINARY\set09_bsq.esa";
  -- constant out_file: string  := "STIMULI\PRELIMINARY\set09_bsq.vhd";
  -- constant PREDICTION_TYPE_conf: integer := 2;

  
  -- constant stim_file: string := "STIMULI\PRELIMINARY\BIL_IMAGE";
  -- constant ref_file: string  := "STIMULI\PRELIMINARY\set09_bil.esa";
  -- constant out_file: string  := "STIMULI\PRELIMINARY\set09_bil.vhd";
  -- constant PREDICTION_TYPE_conf: integer := 3;
  

  -- constant ENCODING_TYPE_G : integer := 1;
  -- constant EN_RUNCFG_G: integer  := 1;
  -- constant EDAC_G: integer := 0;
  -- constant RESET_TYPE_G: integer := 1;
  -- constant AHB_MEM_G: integer := 1;
  
  -- constant PREDICTION_TYPE_GEN: integer := PREDICTION_TYPE_conf;

  
  -- constant Nx_conf: integer := 4;
  -- constant D_conf: integer := 16;
  -- constant IS_SIGNED_conf: integer := 0;
  -- constant DISABLE_HEADER_conf: integer := 0;
  -- constant ENCODER_SELECTION_conf: integer := 1;
  -- constant P_conf: integer := 15;
  -- constant BYPASS_conf: integer := 0;
  
  -- constant Nx: integer := 1024;
  -- constant D: integer := 16;
  -- constant IS_SIGNED: integer := 0;
  -- constant DISABLE_HEADER: integer := 0;
  -- constant ENCODER_SELECTION: integer := 1;
  -- constant P: integer := 15;
  -- constant BYPASS: integer := 0;
  
  -- constant Ny_conf: integer := 4;
  -- constant PREDICTION_conf: integer := 0;
  -- constant LOCAL_SUM_conf: integer := 1;
  -- constant OMEGA_conf: integer := 18;
  -- constant R_conf: integer := 32;
  
  -- constant Ny: integer := 1024;
  -- constant PREDICTION: integer := 0;
  -- constant LOCAL_SUM: integer := 0;
  -- constant OMEGA: integer := 19;
  -- constant R: integer := 64;
  
  -- constant Nz_conf: integer := 5;
  -- constant VMAX_conf: integer := 3;
  -- constant VMIN_conf: integer := -2;
  -- constant TINC_conf: integer := 4;
  -- constant WEIGHT_INIT_conf: integer := 0;
  -- constant ENDIANESS_conf: integer := 1;
  
  -- constant Nz: integer := 1024;
  -- constant VMAX: integer := 9;
  -- constant VMIN: integer := -6;
  -- constant TINC: integer := 11;
  -- constant WEIGHT_INIT: integer := 0;
  -- constant ENDIANESS: integer := 0;
  
  
  -- constant INIT_COUNT_E_conf: integer := 3;
  -- constant ACC_INIT_TYPE_conf: integer := 0;
  -- constant ACC_INIT_CONST_conf: integer := 2;
  -- constant RESC_COUNT_SIZE_conf: integer := 4;
  -- constant U_MAX_conf: integer := 16;
  -- constant W_BUFFER_conf: integer := 64;
  
  -- constant INIT_COUNT_E: integer := 8;
  -- constant ACC_INIT_TYPE: integer := 0;
  -- constant ACC_INIT_CONST: integer := 14;
  -- constant RESC_COUNT_SIZE: integer := 9;
  -- constant U_MAX: integer := 16;
  -- constant W_BUFFER: integer := 64;

  -- constant Q_conf: integer := 0;
  
  -- constant Q: integer := 0;
  
  
--**********************************************************************************************--  
--**********************************************************************************************--  
-- Test: Test10 - bsq, bip, bil

  -- constant stim_file: string := "STIMULI\PRELIMINARY\BIP_IMAGE";
  -- constant ref_file: string  := "STIMULI\PRELIMINARY\res10_bip.esa";
  -- constant out_file: string  := "STIMULI\PRELIMINARY\res10_bip.vhd";
  -- constant PREDICTION_TYPE_conf: integer := 1; 
  
  -- constant stim_file: string := "STIMULI\PRELIMINARY\BSQ_IMAGE";
  -- constant ref_file: string  := "STIMULI\PRELIMINARY\no_header_set10_bsq.esa";
  -- constant out_file: string  := "STIMULI\PRELIMINARY\no_header_set10_bsq.vhd";
  -- constant PREDICTION_TYPE_conf: integer := 2;

  
  -- constant stim_file: string := "STIMULI\PRELIMINARY\BIL_IMAGE";
  -- constant ref_file: string  := "STIMULI\PRELIMINARY\no_header_set10_bil.esa";
  -- constant out_file: string  := "STIMULI\PRELIMINARY\no_header_set10_bil.vhd";
  -- constant PREDICTION_TYPE_conf: integer := 3;


  -- constant ENCODING_TYPE_G: integer  := 0;
  -- constant EN_RUNCFG_G: integer  := 1;
  -- constant EDAC_G: integer := 0;
  -- constant RESET_TYPE_G: integer := 0;
  -- constant AHB_MEM_G: integer := 0;
  
  -- constant PREDICTION_TYPE_GEN: integer := PREDICTION_TYPE_conf; --constant PREDICTION_TYPE_conf: integer := 0;
  
  -- constant Nx_conf: integer := 4;
  -- constant D_conf: integer := 16;
  -- constant IS_SIGNED_conf: integer := 0;
  -- constant DISABLE_HEADER_conf: integer := 1;
  -- constant ENCODER_SELECTION_conf: integer := 0;
  -- constant P_conf: integer := 4;
  -- constant BYPASS_conf: integer := 0;
  
  -- constant Nx: integer := 256;
  -- constant D: integer := 16;
  -- constant IS_SIGNED: integer := 0;
  -- constant DISABLE_HEADER: integer := 0;
  -- constant ENCODER_SELECTION: integer := 0;
  -- constant P: integer := 6;
  -- constant BYPASS: integer := 0;
  
  -- constant Ny_conf: integer := 4;
  -- constant PREDICTION_conf: integer := 1;
  -- constant LOCAL_SUM_conf: integer := 1;
  -- constant OMEGA_conf: integer := 5;
  -- constant R_conf: integer := 32;
  
  -- constant Ny: integer := 256;
  -- constant PREDICTION: integer := 0;
  -- constant LOCAL_SUM: integer := 0;
  -- constant OMEGA: integer := 19;
  -- constant R: integer := 32;
  
  -- constant Nz_conf: integer := 5;
  -- constant VMAX_conf: integer := 1;
  -- constant VMIN_conf: integer := -1;
  -- constant TINC_conf: integer := 4;
  -- constant WEIGHT_INIT_conf: integer := 0;
  -- constant ENDIANESS_conf: integer := 1;
  
  -- constant Nz: integer := 256;
  -- constant VMAX: integer := 9;
  -- constant VMIN: integer := -6;
  -- constant TINC: integer := 11;
  -- constant WEIGHT_INIT: integer := 0;
  -- constant ENDIANESS: integer := 0;
  
  
  -- constant INIT_COUNT_E_conf: integer := 3;
  -- constant ACC_INIT_TYPE_conf: integer := 0;
  -- constant ACC_INIT_CONST_conf: integer := 2;
  -- constant RESC_COUNT_SIZE_conf: integer := 4;
  -- constant U_MAX_conf: integer := 16;
  -- constant W_BUFFER_conf: integer := 32;
  
  -- constant INIT_COUNT_E: integer := 0;
  -- constant ACC_INIT_TYPE: integer := 0;
  -- constant ACC_INIT_CONST: integer := 0;
  -- constant RESC_COUNT_SIZE: integer := 0;
  -- constant U_MAX: integer := 0;
  -- constant W_BUFFER: integer := 64;

  -- constant Q_conf: integer := 0;
  
  -- constant Q: integer := 0;

--**********************************************************************************************--  
--**********************************************************************************************--  


--**********************************************************************************************--  
--  constant stim_file: string := "STIMULI\REDUCED_PREDICTION\UNSIGNED16X16X21\UNCAL_AVIRISL16C16B21_u16b";
--  constant ref_file: string  := "STIMULI\REDUCED_PREDICTION\UNSIGNED16X16X21\comp.fl";
--**********************************************************************************************--  

--**********************************************************************************************--  
-- Test1: UNCALIBRATED AVIRIS 
-- Size LxCxB: 16X16X224 - SIGNED
-- Config: 3MI

--  constant stim_file: string := "STIMULI\TEST-1\UNCAL_AVIRISL16C16B224_u16b";
--  constant ref_file: string  := "STIMULI\TEST-1\comp.fl";

--**********************************************************************************************--  

--**********************************************************************************************--  
-- Test2: CALIBRATED AVIRIS 
-- Size LxCxB: 16X16X224 - SIGNED
-- Config: 3MI

--  constant stim_file: string := "STIMULI\TEST-2\CAL_AVIRISL16C16B224_s16b";
--  constant ref_file: string  := "STIMULI\TEST-2\comp.fl";

--**********************************************************************************************--  


--**********************************************************************************************--  
-- Test3: INPUT IMAGE 8 BITS
-- Size LxCxB: 16X16X12 - UNSIGNED
-- Config: 3MI

--  constant stim_file: string := "STIMULI\TEST-3\MODISL16C16B12_u8bits";
--  constant ref_file: string  := "STIMULI\TEST-3\comp.fl";

--**********************************************************************************************--

--**********************************************************************************************--  
-- Test4: ONES
-- Size LxCxB: 16X16X224 - UNSIGNED
-- Config: 3mi

--  constant stim_file: string := "STIMULI\TEST-4\onesL16C16B5u_16b";
--  constant ref_file: string  := "STIMULI\TEST-4\comp.fl";

--**********************************************************************************************--  

--**********************************************************************************************--  
-- Test5: ZEROS
-- Size LxCxB: 16X16X224 - UNSIGNED
-- Config: 3mi

--  constant stim_file: string := "STIMULI\TEST-5\zerosL16C16B5u_16b";
--  constant ref_file: string  := "STIMULI\TEST-5\comp.fl";

--**********************************************************************************************--  

--**********************************************************************************************--  
-- Test6-1: COMPRESSOR PARAMTERS CHANGED -1 
-- Size LxCxB: 16X16X224 - UNSIGNED
-- Config: config1

--  constant stim_file: string := "STIMULI\TEST6-1\UNCAL_AVIRISL16C16B224_u16b";
--  constant ref_file: string  := "STIMULI\TEST6-1\comp.fl";

--**********************************************************************************************--

--**********************************************************************************************--  
-- Test6-2: COMPRESSOR PARAMTERS CHANGED - 2 
-- Size LxCxB: 16X16X224 - UNSIGNED
-- Config: config2

--  constant stim_file: string := "STIMULI\TEST6-2\UNCAL_AVIRISL16C16B224_u16b";
--  constant ref_file: string  := "STIMULI\TEST6-2\comp.fl";

--**********************************************************************************************--  

--**********************************************************************************************--  
-- Test6-3: COMPRESSOR PARAMTERS CHANGED - 3 
-- Size LxCxB: 16X16X224 - UNSIGNED
-- Config: 3mi

--  constant stim_file: string := "STIMULI\TEST6-3\UNCAL_AVIRISL16C16B224_u16b";
--  constant ref_file: string  := "STIMULI\TEST6-3\comp.fl";

--**********************************************************************************************--  


--**********************************************************************************************--  
-- Test7: NOT SQUARED DIMENSIONS
-- Size LxCxB: 7X31X224 - UNSIGNED
-- Config: 3mi

--  constant stim_file: string := "STIMULI\TEST7\UNCAL_AVIRISL7C31B224_u16b";
--  constant ref_file: string  := "STIMULI\TEST7\comp.fl";

--**********************************************************************************************--  

--**********************************************************************************************--  
-- Test8: 3mi 
-- Size LxCxB: 16X16X21 - UNSIGNED
-- Config: 3mi

--  constant stim_file: string := "STIMULI\TEST8\UNCAL_AVIRISL16C16B21_u16b";
--  constant ref_file: string  := "STIMULI\TEST8\comp.fl";

--**********************************************************************************************--  

  procedure write_to_file (myfilename: in string; value: in std_logic_vector);
  constant DEBUG : boolean := true;
end ccsds_shyloc_tb_parameters;

package body ccsds_shyloc_tb_parameters is 

  function str_2_lv (a : in string) return std_logic_vector is
    variable result: std_logic_vector (a'high downto 0);
  begin
    for i in a'high downto 1 loop
      if (a(i) = '1') then
        result(i-1) := '1';
      else
        result(i-1) := '0';
      end if;
    end loop;
    return result;
  end function str_2_lv;
  
  ----------------------------------- for writing files-----------------------------
  procedure write_to_file (myfilename: in string; value: in std_logic_vector) is
    variable  signed_data: signed (value'high downto 0);
    variable  integer_data, integer_data_tmp: integer := 0;
    variable outline: line;
    constant endoflinemark: character := character'val(10);
    file  myfile    : text;  --is out myfilename;
    file  myfile_in    : text; -- is in myfilename;
    variable status: FILE_OPEN_STATUS;
  begin
    --write(linenumber,value(real type),justified(side),field(width),digits(natural));
    file_open(myfile, myfilename, WRITE_MODE);
    file_open(status, myfile_in, myfilename, READ_MODE);
    if status /= NAME_ERROR then
      signed_data := signed (value);
      integer_data := to_integer (signed_data);
      -- position in eof to append
      while not endfile(myfile_in) loop
        readline(myfile_in, outline);
      end loop;
      file_close(myfile_in);
    end if;
    --write(outline, character'val(10), left, 1);
    write(outline, integer_data, left, 32);
    writeline(myfile, outline);
    file_close(myfile);
    --write(outline, endoflinemark, left, 1);
    --writeline(myfile, outline);
  end write_to_file;
end package body ccsds_shyloc_tb_parameters;