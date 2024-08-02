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
-- Design unit  : Localsum module
--
-- File name    : localsumv2.vhd
--
-- Purpose      : Computes the local sum. 
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
library shyloc_123; use shyloc_123.ccsds123_parameters.all; use shyloc_123.ccsds123_constants.all;    

--!@file #localsumv2.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Calculates the local sum for prediction (CCSDS 123.0-B-1, Section 4.4).
--!@details  This module preforms the local sum of the neighbouring samples, 
--! as described in the CCSDS 123.0-B-1 Standard, Section 4.4. 
--!@details Two different modes are available depending on the user defined parameter:
--!@deltails - Full prediction : uses four neighbouring samples.
--!@deltails - Reduced prediction : uses two neighbouring samples.


entity localsumv2 is
  generic (DRANGE: integer := 16;       --! Dynamic range of the input samples.
       LOCAL_SUM_MODE: integer := 0;    --! Selects if local sum is neighbour oriented (0) or column oriented (1).
       W_LS: integer := 19);        --! Bit width of the output local sum (DRANGE+3)
  port(
    clk: in std_logic;                    --! Clock signal.
    rst_n: in std_logic;                  --! Reset signal. Active low.
    sign: in std_logic;                   --! Input samples are signed (1) or unsigned (0).
    en: in std_logic;                   --! Enable signal.
    clear: in std_logic;                  --! Synchronous clear signal
    config_predictor: in config_123_predictor;        --! Predictor configuration values
    s_left: in std_logic_vector(DRANGE-1 downto 0);     --! Left neighbour of the current sample, s(x-1,y,z).
    s_top: in std_logic_vector(DRANGE-1 downto 0);      --! Top neighbour of the current sample,  s(x,y+1,z).
    s_top_left: in std_logic_vector(DRANGE-1 downto 0);   --! Top left neighbour of the current sample, s(x-1,y+1,z). Only needed for neighbour oriented mode.
    s_top_right: in std_logic_vector(DRANGE-1 downto 0);  --! Top right neighbour of the current sample, s(x+1,y+1,z). Only needed for neighbour oriented mode.
    opcode_ls: in std_logic_vector(4 downto 0);       --! Opcode to calculate the localsum
    ls : out std_logic_vector(W_LS-1 downto 0);       --! Local sum of the input samples (registered).
    opcode_ld: out std_logic_vector(4 downto 0);      --! Opcode to be passed to localdiff
    s_left_ld: out std_logic_vector(DRANGE-1 downto 0);   --! Left neighbour to be passed to localdiff
    s_top_ld: out std_logic_vector(DRANGE-1 downto 0);    --! Top neighbour to be passed to localdiff
    s_top_left_ld: out std_logic_vector(DRANGE-1 downto 0)  --! Top left neighbour to be passed to localdiff
  );
end localsumv2;

----------------------------------------------------------------------------- 
--!@brief Architecture definition
----------------------------------------------------------------------------- 
architecture arch of localsumv2 is
  signal opcode: std_logic_vector(3 downto 0);  
begin
     opcode <= opcode_ls (3 downto 0);
   
process (clk, rst_n)
  variable d1, d2, d3, d4: signed (W_LS-1 downto 0);
begin
  if (rst_n = '0' and RESET_TYPE = 0) then
    ls <= (others => '0');
    s_left_ld <= (others => '0');
    s_top_ld <= (others => '0');
    s_top_left_ld <= (others => '0');
    opcode_ld <= (others => '0');
  elsif (clk'event and clk = '1') then
    if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
      ls <= (others => '0');
      s_left_ld <= (others => '0');
      s_top_ld <= (others => '0');
      s_top_left_ld <= (others => '0');
      opcode_ld <= (others => '0');
    else
      if (en = '1') then
        -- Signed input
        if (sign = '1') then 
          d1 := resize (signed (s_left), W_LS);
          d2 := resize (signed (s_top), W_LS);
          d3 := resize (signed (s_top_left), W_LS);
          d4 := resize (signed (s_top_right), W_LS);
        -- Unsigned input
        else 
          d1 := resize (signed ('0'& s_left), W_LS);
          d2 := resize (signed ('0'& s_top), W_LS);
          d3 := resize (signed ('0'& s_top_left), W_LS);
          d4 := resize (signed ('0' & s_top_right), W_LS);  
        end if;
        -- Neighbor oriented local sum
        if (config_predictor.LOCAL_SUM = "0") then  
          if (opcode = "1111") then
            ls <= std_logic_vector(d1+d2+d3+d4);
          elsif (opcode = "0001") then
            ls <= std_logic_vector(d1 sll 2);
          elsif (opcode = "1010") then
            ls <= std_logic_vector ((d2 sll 1) + (d4 sll 1));
          elsif (opcode = "0111") then
            ls <= std_logic_vector (d1 + d3 + (d2 sll 1));
          else
            ls <= (others => '0');
          end if;
        -- Column oriented local sum
        else 
          if (opcode(1 downto 0) = "01") then
            ls <= std_logic_vector(d1 sll 2);
          elsif (opcode(1 downto 0) = "10" or opcode(1 downto 0) = "11") then
            ls <= std_logic_vector (d2 sll 2);
          else
            ls <= (others => '0');
          end if;
        end if;
        --Pass neighbours to localdiff
        opcode_ld <= opcode_ls;
        s_left_ld <= s_left;
        s_top_ld <= s_top;
        s_top_left_ld <= s_top_left;
      end if;
    end if;
  end if;
end process;
end arch;

        
        