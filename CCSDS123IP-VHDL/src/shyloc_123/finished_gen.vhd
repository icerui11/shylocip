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
-- Design unit  : Finished generation
--
-- File name    : finished_gen.vhd
--
-- Purpose      : Generates finished flag considering z value and opcode
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
library shyloc_123; 
--use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;    

--!@file #finished_gen.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Generates finished flag considering z value and opcode. Flag is generated CYCLES_MAP clock
--! cycles after enable is raised.

entity finished_gen is
  generic (
      CYCLES_MAP : integer := 2;          --! Cycles needed by the mapping module
      W_ADDR_IN_IMAGE : integer := 16;    --! Bit width of the coordinate z
      Nz : integer := 5;                  --! Number of bands
      RESET_TYPE: integer                 --! Reset flavour (0) asynchronous (1) synchronous
      );
  port (
    rst_n: in std_logic;                  --! Reset (active low)
    clk: in std_logic;                    --! Clock
    en: in std_logic;                     --! Enable
    clear : in std_logic;                 --! Clear (synchronous)
    config_image: in config_123_image;    --! Image configuration values
    opcode_mapped: in std_logic_vector (4 downto 0);    --! Opcode received by the mapping component
    z_mapped: in std_logic_vector (W_ADDR_IN_IMAGE -1 downto 0);  --! z coordinate received by the mapping component
    finished: out std_logic                 --! Finished flag (registered)
  );
end finished_gen;

architecture arch of finished_gen is
  signal finished_flag: std_logic_vector (0 to CYCLES_MAP-1);
begin
  -----------------------------------------------------------------------------
  -- Output assignments
  -----------------------------------------------------------------------------
  finished <= finished_flag (CYCLES_MAP-1);
  
  -----------------------------------------------------------------------------
  -- Sequential process
  -----------------------------------------------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      finished_flag <= (others => '0');
    elsif clk'event and clk = '1' then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        finished_flag <= (others => '0');
      else
        if en = '1' then
          if (unsigned(z_mapped) = unsigned(config_image.Nz)-1 and opcode_mapped = "10111") then
            finished_flag(0) <= '1';
          end if;
        end if;
        for i in 1 to CYCLES_MAP-1 loop
          finished_flag(i) <= finished_flag(i-1);
        end loop;
      end if;
    end if;
  end process;
end arch;