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
-- Design unit  : Shift module for local differences in BIP architecture
--
-- File name    : localdiff_shift.vhd
--
-- Purpose      : Shifts the localdiff vector in BIP architecture.
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
--============================================================================l


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
library shyloc_123; 
--use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;   

--!@file #localdiff_shift.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Shifts the localdiff vector in BIP architecture.

entity localdiff_shift is 
  generic(
    NBP: integer := 3;          --! Number of elements in the local differences and weights vectors
    W_LD: integer := 20;        --! Number of bits of each local difference elements
    W_ADDR_IN_IMAGE: integer := 16;   --! Bit width of coordinate z
    RESET_TYPE: integer         --! Reset flavour (0) asynchronous (1) synchronous
  );
  port (
    clk: in std_logic;                      --! Clock
    rst_n: in std_logic;                    --! Reset value (active low)
    en: in std_logic;                       --! Enable value
    z: in std_logic_vector(W_ADDR_IN_IMAGE-1 downto 0);     --! Opcode to know when to clear
    clear: in std_logic;                    --! Clear signal to set the output register to all zeros.
    config_image: in config_123_image;              --! Image metadata configuration values
    config_predictor: in config_123_predictor;          --! Predictor configuration values.
    ld : in std_logic_vector(W_LD-1 downto 0);          --! Local difference output (registered).  
    ld_vector: out ld_array_type(0 to NBP-1)          --! Array of local differences
  );
end localdiff_shift;


architecture arch of localdiff_shift is 

  signal ld_vector_reg: ld_array_type(0 to NBP-1);

begin
  ld_vector <= ld_vector_reg;

  process(clk, rst_n) 
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      ld_vector_reg <= (others => (others => '0'));
    elsif clk'event and clk = '1' then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        ld_vector_reg <= (others => (others => '0'));
      elsif (en = '1') then
        if (unsigned(z) = unsigned(config_image.Nz)-1) then
          for i in 0 to NBP-1 loop
            ld_vector_reg(i) <= (others => '0');
          end loop;
        else
          if unsigned(config_predictor.P) = 0 then
            ld_vector_reg(0) <= (others => '0');
          else
            ld_vector_reg(0) <= ld;
          end if;
          for i in 1 to NBP-1 loop
            if i < to_integer(unsigned(config_predictor.P)) then
              ld_vector_reg(i) <= ld_vector_reg(i-1);
            else
              ld_vector_reg(i) <= (others => '0');
            end if;
          end loop;
        end if;
      end if;
    end if;
  end process;
  
end arch;