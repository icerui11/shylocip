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
-- Design unit  : Mutiplier
--
-- File name    : mult.vhd
--
-- Purpose      : Multiplies two std_logic_vectors
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
-- Instantiates : 
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--!@file #mult.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Calculates the multiplication of a local difference and a weight value. 
--! Result is given 1 clk after assertion of "en". 

entity mult is 
  generic (W_LD: natural := 20;       --! Bit width of the local differences (DRANGE+4)           
      W_WEI: natural := 16;     --! Bit width of the weight elements (OMEGA + 3)  
      RESET_TYPE: integer := 0;   --! Reset type
      W_PRODUCT: natural := 20+16);   --! Bit with of the result of the multiplication (W_LD + W_WEI
                
  port (
    clk: in std_logic;                    --! Clock signal.
    rst_n: in std_logic;                  --! Reset signal. Active low.
    en: in std_logic;                   --! Enable signal.
    clear: in std_logic;                  --! Clear signal to set the output register to all zeros.
    ld_data_in: in std_logic_vector (W_LD - 1 downto 0);  --! Local differences value.
    weight_data_in: in std_logic_vector (W_WEI-1 downto 0); --! Weight value.
    result: out std_logic_vector (W_PRODUCT-1 downto 0)   --! Result of the multiply and accumulate operation (registered). 
    );
    
end mult;

-----------------------------------------------------------------------------
-- This architecture assumes input samples are signed
-----------------------------------------------------------------------------

architecture arch of mult is
  signal product, product_next: signed(W_PRODUCT-1 downto 0);
begin
  -----------------------------------------------------------------------------
  -- Output assignment
  -----------------------------------------------------------------------------
  result <= std_logic_vector(product);
  
  -----------------------------------------------------------------------------
  -- Registers
  -----------------------------------------------------------------------------
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      product <=(others => '0');
    elsif (clk'event and clk='1') then 
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        product <=(others => '0');
      elsif (en = '1') then
        product <= product_next;
      end if;
    end if;
  end process;
  
  -----------------------------------------------------------------------------
  -- Combinational logic
  -----------------------------------------------------------------------------
  process(ld_data_in,weight_data_in)    
    variable prod_1: signed (ld_data_in'high downto 0);
    variable prod_2: signed (weight_data_in'high downto 0);
    variable product_result: signed (product'high downto 0);
    
  begin

    prod_1 := (signed(ld_data_in));
    prod_2 := (signed(weight_data_in));
    product_result := resize(prod_1*prod_2, product'length);
    product_next <= product_result;
  end process;  

end arch; 