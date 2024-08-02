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
-- Design unit  : Record FIFO in 2D
--
-- File name    : record_2d_fifo.vhd
--
-- Purpose      : This module contains FIFOs to store data between the local difference 
--          calculation and the rest of the predictor's operations. 
--
-- Note         : 
--
-- Library      : 
--
-- Author       :
--                Institute for Applied Microelectronics (IUMA)
--                University of Las Palmas de Gran Canaria
--                Campus Universitario de Tafira s/n
--          35017, Las Palmas de Gran Canaria
--                Canary Islands, Spain
--
-- Contact      : 
--                
-- Instantiates : shyloc_utils.fifop2
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library shyloc_123; 
use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;
library shyloc_utils;
--!@file #record_2d_fifo.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief This module contains FIFOs to store data between the local difference calculation and the rest of the predictor's operations. 
--! The goal is not to lose data if the storing and retrieving of local differences to external memory gets stalled.

entity record_2d_fifo is
    generic (
      NE : integer;       --! Number of elements stored in the FIFO
      RESET_TYPE: integer := 1; --! Reset flavour (0: asynchronous; 1: synchronous).
      W_ADDR : integer := 4;    --! Bit width of the address pointer. Determines number of elements as 2**W_ADDR
      EDAC: integer := 0;     --! (0) EDAC  disabled (1) or (3) enabled. 
      TECH : integer := 0     --! Parameter used to change technology; (0) uses inferred memories.
    );
  port(
      clk: in std_logic;                --! Clock
      rst_n: in std_logic;              --! Reset value (active low)
      clr : in std_logic;               --! Asynchronous clear.
      w_update: in std_logic;             --! Write update.
      r_update : in std_logic;            --! Read update.
      data_record_in: in ld_record_type;        --! Input data. Record type.
      data_record_out: out ld_record_type;      --! Output data. Record type.
      hfull: out std_logic;             --! Half full flag. 
      empty : out std_logic;              --! Empty flag. 
      full : out std_logic;             --! Full flag.
      afull : out std_logic;              --! Almost full flag.
      aempty : out std_logic;             --! Almost empty flag.
      edac_double_error: out std_logic        --! Signals that there was an EDAC double error.
  );
end record_2d_fifo;

architecture arch of record_2d_fifo is
  signal is_hfull:  std_logic;
  signal is_empty :  std_logic;
  signal is_full :  std_logic;
  signal is_afull :  std_logic;
  signal is_aempty :  std_logic;
  
  constant Cz : integer := data_record_in.ld_vector'length;
  constant W_LD0 : integer := data_record_in.ld_vector(0)'length;
  constant W_OPC_PREDICT: integer  := data_record_in.opcode_predict'length;
  constant W_S_PREDICT: integer := data_record_in.s_predict'length;
  constant W_LS_PREDICT: integer := data_record_in.ls_predict'length;
  constant W_Z_PREDICT: integer := data_record_in.z_predict'length;
  
  signal edac_double_error_vector, edac_double_error_vector_tmp: std_logic_vector (0 to 6);
