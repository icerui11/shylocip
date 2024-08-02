

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
package ccsds123_parameters is

-- TEST: 60_test
--SYSTEM
  constant EN_RUNCFG: integer  := 1;
  constant RESET_TYPE : integer := 1;
  constant EDAC: integer  :=  0;
  constant PREDICTION_TYPE: integer := 3;
  constant ENCODING_TYPE: integer  := 0;
--AHB
--slave

  constant HSINDEX_123: integer := 1;
  constant HSCONFIGADDR_123: integer := 16#200#;
--master

  constant HSADDRMASK_123: integer := 16#FFF#;
  constant HMINDEX_123: integer := 1;
  constant HMAXBURST_123: integer := 16;
  constant ExtMemAddress_GEN: integer := 16#400#;

  constant Nx_GEN: integer := 1024;
  constant Ny_GEN: integer := 1024;
  constant Nz_GEN: integer := 2048;
  constant D_GEN: integer := 16;
  constant IS_SIGNED_GEN: integer := 0;
  constant ENDIANESS_GEN: integer := 1;

  constant DISABLE_HEADER_GEN: integer := 0;
--PREDICTOR
  constant P_MAX: integer := 6;
  constant PREDICTION_GEN: integer := 0;
  constant LOCAL_SUM_GEN: integer := 0;
  constant OMEGA_GEN: integer := 19;
  constant R_GEN: integer := 64;

  constant VMAX_GEN: integer := 9;
  constant VMIN_GEN: integer := -6;
  constant T_INC_GEN: integer := 11;
  constant WEIGHT_INIT_GEN: integer := 0;
  constant ENCODER_SELECTION_GEN: integer := 2;
  constant INIT_COUNT_E_GEN: integer := 8;
  constant ACC_INIT_TYPE_GEN: integer := 0;
  constant ACC_INIT_CONST_GEN: integer := 14;
  constant RESC_COUNT_SIZE_GEN: integer := 9;
  constant U_MAX_GEN: integer := 16;
  constant W_BUFFER_GEN: integer := 64;

  constant Q_GEN: integer := 16;
  -- Modified by AS: New generics for CWI --
  constant CWI_GEN: integer := 0;
  ---------------------------------

end ccsds123_parameters;