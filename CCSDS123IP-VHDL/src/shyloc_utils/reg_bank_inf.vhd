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
-- Design unit  : reg_bank module
--
-- File name    : reg_bank_inf.vhd
--
-- Purpose      : Register bank to store intermediate data
--
-- Note         :
--
-- Library      : shyloc_utils
--
-- Author       : Lucana Santos
--
-- Instantiates : 
--============================================================================

--!@file #reg_bank_inf.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Register bank controlled by one clock signal

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! reg_bank entity. Register bank to store intermediate data
entity reg_bank_inf is
  generic (RESET_TYPE: integer := 1;    --! Implement Asynchronous Reset (0) or Synchronous Reset (1)
       Cz: natural := 15;       --! Number of components of the vectors.
       W: natural := 16;        --! Bit width of the stored values.
       W_ADDRESS: natural := 32);   --! Bit width of the address signal. 
  port (
    -- System Interface
    clk: in std_logic;                    --! Clock signal.
    rst_n: in std_logic;                  --! Reset signal. Active low. 
    
    -- Control and data Interface
    clear: in std_logic;                  --! Clear signal.
    data_in: in std_logic_vector (W - 1 downto 0);      --! Input data to be stored.
    data_out: out std_logic_vector (W -1 downto 0);     --! Output read data.
    read_addr: in std_logic_vector (W_ADDRESS-1 downto 0);  --! Read address.
    write_addr: in std_logic_vector (W_ADDRESS-1 downto 0); --! Write address.
    we: in std_logic;                   --! Write enable. Active high.
    re: in std_logic                    --! Read enable. Active high. 
    );
      
end reg_bank_inf;

--! @brief Architecture of reg_bank 
architecture arch of reg_bank_inf is
  type array_type is array (0 to Cz-1) of std_logic_vector (data_in'high downto 0);
  signal bank: array_type;
begin

    process(clk)  
    begin
      if (clk'event and clk = '1') then
        if (we = '1') then
          bank(to_integer(unsigned(write_addr))) <= data_in;
        end if;
        if (re = '1') then
          data_out <= bank(to_integer(unsigned(read_addr)));
        end if;
      end if;
    end process;
end arch;

--! @brief Architecture of reg_bank considering reset signals
architecture arch_reset_flavour of reg_bank_inf is
  type array_type is array (0 to Cz-1) of std_logic_vector (data_in'high downto 0);
  signal bank: array_type;
begin

  process(clk, rst_n) 
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then 
      bank <= (others => (others => '0'));
      data_out <= (others =>'0');   
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        bank <= (others => (others => '0'));
        data_out <= (others =>'0');   
      else
        -- Same read and write addresses
        if (read_addr = write_addr) then
          if (re = '1' and we = '1') then
            data_out <= data_in;
            bank(to_integer(unsigned(write_addr))) <= data_in;
          elsif (re = '1') then  
            data_out <= bank(to_integer(unsigned(read_addr))); 
          elsif (we = '1') then
            bank(to_integer(unsigned(write_addr))) <= data_in;
          end if;
        -- Different read and write addresses
        else 
          if (re = '1') then
            data_out <= bank(to_integer(unsigned(read_addr))); 
          end if;
          if (we = '1') then 
            bank(to_integer(unsigned(write_addr))) <= data_in;
          end if;
        end if;
      end if;
    end if;
  end process;
end arch_reset_flavour;


--============================================================================--
-- Design unit  : reg_bank_2clk_inf module
--
-- File name    : reg_bank_2clk_inf.vhd
--
-- Purpose      : Register bank to store intermediate data with different clocks for reading and writing
--
-- Note         :
--
-- Library      : shyloc_utils
--
-- Author       :
--                Institute for Applied Microelectronics (IUMA)
--                University of Las Palmas de Gran Canaria
--                Campus Universitario de Tafira s/n
--                35017, Las Palmas de Gran Canaria
--                Canary Islands, Spain
--
-- Contact      : lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--
-- Instantiates : 
--============================================================================

--!@file #reg_bank_2clk_inf.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Register bank to store intermediate data with different clocks for reading and writing

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! reg_bank_2clk_inf entity. Register bank to store intermediate data
entity reg_bank_2clk_inf is
  generic (Cz: natural := 15;       --! Number of components of the vectors.
       W: natural := 16;        --! Bit width of the stored values.
       W_ADDRESS: natural := 4;   --! Bit width of the address signal. 
       RESET_TYPE: integer := 0);   --! Implement Asynchronous Reset (0) or Synchronous Reset (1)
  port (
      clkw: in std_logic;                   --! Clock signal.
      rstw_n: in std_logic;                 --! Reset signal. Active low.
      data_in: in std_logic_vector (W - 1 downto 0);      --! Input data to be stored.
      write_addr: in std_logic_vector (W_ADDRESS-1 downto 0); --! Write address.
      we: in std_logic;                   --! Write enable. Active high
      clearw: in std_logic;                 --! Clear signal.
      
      clkr: in std_logic;                   --! Clock signal.
      rstr_n: in std_logic;                 --! Reset signal. Active low. 
      data_out: out std_logic_vector (W -1 downto 0);     --! Output read data.
      read_addr: in std_logic_vector (W_ADDRESS-1 downto 0);  --! Read address.
      clearr: in std_logic;                 --! Clear signal.
      re: in std_logic                    --! Read enable. Active low. 
      );
      
end reg_bank_2clk_inf;

--! @brief Architecture of reg_bank_2clk_inf considering reset signals
architecture arch of reg_bank_2clk_inf is
  type array_type is array (0 to Cz-1) of std_logic_vector (data_in'high downto 0);
  signal bank: array_type;
begin

  -----------------
  --! Write process
  -----------------
  process(clkw) 
  begin
    if (clkw'event and clkw = '1') then
      if (we = '1') then 
        bank(to_integer(unsigned(write_addr))) <= data_in;
      end if;
    end if;
  end process;
  
  ----------------
  --! Read process
  ----------------
  process(clkr)
  begin
    if (clkr'event and clkr = '1') then
      if (re = '1') then
        data_out <= bank(to_integer(unsigned(read_addr))); 
      end if;
    end if;
  end process;

end arch;