begin
  ---------------------------------------------------------------------------
  -- Output assignments for flags
  ---------------------------------------------------------------------------
  hfull <= is_hfull;
  empty <= is_empty;
  full  <= is_full;
  afull <= is_afull;
  aempty <= is_aempty;
  
  ---------------------------------------------------------------------------
  -- Output assignments for EDAC
  ---------------------------------------------------------------------------
  edac_double_error_vector_tmp(0) <= '0';
  gen_edac_error: for j in 0 to 5 generate
    edac_double_error_vector_tmp(j+1) <= edac_double_error_vector_tmp(j) or edac_double_error_vector(j); 
  end generate gen_edac_error;
  edac_double_error <= edac_double_error_vector_tmp(6); 
  
  -- Generate Cz FIFOs for local differences values. 
  gen_ld_values: if Cz > 0 generate
  ---------------------------------------------------------------------------
  --! FIFO 2d for local differences vector
  ---------------------------------------------------------------------------
  fifo_0_2d_ld: entity shyloc_123.ld_2d_fifo(arch)
    generic map (
      Cz => Cz , --Full*3 +1 pero no me deja...
      W => W_LD0,
      NE => NE,
      W_ADDR => W_ADDR,
      RESET_TYPE => RESET_TYPE, 
      EDAC => 0, 
      TECH => TECH) 
    port map (
      clk => clk,
      rst_n => rst_n,
      clr => clr,
      w_update => w_update,
      r_update => r_update,
      data_vector_in => data_record_in.ld_vector, 
      data_vector_out => data_record_out.ld_vector, 
      edac_double_error => edac_double_error_vector(0)    
    );
  end generate gen_ld_values;


  --------------------------------------------------------------------------- 
  --! FIFO for opcode
  ---------------------------------------------------------------------------
  fifo_1_opcode: entity shyloc_utils.fifop2(arch)
  generic map (
    RESET_TYPE => RESET_TYPE, 
    W => W_OPC_PREDICT, 
    NE => NE,
    W_ADDR => W_ADDR, 
    EDAC => EDAC, 
    TECH => TECH) 
  port map (
    clk => clk,
    rst_n => rst_n,
    clr => clr,
    w_update => w_update,
    r_update => r_update,
    data_in => data_record_in.opcode_predict, 
    data_out => data_record_out.opcode_predict, 
    edac_double_error => edac_double_error_vector(1)  
    );
  
  ---------------------------------------------------------------------------
  --! FIFO for s_predict
  ---------------------------------------------------------------------------
  fifo_2_s_predict: entity shyloc_utils.fifop2(arch)
  generic map (
    RESET_TYPE => RESET_TYPE, 
    W => W_S_PREDICT, 
    NE => NE,
    W_ADDR => W_ADDR, 
    EDAC => EDAC,
    TECH => TECH) 
  port map (
    clk => clk,
    rst_n => rst_n,
    clr => clr,
    w_update => w_update,
    r_update => r_update,
    data_in => data_record_in.s_predict, 
    data_out => data_record_out.s_predict, 
    edac_double_error => edac_double_error_vector(2)  
  );
  
  ---------------------------------------------------------------------------
  --! FIFO for ls_predict
  ---------------------------------------------------------------------------
  fifo_3_ls_predict: entity shyloc_utils.fifop2(arch)
  generic map (
    RESET_TYPE => RESET_TYPE, 
    W => W_LS_PREDICT,
    NE => NE,
    W_ADDR => W_ADDR, 
    EDAC => EDAC, 
    TECH => TECH) 
  port map (
    clk => clk,
    rst_n => rst_n,
    clr => clr,
    w_update => w_update,
    r_update => r_update,
    data_in => data_record_in.ls_predict, 
    data_out => data_record_out.ls_predict, 
    hfull => is_hfull,
    empty => is_empty,
    full => is_full, 
    afull  => is_afull, 
    aempty => is_aempty,
    edac_double_error => edac_double_error_vector(3)  
  );
  
  ---------------------------------------------------------------------------
  --! FIFO for z
  ---------------------------------------------------------------------------
  fifo_4_z_predict: entity shyloc_utils.fifop2(arch)
  generic map (
    RESET_TYPE => RESET_TYPE, 
    W => W_Z_PREDICT,
    NE => NE,
    W_ADDR => W_ADDR, 
    EDAC => EDAC, 
    TECH => TECH) 
  port map (
    clk => clk,
    rst_n => rst_n,
    clr => clr,
    w_update => w_update,
    r_update => r_update,
    data_in => data_record_in.z_predict, 
    data_out => data_record_out.z_predict, 
    edac_double_error => edac_double_error_vector(4)  
  );
  
  ---------------------------------------------------------------------------
  -- FIFO for z
  ---------------------------------------------------------------------------
  fifo_5_t_predict: entity shyloc_utils.fifop2(arch)
  generic map (
    RESET_TYPE => RESET_TYPE, 
    W => W_T,
    NE => NE,
    W_ADDR => W_ADDR, 
    EDAC => EDAC, 
    TECH => TECH) 
  port map (
    clk => clk,
    rst_n => rst_n,
    clr => clr,
    w_update => w_update,
    r_update => r_update,
    data_in => data_record_in.t_predict, 
    data_out => data_record_out.t_predict, 
    edac_double_error => edac_double_error_vector(5)  
  );
end arch;
