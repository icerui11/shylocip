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
-- Design unit  : fixed_shifter module
--
-- File name    : fixed_shifter.vhd
--
-- Purpose      : Performs shifts and rotations.
--
-- Note         :
--
-- Library      : shyloc_utils
--
-- Instantiates : 
--============================================================================

--!@file #fixed_shifter.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Performs shifts and rotations.
--!@details 
--! MODE 0 --> shift left
--! MODE 1 --> shift right
--! MODE 2 --> rotate left
--! MODE 3 --> rotate right
--! MODE 4 --> arithmetic shift right


--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;

--! fixed_shifter entity. Performs shifts and rotations.
entity fixed_shifter is
  generic (
    W   : natural := 16;          --! Bit width of the input samples.
    S_AMT : natural := 5;       --! Amount of bits to shift.
    S_MODE  : natural := 4);      --! Operating mode.
  port (
    -- Data Interface
    fixed_shifter_data_in : in std_logic_vector(W-1 downto 0);      --! Input data.
    fixed_shifter_data_out  : out std_logic_vector(W-1 downto 0);   --! Output data.
    
    -- Control Interface
    shft          : in std_logic                --! Enable output.
    );    
end fixed_shifter;

--! @brief Architecture toggle of fixed_shifter 
architecture arch of fixed_shifter is
  
  -- constants indicating the opertation
  constant L_SHIFT: natural := 0;
  constant R_SHIFT: natural := 1;
  constant L_ROTAT: natural := 2;
  constant R_ROTAT: natural := 3;
  constant ARITH_R_SHIFT: natural := 4;
  
  -- Intermediate data
  signal sh_tmp, zero: std_logic_vector (W-1 downto 0);

begin
  
  -----------------------------
  -- To fill bits if necessary
  -----------------------------
  zero <= (others => '0');
  
  --------------
  -- Left shift
  --------------
  ls_sh_gen:
  if S_MODE = L_SHIFT generate 
    sh_tmp <= fixed_shifter_data_in (W - S_AMT - 1 downto 0)&zero(W-1 downto W-S_AMT);
  end generate;
  
  -----------------
  -- Left rotation 
  -----------------
  l_rt_gen:
  if S_MODE = L_ROTAT generate
    sh_tmp <= fixed_shifter_data_in (W - S_AMT -1 downto 0)& fixed_shifter_data_in (W-1 downto W-S_AMT);
  end generate;
  
  ---------------
  -- Right shift 
  ---------------
  r_sh_gen:
  if S_MODE = R_SHIFT generate
    sh_tmp <= zero (S_AMT -1 downto 0) & fixed_shifter_data_in (W-1 downto S_AMT);
  end generate;
  
  ------------------
  -- Right rotation 
  ------------------
  r_rt_gen:
  if S_MODE = R_ROTAT generate
    sh_tmp <= fixed_shifter_data_in(S_AMT -1 downto 0)& fixed_shifter_data_in (W-1 downto S_AMT);
  end generate;
  
  --------------------------
  -- Arithmetic right shift 
  --------------------------
  arith_shift_gen:
  if S_MODE = ARITH_R_SHIFT generate
    sh_tmp (W-1 downto W - S_AMT) <= (others => fixed_shifter_data_in(fixed_shifter_data_in'high));
    sh_tmp (W - S_AMT -1 downto 0) <=  fixed_shifter_data_in (W-1 downto S_AMT);  
  end generate;
  
  --------------------
  -- Output assignment 
  --------------------
  fixed_shifter_data_out <= sh_tmp  when shft ='1' else fixed_shifter_data_in;
  
end arch;
