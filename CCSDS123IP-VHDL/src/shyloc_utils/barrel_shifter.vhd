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
-- Design unit  : barrel_shifter module
--
-- File name    : barrel_shifter.vhd
--
-- Purpose      : It can shift or rotate a data word by a specified number of bits  
--
-- Note         :
--
-- Library      : shyloc_utils
--
-- Author       : Lucana Santos
--
-- Instantiates : fixed_shifter (fixed_shifter)
--============================================================================

--!@file #barrel_shifter.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  It can shift a data word by a specified number of bits  
--!@details Operation mode:
--! MODE 0 --> shift left
--! MODE 1 --> shift right
--! MODE 2 --> rotate left
--! MODE 3 --> rotate right
--! MODE 4 --> arithmetic shift right


--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;

--! Use shyloc_utils library
library shyloc_utils;

--! barrel_shifter entity.  It can shift or rotate a data word by a specified number of bits  
entity barrel_shifter is
  generic(
    W   : natural := 20;    --! Bit width of the input data.
    S_MODE  : natural := 4;     --! Operation mode.
    STAGES  : natural := 4);    --! Number of stages.
  port(
    -- Data Interface
    barrel_data_in  : std_logic_vector (W-1 downto 0);    --! Input data.
    barrel_data_out : out std_logic_vector (W-1 downto 0);  --! Output data.
    
    -- Control Interface
    amt: in std_logic_vector (STAGES - 1 downto 0)      --! Amount of bits to shift.
  );
end barrel_shifter;

--! @brief Architecture of barrel_shifter 
architecture arch of barrel_shifter is
  
  type arr_type is array (STAGES downto 0) of std_logic_vector (W-1 downto 0);  
  signal p: arr_type;
  
  constant W_MIN: integer := 2**(STAGES-1);
  type arr_type_long is array (STAGES downto 0) of std_logic_vector (W_MIN-1 downto 0); 
  signal p_long: arr_type_long;
  signal input_long, output_long: std_logic_vector(W_MIN-1 downto 0);
begin
  
  
  -------------------------------------------------------------
  --! The word size is not going to be a problem for the stages
  -------------------------------------------------------------
  no_extension:
  if (W >= W_MIN) generate
    p(0) <= barrel_data_in;
    stage_gen:
    for s in 0 to (STAGES-1) generate 
      -----------------------------------------------------
      --!@brief fixed_shifter (one fixed shifter per stage)
      -----------------------------------------------------
      fixed_shifter: entity shyloc_utils.fixed_shifter(arch)
      generic map (W => W, S_AMT => 2**s, S_MODE => S_MODE)
      port map (fixed_shifter_data_in => p(s), shft => amt(s), fixed_shifter_data_out => p(s+1));
    end generate;
    barrel_data_out <= p(STAGES);
  end generate no_extension;
  
  -----------------------------------------------------------------------------------------------------------------
  --! The word size is going to be a problem for the stages (It is smaller than the needed size for all the stages)
  --! So we need to have an intermediate bigger word for the fixed_shifter results
  -----------------------------------------------------------------------------------------------------------------
  extension:
  if (W < W_MIN) generate
    input_long (W-1 downto 0) <= barrel_data_in;
    input_long(W_MIN-1 downto W) <= (others => '0');
    
    p_long(0) <= input_long;
    stage_gen:
    for s in 0 to (STAGES-1) generate 
      -----------------------------------------------------
      --!@brief fixed_shifter (one fixed shifter per stage)
      -----------------------------------------------------
      fixed_shifter: entity shyloc_utils.fixed_shifter(arch)
      generic map (W => W_MIN, S_AMT => 2**s, S_MODE => S_MODE)
      port map (fixed_shifter_data_in => p_long(s), shft => amt(s), fixed_shifter_data_out => p_long(s+1));
    end generate;
  
    barrel_data_out <= p_long(STAGES)(W-1 downto 0);
  end generate extension;
  
end arch;
    
