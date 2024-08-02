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
-- Design unit  : Multiply and accumulate unit for dot product tree.
--
-- File name    : mult_acc_shyloc.vhd
--
-- Purpose      : Calculates the multiplication and accumulation of Cz local differences 
--        and Cz weights values (CCSDS 123.0-B-1; Section 4.7.1a).
--
-- Note         : 
--
-- Library      : shyloc_123
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
-- Instantiates : mult, n_adders_top
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_123; 
--use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;

library shyloc_utils;    
use shyloc_utils.shyloc_functions.all;

--!@file #mult_acc_shyloc.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Calculates the multiplication and accumulation of 
--! Cz local differences and weights vectors (CCSDS 123.0-B-1; Section 4.7.1a).
--!@details This module is thought to be part of the computation of the dot product needed for the predictor. 

entity mult_acc_shyloc is
  generic(
    Cz: integer := 6;           --! Number of elements in the local differences and weights vectors
    W_LD: integer := 20;        --! Number of bits of each local difference element
    W_WEI: integer := 16;       --! Number of bits of each weight vector element
    W_RES: integer := 36;       --! Number of bits of the result
    RESET_TYPE: integer := 1      --! Reset flavour (0: asynchronous; 1: synchronous).
  );
  port(
    clk: in std_logic;                --! Clock
    rst_n: in std_logic;              --! Reset value (active low)
    en: in std_logic;                 --! Enable value
    clear: in std_logic;              --! Clear signal to set the output register to all zeros.
    result: out std_logic_vector(W_RES-1 downto 0); --! Stores the result of the dot product operation.
    valid: out std_logic;             --! To validate the results for one clk
    ld_vector: in ld_array_type(0 to Cz-1);     --! Array of local differences
    wei_vector: in wei_array_type(0 to Cz-1)    --! Array of weight values
  );
end mult_acc_shyloc;


architecture arch of mult_acc_shyloc is
  
  constant N_RESULTS_MULT : integer := Cz; --6 --2
  constant N_ADDERS_STAGE_1: integer := ceil(Cz, 2); --3 --1 
  constant N_ADDERS_POW2: integer := 2**log2_floor(N_ADDERS_STAGE_1); --2**2 = 4 --2**0 = 1
  
  constant N_MULT_POW2: integer := N_ADDERS_POW2*2; --4*2 = 8 --1*2 = 2
  constant HEIGHT_TREE: integer := log2_floor(N_ADDERS_STAGE_1)+1; --log2(3) = 3 --log2(1) + 1 = 0 + 1 = 1 
  
  signal result_tree: std_logic_vector(W_RES-1 downto 0);
  
  signal multipliers_result: dot_product_type (0 to N_MULT_POW2-1); -- 0 to 8-1
  signal op1, op2: dot_product_type(2**(HEIGHT_TREE-1)-1 downto 0); --(2**(3-2)-1 downto 0) --2**2-1 downto 0 -- 4-1 downto 0 -- 3 downto 0
  
  signal din_valid: std_logic_vector (HEIGHT_TREE downto 0);
  signal dout_valid: std_logic_vector (HEIGHT_TREE downto 0);

  
begin
  ----------------------------------------------------------------------------- 
  -- Instantiate Cz multipliers
  ----------------------------------------------------------------------------- 
  multipliers: for j in 0 to Cz-1 generate -- 0 to 5
      mult: entity shyloc_123.mult(arch)
      generic map( W_LD => W_LD, W_WEI => W_WEI, RESET_TYPE  => RESET_TYPE, W_PRODUCT => W_RES)
      port map(
          clk => clk,
          rst_n  => rst_n, 
          en => en, 
          clear => clear, 
          ld_data_in => ld_vector(j), 
          weight_data_in => wei_vector(j), 
          result => multipliers_result(j)
      );
  end generate multipliers;
  
  ----------------------------------------------------------------------------- 
  -- Rest of multiplier results fill with zeros to feed power of two adders
  ----------------------------------------------------------------------------- 
  fill_zeros: for j in Cz to N_MULT_POW2-1 generate
    multipliers_result(j) <= (others => '0'); 
  end generate fill_zeros;
  
  ----------------------------------------------------------------------------- 
  -- Assign operators 2 by 2 for adder tree
  -----------------------------------------------------------------------------   
  reassign: for j in 0 to N_ADDERS_POW2-1 generate
      op1(j) <= multipliers_result(j*2);
      op2(j) <=  multipliers_result(j*2+1);
  end generate reassign;
  
  
  ----------------------------------------------------------------------------- 
  -- Generate valid bit: delay of HEIGHT_TREE+1 cycles
  ----------------------------------------------------------------------------- 
  sr: for j in 0 to HEIGHT_TREE generate
    assign_initial: if (j = 0) generate
      din_valid(0) <= en;
      din_valid(1) <= dout_valid(0);
    end generate assign_initial;
    ff1bit: entity shyloc_123.ff1bit(arch)
      generic map (RESET_TYPE => RESET_TYPE)
      port map(
        clk => clk, 
        rst_n => rst_n,
        clear => clear, 
        din => din_valid(j),
        dout => dout_valid(j)
      );
      
    reassign_output: if (j < HEIGHT_TREE and j > 0) generate
      din_valid(j+1) <= dout_valid(j);
    end generate reassign_output;
      
    assing_out_valid: if (j = HEIGHT_TREE) generate
      valid <= dout_valid(j);
    end generate assing_out_valid;
  end generate;
  
  ----------------------------------------------------------------------------- 
  -- Now generate adder tree of height HEIGHT_TREE
  -----------------------------------------------------------------------------   
  adder_tree: entity shyloc_123.n_adders_top(arch)
  generic map(HEIGHT_ADDERS => HEIGHT_TREE, W_OP => W_RES, RESET_TYPE  => RESET_TYPE, W_RES => W_RES)
  port map(
    clk => clk,
    rst_n => rst_n, 
    clear => clear,
    op1 => op1, 
    op2 => op2,
    result => result_tree
  );
  
  ----------------------------------------------------------------------------- 
  -- Output assignment
  ----------------------------------------------------------------------------- 
  result <= result_tree;
end arch;