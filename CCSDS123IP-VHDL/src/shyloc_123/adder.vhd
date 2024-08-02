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
-- Design unit  : Single adder.
--
-- File name    : adders.vhd
--
-- Purpose      : Single adder of two std_logic_vector values.
--
-- Note         : 
--
-- Library      : 
--
-- Author       : Lucana Santos
--                Institute for Applied Microelectronics (IUMA)
--                University of Las Palmas de Gran Canaria
--                Campus Universitario de Tafira s/n
--          35017, Las Palmas de Gran Canaria
--                Canary Islands, Spain
--
-- Contact      : lsfalcon@iuma.ulpgc.es
--                
--
--============================================================================

-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library shyloc_123; use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;    

--!@file #adders.vhd#
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Basic adder component. Adds two std_logic_vector values. 
entity adder is 
  generic (W_OP: natural := 39;       --! Bit width of the operands we need to add
      RESET_TYPE: integer := 0;   --! Reset flavour (0: asynchronous; 1: synchronous).
       W_RES: natural := 39       --! Bit width of the result.
      );
                
  port (
    clk: in std_logic;                    --! Clock signal.
    rst_n: in std_logic;                  --! Reset signal. Active low.
    clear: in std_logic;                  --! Clear signal to set the output register to all zeros.
    op1: in std_logic_vector (W_OP - 1 downto 0);     --! Local differences value.
    op2: in std_logic_vector (W_OP-1 downto 0);       --! Weight value.
    result: out std_logic_vector (W_RES-1 downto 0)     --! Result of the multiply and accumulate operation (registered). 
    );
    
end adder;

--!@brief Architecture definition of basic adder
architecture arch of adder is
  signal acc_value, acc_value_next: signed(result'high downto 0);
  
begin
  -- Output assignment
  result <= std_logic_vector(acc_value);
  
  reg: process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      acc_value <= (others => '0');
    elsif (clk'event and clk='1') then 
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        acc_value <= (others => '0');
      else
        acc_value <= acc_value_next;
      end if;
    end if;
  end process;
  
  -- Combinational logic  
  comb: process(op1,op2)
    variable acc_1: signed (result'high downto 0);
    variable acc_2: signed (result'high downto 0);
    variable acc_result: signed (result'high downto 0);
    
  begin
    -- Accumulate result
    acc_1 := resize(signed (op1), result'length); 
    acc_2 := resize(signed (op2), result'length); 
    acc_result := acc_1 + acc_2;
    acc_value_next <= (acc_result);
  end process;  

end arch; --============================================================================