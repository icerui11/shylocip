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
-- Design unit  : Array of adders
--
-- File name    : n_adders.vhd
--
-- Purpose      : Arry of N_ADDERS adders of two std_logic_vector values.
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
-- Instantiates : adder
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_123;
use shyloc_123.ccsds123_constants.all;   

--!@file #n_adders.vhd#
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Adder array. Instantiates N_ADDERS
entity n_adders is 
  generic (N_ADDERS: natural := 4;      --! Number of adder components in the array.
      W_OP: natural := 39;        --! Bit width of the operands to be added.
      RESET_TYPE: integer:= 0;      --! Reset flavour (0: asynchronous; 1: synchronous).
      W_RES: natural := 39        --! Bit width of the result.
      );
                
  port (
    clk: in std_logic;                    --! Clock signal.
    rst_n: in std_logic;                  --! Reset signal. Active low.
    clear: in std_logic;                  --! Clear signal to set the output register to all zeros.
    op1: in dot_product_type (N_ADDERS - 1 downto 0);   --! Array of N_ADDERS elements of operand 1.
    op2: in dot_product_type (N_ADDERS - 1 downto 0);   --! Array of N_ADDERS elements of operand 2.
    result: out dot_product_type (N_ADDERS- 1 downto 0)   --! Array of N_ADDERS elements of result values.
    );
    
end n_adders;

architecture non_recursive of n_adders is 
  signal result_local: dot_product_type (N_ADDERS- 1 downto 0); 

begin
  -----------------------------------------------------------------------------
  -- Output assignment
  -----------------------------------------------------------------------------
  result <= result_local;
  
  -----------------------------------------------------------------------------
  -- Generates N_ADDERS.
  -----------------------------------------------------------------------------
  n_adders_gen: for i in N_ADDERS-1 downto 0 generate
    adder : entity shyloc_123.adder(arch)
    generic map (W_OP =>  W_OP  ,  RESET_TYPE => RESET_TYPE, W_RES =>  W_RES)
    port map( 
      clk => clk,
      rst_n => rst_n,
      clear => clear, 
      op1 => op1(i)(W_OP-1 downto 0), 
      op2 => op2(i)(W_OP-1 downto 0), 
      result => result_local (i) (W_RES-1 downto 0)
      );
    end generate n_adders_gen;

end non_recursive; --============================================================================
