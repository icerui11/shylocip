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
-- Design unit  : Adder tree.
--
-- File name    : n_adders_top.vhd
--
-- Purpose      : Tree of HEIGHT_ADDERS levels of adders.
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
-- Instantiates : n_adders
--============================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use shyloc_123.adder_array.all;
library shyloc_utils;
use shyloc_utils.shyloc_functions.all;
library shyloc_123;
use shyloc_123.ccsds123_constants.all;  

--!@file #n_adders_top.vhd#
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Top entity of adder tree.
--!@details Creates an adder tree of HEIGHT_ADDERS height. Calculates the number of adders in each level of the tree and instantiates the adder components.
--!The results of each level are the operands of the next level. 
entity n_adders_top is 
  generic (HEIGHT_ADDERS: natural := 3;       --! Height of the adder tree; will generate a total of 2**(HEIGHT_ADDERS-1) adders
      RESET_TYPE: integer := 0;       --! Reset flavour (0: asynchronous; 1: synchronous).
      W_OP: natural := 36;          --! Bit width of the operands to be added.
      W_RES: natural := 36          --! Bit width of the result.
      );
                
  port (
    clk: in std_logic;                          --! Clock signal.
    rst_n: in std_logic;                        --! Reset signal. Active low.
    clear: in std_logic;                        --! Clear signal to set the output register to all zeros.
    op1: in dot_product_type (2**(HEIGHT_ADDERS-1)-1 downto 0);     --! N_ADDERS of operand 1
    op2: in dot_product_type (2**(HEIGHT_ADDERS-1)-1 downto 0);     --! N_ADDERS of operand 2
    result: out std_logic_vector(W_RES-1 downto 0)            --! N_ADDERS results
    );
    
end n_adders_top;

--!@brief Architecture definition of adder tree: instantiates the necessary components to make a tree of HEIGHT_ADDERS height.
architecture arch of n_adders_top is 

  --Total number of adders in thet tree.
  constant TOTAL_ADDERS: integer := indexes(HEIGHT_ADDERS-1);
  --Total number of results and operands in the entire tree. 
  signal result_local: dot_product_type (TOTAL_ADDERS- 1 downto 0); 
  signal op1_res: dot_product_type (TOTAL_ADDERS - 1 downto 0);   
  signal op2_res: dot_product_type (TOTAL_ADDERS - 1 downto 0);   
  
begin
  --Generation of the adder tree. 
  adders_tree: for j in HEIGHT_ADDERS-1 downto 0 generate
      assing_inputs: if j = HEIGHT_ADDERS-1 generate
        op1_res(indexes(j)-1 downto indexes(j-1)) <= op1;
        op2_res(indexes(j)-1 downto indexes(j-1)) <= op2;
      end generate;
  
      n_adders_gen : entity shyloc_123.n_adders(non_recursive)
        generic map (N_ADDERS => 2**j, W_OP =>  W_OP  , RESET_TYPE => RESET_TYPE,  W_RES =>  W_RES)
        port map( 
          clk => clk,
          rst_n => rst_n,
          clear => clear,
          op1 => op1_res(indexes(j)-1 downto indexes(j-1)), 
          op2 => op2_res (indexes(j)-1 downto indexes(j-1)), 
          result => result_local (indexes(j)-1 downto indexes(j-1))
          );
      -- reassign
      output_assign_1: if j /= 0 generate
        reassign: for i in indexes(j)-1 - indexes(j-1) downto 0 generate
          gen_op1: if modulo (i, 2) = 0 generate
            op1_res(i/2 + indexes(j-2)) <= result_local (i+indexes(j-1));
          end generate gen_op1;
        
          gen_op2: if modulo (i, 2) = 1 generate
            op2_res(i/2 + indexes(j-2)) <= result_local (i+indexes(j-1));
          end generate gen_op2;
        end generate reassign;
      end generate output_assign_1;
      
      output_assign_0: if j = 0 generate
        result <= result_local(0);
      end generate output_assign_0;
      
    end generate adders_tree;
end arch; --============================================================================