--============================================================================--
-- Copyright 2017 University of Las Palmas de Gran Canaria 
--
-- Institute for Applied Microelectronics (IUMA)
-- Campus Universitario de Tafira s/n
-- 35017, Las Palmas de Gran Canaria
-- Canary Islands, Spain
--
-- This code may be freely used, copied, modified, and redistributed
-- by the European Space Agency for the Agency's own requirements.
--============================================================================--
-- ESA IP-CORE LICENSE
--
-- This code is provided under the terms of the
-- ESA Licence (Agreement) on Synthesisable HDL Models,
-- which you have signed prior to receiving the code.
--
-- The code is provided "as is", there is no warranty that
-- the code is correct or suitable for any purpose,
-- neither implicit nor explicit. The code and the information in it
-- contained do not necessarily reflect the policy of the
-- European Space Agency or of <originator>.
--
-- No technical support is available from ESA for this IP core,
-- however, news on the IP will be posted on the web page:
-- http://www.esa.int/TEC/Microelectronics
--
-- Any feedback (bugs, improvements etc.) shall be reported to ESA
-- at E-Mail IpCoreRequest@esa.int
--============================================================================--
-- Design unit  : Package with constants derived from parameters of the CCSDS 123 IP core.
--
-- File name    : ccsds123_constants.vhd
--
-- Purpose      : Computes all the necessary constants to propagate to the CCSDS 123 modules. 
--           
--
-- Note         :
--
-- Library      : shyloc_utils
--
-- Author       :
--                Institute for Applied Microelectronics (IUMA)
--                University of Las Palmas de Gran Canaria
--                Campus Universitario de Tafira s/n
--                35017, Las Palmas de Gran Canaria
--                Canary Islands, Spain
--
-- Contact      : lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--
-- Instantiates : 
--============================================================================

--!@file #fifop2.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Computes all the necessary constants to propagate to the CCSDS 123 modules. 

library ieee;
use ieee.std_logic_1164.all;
library shyloc_utils;
use shyloc_utils.shyloc_functions.all;

library shyloc_123; 
use shyloc_123.ccsds123_parameters.all;

