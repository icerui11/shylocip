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
-- Design unit  : Multiply and accumulate unit.
--
-- File name    : mult_acc2stagesv2.vhd
--
-- Purpose      : Calculates the multiplication and accumulation of 
--        an element in the local differences vector and the 
--        weight vector(CCSDS 123.0-B-1; Section 4.7.1a).
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
-- Instantiates : 
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--library shyloc_123; 
--use shyloc_123.ccsds123_parameters.all; 
--use shyloc_123.ccsds123_constants.all;    

--!@file #mult_acc2stages.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Calculates the multiplication and accumulation of 
--! an element in the local differences vector and the weight vector(CCSDS 123.0-B-1; Section 4.7.1a).
--!@details The result of this operation is used at the prediction stage. Specifically the multiplication 
--! and accumulation of all the elements in the local differences and weights vectors corresponds to dz. 
--! The multiplication and accumulation of a pair of local difference and weight values takes two clock cycles.

entity mult_acc2stagesv2 is 
  generic (W_LD: natural := 20;       --! Bit width of the local differences (DRANGE+4)           
       W_WEI: natural := 16;      --! Bit width of the weight elements (OMEGA + 3)
       W_RESULT_MAC: natural := 39; --! Bit with of the multiply and accumulate operation result ((W_LD + W_WEI)*log2(Cz))
       RESET_TYPE : integer := 0
       );   
                
  port (
    clk: in std_logic;                    --! Clock signal.
    rst_n: in std_logic;                  --! Reset signal. Active low.
    en: in std_logic;                   --! Enable signal.
    clear: in std_logic;                  --! Clear signal to set the output register to all zeros.
    ld_data_in: in std_logic_vector (W_LD - 1 downto 0);  --! Local differences value.
    weight_data_in: in std_logic_vector (W_WEI-1 downto 0); --! Weight value.
    result: out std_logic_vector (W_RESULT_MAC-1 downto 0)  --! Result of the multiply and accumulate operation (registered). 
    );
    
end mult_acc2stagesv2;


architecture arch of mult_acc2stagesv2 is

  constant W_PRODUCT: natural := W_LD + W_WEI;
  signal product, product_next: signed(W_PRODUCT-1 downto 0);
  signal acc_value, acc_value_next: signed(result'high downto 0);
  signal en_acc: std_logic;
  
begin
  -----------------------------------------------------------------------------
  -- Output assignment
  -----------------------------------------------------------------------------
  result <= std_logic_vector(acc_value);
  
  -----------------------------------------------------------------------------
  -- Registers
  ----------------------------------------------------------------------------- 
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      product <=(others => '0');
      acc_value <= (others => '0');
      en_acc <= '0';
    elsif (clk'event and clk='1') then 
      if ((rst_n = '0' and RESET_TYPE= 1)) then
        product <=(others => '0');
        acc_value <= (others => '0');
        en_acc <= '0';
      else
        en_acc <= en; 
        if (clear = '1') then
          product <=(others => '0');
          acc_value <= (others => '0');
        else
          if (en = '1') then
            product <= product_next;
          end if;
          if (en_acc = '1') then
            acc_value <= acc_value_next;
          end if;
        end if;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Combinational logic
  ----------------------------------------------------------------------------- 
  process(ld_data_in,weight_data_in, product, acc_value)
    variable acc_1: signed (result'high downto 0);
    variable acc_2: signed (result'high downto 0);
    variable acc_result: signed (result'high downto 0);
    
    variable prod_1: signed (ld_data_in'high downto 0);
    variable prod_2: signed (weight_data_in'high downto 0);
    variable product_result: signed (product'high downto 0);
    
  begin

    prod_1 := (signed(ld_data_in));
    prod_2 := (signed(weight_data_in));
    product_result := prod_1*prod_2;
    product_next <= product_result;
    
    -- Accumulate result
    acc_1 := signed (acc_value); 
    acc_2 := resize(signed (product), result'length); 
    acc_result := acc_1 + acc_2;
    acc_value_next <= (acc_result); 
  end process;  

end arch; 