package ccsds123_constants is
  ---------------------------------------------------------------------------
  --! Number of bits used to represent coordinates z, y, x
  ---------------------------------------------------------------------------
  constant W_ADDR_IN_IMAGE: integer := 16;
  
  ---------------------------------------------------------------------------
  --! Determines if the external memory is accessed through AHB or dedicated
  --! interface. The current version only includes AHB, so this value
  --! is fixed to 1;
  ---------------------------------------------------------------------------
  constant AHB_MEM: integer :=  1; 
  ---------------------------------------------------------------------------
  --! Sub-frame interleaving depth. Used for BI order.
  --! This IP only accepts BIP (for which M = Nz) or BIL for which (M=1).
  ---------------------------------------------------------------------------
  --constant M: integer := 0; -- sub-frame interleaving depth  (not used)
  
  ---------------------------------------------------------------------------
  --! Number of bytes in the output buffer.
  ---------------------------------------------------------------------------
  constant B: integer := W_BUFFER_GEN/8; -- output word size
  
  ---------------------------------------------------------------------------
  --! Bit width of coordinate t
  ---------------------------------------------------------------------------
  constant W_T: integer := W_ADDR_IN_IMAGE*2; 
  
  ---------------------------------------------------------------------------
  --! Constants for FIFO CURR
  ---------------------------------------------------------------------------
  constant W : integer := D_GEN;
  constant NE_CURR: integer := 16;
  constant W_ADDR_CURR: integer := maximum(1, log2(NE_CURR));
  

  ---------------------------------------------------------------------------
  --! Constants for BIP FIFOs. Right now FIFOs are dimensioned using W_ADDR.
  --! NUmber of elements is left for future developments -->
  --! Using a FIFO that is not a power of 2 to save storage resources.
  --! In the current version all FIFOs are a power of 2. 
  ---------------------------------------------------------------------------
  constant NE_WEIGHT_UPDATE_BIP: integer := Nz_GEN;
  constant W_ADDR_WEIGHT_UPDATE_BIP: integer := log2(NE_WEIGHT_UPDATE_BIP);
  
  constant NE_TOP_LEFT_BIP: integer := Nz_GEN;
  constant W_ADDR_TOP_LEFT_BIP: integer := log2(NE_TOP_LEFT_BIP);
  
  constant NE_TOP_BIP: integer := Nz_GEN; 
  constant W_ADDR_TOP_BIP: integer := log2(Nz_GEN);
  
  constant NE_LEFT_BIP: integer := Nz_GEN; 
  constant W_ADDR_LEFT_BIP: integer := log2(Nz_GEN);
  
  constant NE_TOP_RIGHT_BIP: integer := Nz_GEN*Nx_GEN; 
  constant W_ADDR_TOP_RIGHT_BIP: integer := log2(NE_TOP_RIGHT_BIP);
  
  -- Difference to raise hfull flag in AHB FIFO.
  constant DIFFERENCE_AHB_BIP: integer := 5; --INCREASED IN ONE, FOUND PROBLEM WHEN IP IS SLOW CONSUMER
  -- The AHB FIFO shall allocate at least 2*DIFFERENCE_AHB_BIP elements.
  constant NE_AHB_FIFO_BIP : integer := maximum(2*DIFFERENCE_AHB_BIP, 16); --not used right now... (?)
  
  ---------------------------------------------------------------------------
  --! Constants for BSQ FIFOs. Right now FIFOs are dimensioned using W_ADDR.
  ---------------------------------------------------------------------------
  constant DIFFERENCE_AHB_BSQ: integer := 14;
  constant NE_TOP_RIGHT_BSQ: integer := (Nx_GEN); --in theory we had here Nx_GEN + 1
  constant W_ADDR_TOP_RIGHT_BSQ: integer := log2(NE_TOP_RIGHT_BSQ);
  constant NE_AHB_FIFO_BSQ : integer := 32;
  
  --Record FIFOs
  constant NE_RECORD_BSQ: integer := 16;
  constant W_ADDR_RECORD_BSQ: integer := 4; 

  constant NE_LD_BSQ : integer := P_MAX;
  constant W_ADDR_LD_BSQ: integer := log2(P_MAX);
  
  constant NE_WEI_BSQ : integer := P_MAX;
  constant W_ADDR_WEI_BSQ: integer := log2(P_MAX);

  
  ---------------------------------------------------------------------------
  --! Constants for BIL FIFOs. Right now FIFOs are dimensioned using W_ADDR.
  ---------------------------------------------------------------------------
  constant NE_TOP_RIGHT_BIL: integer := (Nx_GEN+1)*Nz_GEN;
  constant W_ADDR_TOP_RIGHT_BIL: integer := log2(NE_TOP_RIGHT_BIL);
  
  constant W_ADDR_WEIGHT_UPDATE_BIL : integer := log2(Nz_GEN);
  constant W_ADDR_DOT_TO_UPDATE_BIL: integer := 2;
  constant W_ADDR_CENTRAL_BIL: integer := log2(Nx_GEN);
  constant NE_RECORD_BIL: integer := 16;
  --There is a minimum size for this FIFO, which is the amount of cycles between reading
  --from the input FIFO and the raise of the hfull flag.
  --it takes 5 cycles: minimum elements in fifo= 5*2 = 10 elements (it is *2 because we are checking the hfull flag) 
  constant W_ADDR_RECORD_BIL: integer := 4; 
  
  --! Bit width of S_MAX value.
  constant W_SMAX : integer := D_GEN + 1;
  --! Derived from PREDICTION_GEN. (0) Reduced prediction (1) Full prediction.
  constant FULL: integer := getfull(PREDICTION_GEN);
  --! Bit width of the local sum signed values.
  constant W_LS: integer := D_GEN + 3;
  --! Bit width of the localdiff signed values.
  constant W_LD: integer := D_GEN + 4;
  --! Bit width of the signed weights .
  constant W_WEI: integer := OMEGA_GEN + 3;
  --! Cz = P_MAX if reduced prediction; Cz = 3 + P_MAX when full prediction is used.
  constant Cz: integer := FULL*3 + P_MAX;

  --constant W_ADDR_BANK : integer := maximum(1,log2(Cz)); -- register bank NOT USED
  --! Constant used to calculate the bit width of the dot product result. 
  constant W_D: integer := maximum(1, log2(Cz));
  --! Bit width of the dot product result. 
  constant W_DZ: integer := W_LD + W_WEI + W_D; -- es W_RESULT_MAC
  --! Bit width of the scaled predicted sample.
  constant W_SCALED: integer := R_GEN+2;  
  --! Minimum weight
  constant WE_MIN: integer := -2**(OMEGA_GEN+2); ---2^(OMEGA+2)
  --! Maximum weight
  constant WE_MAX: integer := 2**(OMEGA_GEN+2) -1;  
  --! Maximum possible Rho value
  --constant MAX_RO: integer := maximum(absolute(VMAX_GEN+D_GEN-OMEGA_GEN),absolute(VMIN_GEN+D_GEN-OMEGA_GEN)); 
  constant MAX_RO: integer := maximum(absolute(VMAX_GEN+D_GEN),absolute(VMIN_GEN+D_GEN)); 
  --! Bit width to represent RHO
  constant W_RO: integer := log2(MAX_RO)+1;
  --! Bit width of input sample (signed)
  constant W_S_SIGNED: integer := D_GEN +1;
  --! Bit width of the mapped prediction residual
  constant W_MAP: integer := D_GEN;
  
  ---------------------------------------------------------------------------
  --! Constants for FIFO input to sample-adaptive encoder
  ---------------------------------------------------------------------------
  constant W_CURR_SAMPLE: integer := D_GEN;
  constant NE_CURR_SAMPLE: integer := 16;
  constant W_ADDR_CURR_SAMPLE: integer := maximum(1, log2(NE_CURR_SAMPLE));
  ---------------------------------------------------------------------------
  --! Constants for sample-adaptive encoder
  ---------------------------------------------------------------------------
  -- Bit width of accumulator
  constant W_ACC: integer := 32; 
  -- Bit width of coutner.
  constant W_COUNT: integer := 32;
  -- Maximum bit width of a codeword.
  constant W_MAX_CDW: integer := U_MAX_GEN + D_GEN;
  -- Bit widths of value representing the number of valid bits in the output buffer.
  constant W_NBITS: integer := log2(W_BUFFER_GEN);
  

  ---------------------------------------------------------------------------
  --! Constants for header computation
  ---------------------------------------------------------------------------
  constant W_NBITS_HEAD_GEN : integer := 7;
  
  ---------------------------------------------------------------------------
  -- These constants are left commented for reference. They come from
  -- previous versions and are not used anymore. 
  ---------------------------------------------------------------------------
  --constant HEADER_SIZE: integer := 19; -- number of bytes in the header
  --constant HEADER_ADDR: integer := log2(HEADER_SIZE);
  --constant Nx_mod16: integer := modulo(Nx_GEN, 2**16);
  --constant Ny_mod16: integer := modulo(Ny_GEN, 2**16);
  --constant Nz_mod16: integer := modulo(Nz_GEN, 2**16);
  --constant DRANGE_mod4: integer := modulo(D_GEN, 2**4);
  --constant M_mod16: integer := modulo(M, 2**16);
  --constant B_mod3: integer := modulo (B, 2**3);
  --constant R_mod6: integer := modulo (R_GEN, 2**6);
  --constant U_MAX_mod5: integer := modulo (U_MAX_GEN, 2**5);
  --constant INIT_COUNT_E_mod3: integer := modulo(INIT_COUNT_E_GEN, 2**3);
  --constant W_S   : integer := W_S_SIGNED;
  --constant W_OP  : integer := 5;
  --constant N_SOP : integer := log2(HEIGHT_TREE); --maximum(2,P_MAX);
  --constant W_ADDR_SOP: integer := log2(N_SOP);
  
  -- Bit width of counter for prediction in BSQ. 
  constant W_COUNT_PRED: integer := maximum(2, log2(P_MAX)+1);
  
  ---------------------------------------------------------------------------
  --! Multiply & accumulate constants. Multipliers and adder tree.
  ---------------------------------------------------------------------------
  -- Number of multipliers
  constant N_RESULTS_MULT : integer := Cz; --6
  -- Number of adders. 1 adder for every 2 multipliers.
  constant N_ADDERS_STAGE_1: integer := ceil(Cz, 2); --3
  -- Number of adders is made a power of two, in order to be able to generate the tree.
  constant N_ADDERS_POW2: integer := 2**log2_floor(N_ADDERS_STAGE_1); --2**2 = 4 
  -- Number of multipliers is made a power of two.
  constant N_MULT_POW2: integer := N_ADDERS_POW2*2; --4*2 = 8
  -- Height of the tree.
  constant HEIGHT_TREE: integer := log2_floor (N_ADDERS_STAGE_1)+1; --log2(3) = 3

  ---------------------------------------------------------------------------
  --! Constants used for BIP. Used to calculate the number of cycles needed
  --! for the prediction. In order to delay the processing and ensure
  --! data dependencies in images with Nz < prediction cycles
  ---------------------------------------------------------------------------
  constant CYCLES_PRED: integer := 2;
  constant CYCLES_WEIGHT: integer := 2;
  -- Clock cycles between MAC and weight.
  constant CYCLES_MAC_WEIGHT: integer := HEIGHT_TREE + 1 + CYCLES_WEIGHT + CYCLES_PRED + 1; --+1 TO STORE THE VALUE
  -- Bit width of cycle counter.
  constant W_CYCLE_COUNT: integer := log2(CYCLES_MAC_WEIGHT);
  
  -- Number of elements in intermediate FIFO, from MAC to weight update
  constant NE_DOT_TO_UPDATE_BIP: integer := HEIGHT_TREE + 1 + CYCLES_PRED;
  constant W_ADDR_DOT_TO_UPDATE_BIP: integer := log2(NE_DOT_TO_UPDATE_BIP);
  
  -- Number of elements in fifo to store the directional local differences.
  constant NE_LD_DIR_BSQ : integer := HEIGHT_TREE + 1;
  constant W_ADDR_LD_DIR_BSQ: integer := log2(NE_LD_DIR_BSQ);
  
  -- Bypass generic.
  constant BYPASS_GEN: integer := 0;
  constant MAX_HEADER_SIZE : integer := 19 + ceil(19*Q_GEN, 8) + ceil(Nz_GEN,2);  -- number of bytes in header  
  constant W_MAX_HEADER_SIZE : integer := log2(MAX_HEADER_SIZE);
  
  --------------------------------------------------------------------------- 
  --! Bit widths of configuration values.
  ---------------------------------------------------------------------------
  constant W_Nx_GEN: integer := log2(Nx_GEN);
  constant W_Ny_GEN: integer := log2(Ny_GEN);
  constant W_Nz_GEN: integer := log2(Nz_GEN);
  constant W_D_GEN: integer := log2(D_GEN);
  constant W_P_GEN: integer := log2(P_MAX);
  constant W_W_BUFFER_GEN : integer := log2(W_BUFFER_GEN);
  constant W_OMEGA_GEN: integer := log2(OMEGA_GEN);
  constant W_R_GEN: integer := log2(R_GEN);
  constant W_VMAX_GEN: integer := log2(16);
  constant W_VMIN_GEN: integer := log2(16);
  constant W_TINC_GEN: integer := log2(T_INC_GEN);
  constant W_INIT_COUNT_E_GEN: integer := log2(INIT_COUNT_E_GEN);
  constant W_ACC_INIT_CONST_GEN: integer := log2(ACC_INIT_CONST_GEN);
  constant W_RESC_COUNT_SIZE_GEN: integer := log2(RESC_COUNT_SIZE_GEN);
  constant W_U_MAX_GEN: integer := log2(U_MAX_GEN);
  constant W_Q_GEN: integer := log2(Q_GEN);
  --  W_ExtMemAddress_GEN has a fixed length of 32 bits always, because of the AHB addressing scheme. 
  constant W_ExtMemAddress_GEN: integer:= 32;
  
  -- Bit width of counter for total number of samples.
  constant W_SAMPLE_COUNTER: integer := W_Nx_GEN + W_Ny_GEN + W_Nz_GEN;
  
  ---------------------------------------------------------------------------
  --! Maximum possible bit widths of configuration values.
  --! Used when checking if the selected configuration is correct.
  ---------------------------------------------------------------------------
  constant W_Nx_GEN_f: integer := 16;
  constant W_Ny_GEN_f: integer := 16;
  constant W_Nz_GEN_f: integer := 16;
  constant W_D_GEN_f: integer := 5;
  constant W_P_GEN_f: integer := 4;
  constant W_W_BUFFER_GEN_f: integer := 7;
  constant W_OMEGA_GEN_f: integer := 5;
  constant W_R_GEN_f: integer := 7;
  constant W_VMAX_GEN_f: integer := 5;
  constant W_VMIN_GEN_f: integer := 5;
  constant W_TINC_GEN_f: integer := 4;
  constant W_INIT_COUNT_E_GEN_f: integer := 4;
  constant W_ACC_INIT_CONST_GEN_f: integer := 4;
  constant W_RESC_COUNT_SIZE_GEN_f: integer := 4;
  constant W_U_MAX_GEN_f: integer := 6;
  constant W_Q_GEN_f: integer := 5;
  constant W_ExtMemAddress_GEN_f: integer:= 32;
  
  ---------------------------------------------------------------------------
  --! Constants for HEADER FIFOs in dispatcher module.
  ---------------------------------------------------------------------------
  constant OUTPUT_HEADER_FIFO_SIZE: integer := 8;
  constant W_ADDR_HEADER_OUTPUT_FIFO: integer := log2_floor(OUTPUT_HEADER_FIFO_SIZE);

  ---------------------------------------------------------------------------
  --! Constants for OUTPUT FIFOs in dispatcher module (sample-adaptive values or mapper)
  ---------------------------------------------------------------------------
  constant OUTPUT_FIFO_SIZE: integer := 16;
  constant W_ADDR_OUTPUT_FIFO: integer := log2_floor(OUTPUT_FIFO_SIZE); 
  
  -- Maximum possible Cz value. 
  -- Modified by AS: Cz assignment adjusted --
  constant Cz_type : integer := maximum(1, Cz);  --P_MAX+3;  --18;
  
  ---------------------------------------------------------------------------
  --! Array type.
  ---------------------------------------------------------------------------
  --! Local differences vector
  type ld_array_type is array (integer range <>) of std_logic_vector (W_LD-1 downto 0);
  --! Weight vector
  type wei_array_type is array (integer range <>) of std_logic_vector (W_WEI-1 downto 0);
  --! Weight table vector (not used for now).
  type weight_tab_type is array (0 to Cz_type-1) of std_logic_vector(Q_GEN-1 downto 0);
  --! Accumulator table vector.
  type acc_tab_type is array (0 to Nz_GEN-1) of std_logic_vector(3 downto 0);
  --! Vectors used inside multipliers and adders tree in BIP and BIL. 
  type dot_product_type is array (integer range <>) of std_logic_vector (W_DZ-1 downto 0);
  
  -- Weight table generics (not used, left for future developments)
  constant WEIGHT_TAB_GEN: weight_tab_type := (others => (others => '0'));
  -- Accumulator table generic for sample adaptive.
  constant ACC_TAB_GEN: acc_tab_type := (others => "0001");
  
  ---------------------------------------------------------------------------
  --! Record for values  that need to be stored between computation 
  --! of local differences and prediction. 
  ---------------------------------------------------------------------------
  type ld_record_type is 
    record 
      opcode_predict: std_logic_vector (4 downto 0);
      ld_vector: ld_array_type (0 to FULL*3);
      z_predict: std_logic_vector (W_ADDR_IN_IMAGE -1 downto 0);
      s_predict: std_logic_vector ((D_GEN+1)-1 downto 0);
      ls_predict: std_logic_vector(W_LS-1 downto 0);
      t_predict: std_logic_vector (W_T-1 downto 0);
    end record;
  
  ---------------------------------------------------------------------------
  --! Record for status of the IP core. 
  ---------------------------------------------------------------------------
  type ctrls is
    record
      AwaitingConfig: std_logic;
      Ready: std_logic;
      FIFO_Full: std_logic;
      EOP: std_logic;
      Finished: std_logic;
      Error: std_logic;
      ErrorCode: std_logic_vector(3 downto 0);
  end record; 
  
  ---------------------------------------------------------------------------
  --! Record for configuration values with maximum possible bit width
  --! Used to store the values when they come from AHB
  --! and before we check they are correct.
  ---------------------------------------------------------------------------
  type config_123_f is
    record
      ENABLE: std_logic_vector(0 downto 0);
      Nx: std_logic_vector (W_Nx_GEN_f-1 downto 0);
      Nz: std_logic_vector (W_Nz_GEN_f-1 downto 0);
      Ny: std_logic_vector (W_Ny_GEN_f-1 downto 0);
      IS_SIGNED: std_logic_vector(0 downto 0);
      ENDIANESS: std_logic_vector(0 downto 0);
      D: std_logic_vector(W_D_GEN_f-1 downto 0);
      DISABLE_HEADER: std_logic_vector(0 downto 0);
      --ENCODER_SELECTION: std_logic_vector(0 downto 0);
      W_BUFFER: std_logic_vector (W_W_BUFFER_GEN_f-1 downto 0);
      BYPASS: std_logic_vector(0 downto 0);
      P: std_logic_vector(3 downto 0);
      ENCODER_SELECTION: std_logic_vector(1 downto 0);
      PREDICTION: std_logic_vector(0 downto 0);
      LOCAL_SUM: std_logic_vector(0 downto 0);
      OMEGA: std_logic_vector(W_OMEGA_GEN_f-1 downto 0); 
      R: std_logic_vector(W_R_GEN_f-1 downto 0);
      VMAX: std_logic_vector(W_VMAX_GEN_f-1 downto 0);
      VMIN: std_logic_vector(W_VMIN_GEN_f-1 downto 0);
      TINC: std_logic_vector(W_TINC_GEN_f-1 downto 0);
      WEIGHT_INIT: std_logic_vector(0 downto 0);
      INIT_COUNT_E: std_logic_vector(W_INIT_COUNT_E_GEN_f-1 downto 0);
      ACC_INIT_TYPE: std_logic_vector(0 downto 0);
      ACC_INIT_CONST: std_logic_vector(W_ACC_INIT_CONST_GEN_f-1 downto 0);
      RESC_COUNT_SIZE: std_logic_vector(W_RESC_COUNT_SIZE_GEN_f-1 downto 0);
      U_MAX: std_logic_vector(W_U_MAX_GEN_f-1 downto 0);
      Q: std_logic_vector(W_Q_GEN_f-1 downto 0);
      -- Modified by AS: New parameter for CWI --
      WR: std_logic_vector(0 downto 0);
      ----------------------------------
      WEIGHT_TAB: weight_tab_type;
      ExtMemAddress: std_logic_vector(W_ExtMemAddress_GEN_f-1 downto 0);
    end record; 
  
  ---------------------------------------------------------------------------
  --! Record for configuration values with actual used bit width
  --! Used after we check that the configuration is correct
  --! and before broadcasting to the rest of the modules.
  ---------------------------------------------------------------------------
  type config_123 is
    record
      ENABLE: std_logic_vector(0 downto 0);
      Nx: std_logic_vector (W_Nx_GEN-1 downto 0);
      Nz: std_logic_vector (W_Nz_GEN-1 downto 0);
      Ny: std_logic_vector (W_Ny_GEN-1 downto 0);
      IS_SIGNED: std_logic_vector(0 downto 0);
      ENDIANESS: std_logic_vector(0 downto 0);
      D: std_logic_vector(W_D_GEN-1 downto 0);
      DISABLE_HEADER: std_logic_vector(0 downto 0);
      W_BUFFER: std_logic_vector (W_W_BUFFER_GEN-1 downto 0);
      BYPASS: std_logic_vector(0 downto 0);
      P: std_logic_vector(3 downto 0);
      ENCODER_SELECTION: std_logic_vector(1 downto 0);
      PREDICTION: std_logic_vector(0 downto 0);
      LOCAL_SUM: std_logic_vector(0 downto 0);
      OMEGA: std_logic_vector(W_OMEGA_GEN-1 downto 0); 
      R: std_logic_vector(W_R_GEN-1 downto 0);
      VMAX: std_logic_vector(W_VMAX_GEN-1 downto 0);
      VMIN: std_logic_vector(W_VMIN_GEN-1 downto 0);
      TINC: std_logic_vector(W_TINC_GEN-1 downto 0);
      WEIGHT_INIT: std_logic_vector(0 downto 0);
      INIT_COUNT_E: std_logic_vector(W_INIT_COUNT_E_GEN-1 downto 0);
      ACC_INIT_TYPE: std_logic_vector(0 downto 0);
      ACC_INIT_CONST: std_logic_vector(W_ACC_INIT_CONST_GEN-1 downto 0);
      RESC_COUNT_SIZE: std_logic_vector(W_RESC_COUNT_SIZE_GEN-1 downto 0);
      U_MAX: std_logic_vector(W_U_MAX_GEN-1 downto 0);
      Q: std_logic_vector(W_Q_GEN-1 downto 0);
      -- Modified by AS: New parameter for CWI --
      WR: std_logic_vector(0 downto 0);
      -----------------------------------
      WEIGHT_TAB: weight_tab_type;
      ExtMemAddress: std_logic_vector(W_ExtMemAddress_GEN-1 downto 0);
    end record; 
    
  ---------------------------------------------------------------------------
  --! Image metadata configuration
  ---------------------------------------------------------------------------
  type config_123_image is
    record
      Nx: std_logic_vector (W_Nx_GEN-1 downto 0);
      Nz: std_logic_vector (W_Nz_GEN-1 downto 0);
      Ny: std_logic_vector (W_Ny_GEN-1 downto 0);
      IS_SIGNED: std_logic_vector(0 downto 0);
      ENDIANESS: std_logic_vector(0 downto 0);
      D: std_logic_vector(W_D_GEN-1 downto 0);
      DISABLE_HEADER: std_logic_vector(0 downto 0);
      BYPASS: std_logic_vector(0 downto 0);
      W_BUFFER: std_logic_vector (W_W_BUFFER_GEN-1 downto 0);
      ENCODER_SELECTION: std_logic_vector(1 downto 0);
      xz_bip: std_logic_vector (W_Nx_GEN + W_Nz_GEN -1 downto 0);
      xy_bsq: std_logic_vector (W_Nx_GEN + W_Ny_GEN -1 downto 0);
      number_of_samples: std_logic_vector (W_Nx_GEN + W_Ny_GEN + W_Nz_GEN -1 downto 0);
    end record; 

  ---------------------------------------------------------------------------
  --! Predictor configuration
  ---------------------------------------------------------------------------   
  type config_123_predictor is
    record
      P: std_logic_vector(3 downto 0);
      PREDICTION: std_logic_vector(0 downto 0);
      LOCAL_SUM: std_logic_vector(0 downto 0);
      OMEGA: std_logic_vector(W_OMEGA_GEN-1 downto 0); 
      R: std_logic_vector(W_R_GEN-1 downto 0);
      VMAX: std_logic_vector(W_VMAX_GEN-1 downto 0);
      VMIN: std_logic_vector(W_VMIN_GEN-1 downto 0);
      TINC: std_logic_vector(W_TINC_GEN-1 downto 0);
      WEIGHT_INIT: std_logic_vector(0 downto 0);
      Q: std_logic_vector(W_Q_GEN-1 downto 0);
      -- Modified by AS: New parameter for CWI --
      WR: std_logic_vector(0 downto 0);
      ------------------------------------
      ExtMemAddress: std_logic_vector(W_ExtMemAddress_GEN-1 downto 0);
    end record; 
    
  ---------------------------------------------------------------------------
  --! Sample-adaptive encoder configuration
  ---------------------------------------------------------------------------   
  type config_123_sample is
    record
      INIT_COUNT_E: std_logic_vector(W_INIT_COUNT_E_GEN-1 downto 0);
      ACC_INIT_TYPE: std_logic_vector(0 downto 0);
      ACC_INIT_CONST: std_logic_vector(W_ACC_INIT_CONST_GEN-1 downto 0);
      RESC_COUNT_SIZE: std_logic_vector(W_RESC_COUNT_SIZE_GEN-1 downto 0);
      U_MAX: std_logic_vector(W_U_MAX_GEN-1 downto 0);
    end record; 
    
  ---------------------------------------------------------------------------
  --! Image metadata configuration, as read from AHB. With maximum bit widths.
  --------------------------------------------------------------------------- 
  type config_123_image_f is
    record
      Nx: std_logic_vector (W_Nx_GEN_f-1 downto 0);
      Nz: std_logic_vector (W_Nz_GEN_f-1 downto 0);
      Ny: std_logic_vector (W_Ny_GEN_f-1 downto 0);
      IS_SIGNED: std_logic_vector(0 downto 0);
      ENDIANESS: std_logic_vector(0 downto 0);
      D: std_logic_vector(W_D_GEN_f-1 downto 0);
      DISABLE_HEADER: std_logic_vector(0 downto 0);
      BYPASS: std_logic_vector(0 downto 0);
      W_BUFFER: std_logic_vector (W_W_BUFFER_GEN_f-1 downto 0);
      ENCODER_SELECTION: std_logic_vector(1 downto 0);
    end record; 
    
  ---------------------------------------------------------------------------
  --! Predictor configuration, as read from AHB. With maximum bit widths.
  ---------------------------------------------------------------------------   
  type config_123_predictor_f is
    record
      P: std_logic_vector(3 downto 0);
      PREDICTION: std_logic_vector(0 downto 0);
      LOCAL_SUM: std_logic_vector(0 downto 0);
      OMEGA: std_logic_vector(W_OMEGA_GEN_f-1 downto 0); 
      R: std_logic_vector(W_R_GEN_f-1 downto 0);
      VMAX: std_logic_vector(W_VMAX_GEN_f-1 downto 0);
      VMIN: std_logic_vector(W_VMIN_GEN_f-1 downto 0);
      TINC: std_logic_vector(W_TINC_GEN_f-1 downto 0);
      WEIGHT_INIT: std_logic_vector(0 downto 0);
      Q: std_logic_vector(W_Q_GEN_f-1 downto 0);
      -- Modified by AS: New parameter for CWI --
      WR: std_logic_vector(0 downto 0);
      ----------------------------------
      ExtMemAddress: std_logic_vector(W_ExtMemAddress_GEN_f-1 downto 0);
    end record; 
    
  ---------------------------------------------------------------------------
  --! Sample-adaptive encoder configuration, as read from AHB. With maximum bit widths.
  ---------------------------------------------------------------------------   
  type config_123_sample_f is
    record
      INIT_COUNT_E: std_logic_vector(W_INIT_COUNT_E_GEN_f-1 downto 0);
      ACC_INIT_TYPE: std_logic_vector(0 downto 0);
      ACC_INIT_CONST: std_logic_vector(W_ACC_INIT_CONST_GEN_f-1 downto 0);
      RESC_COUNT_SIZE: std_logic_vector(W_RESC_COUNT_SIZE_GEN_f-1 downto 0);
      U_MAX: std_logic_vector(W_U_MAX_GEN_f-1 downto 0);
    end record; 
    
  --------------------------------------------------------------------------- 
  --! Configuration values that need to be read by the AHB controller module.
  ---------------------------------------------------------------------------
  type config_123_ahbm is
    record
      config_valid: std_logic;
      P: std_logic_vector(3 downto 0);
      Nx: std_logic_vector (W_Nx_GEN-1 downto 0);
      Nz: std_logic_vector (W_Nz_GEN-1 downto 0);
      Ny: std_logic_vector (W_Ny_GEN-1 downto 0);
      ExtMemAddress: std_logic_vector(W_ExtMemAddress_GEN-1 downto 0);
    end record;
    
  ---------------------------------------------------------------------------
  --! AHB status values
  ---------------------------------------------------------------------------
  type ahbm_123_status is
    record
      ahb_idle: std_logic;
      ahb_error: std_logic;
      edac_double_error: std_logic;
      edac_single_error: std_logic;
    end record;
end ccsds123_constants;
