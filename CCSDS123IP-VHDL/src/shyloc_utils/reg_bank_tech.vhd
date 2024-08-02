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
--============================================================================
---------------------------------------------------------------------------------
-- Title        Register Bank Memory Wrapper
-- Project      SHyLoC
-- Company      Thales Alenia Space Spain
-------------------------------------------------------------------------------
--! @file       reg_bank_tech.vhd
--! @author     Ricardo Pinto  <ricardo.pinto@thalesaleniaspace.com>
--! @date       2017-02-24
-------------------------------------------------------------------------------
--! @brief      Wrapper for technology-specific memories
-------------------------------------------------------------------------------
-- Copyright (c) 2017 Thales Alenia Space Spain
-------------------------------------------------------------------------------
--! @b Platform     Linux
--! @b Standard     VHDL'93/02
--! @b Revisions
--! @verbatim
--! Date        Version Author Description
--! 2017-02-23  1.0      rp Created
--! @endverbatim
-------------------------------------------------------------------------------
--! @todo       
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! reg_bank entity. Register bank to store intermediate data
entity reg_bank_tech is
  generic (RESET_TYPE : integer := 1;    --! Implement Asynchronous Reset (0) or Synchronous Reset (1)
           Cz         : natural := 15;   --! Number of components of the vectors.
           W          : natural := 16;   --! Bit width of the stored values.
           W_ADDRESS  : natural := 32);  --! Bit width of the address signal. 
  port (
    --\/ System Interface ----------------
    clk        : in  std_logic;         --! Clock signal.
    rst_n      : in  std_logic;         --! Reset signal. Active low.
    --\/ Control and Data Interface ------
    clear      : in  std_logic;         --! Clear signal.
    data_in    : in  std_logic_vector (W-1 downto 0);  --! Input data to be stored.
    data_out   : out std_logic_vector (W-1 downto 0);  --! Output read data.
    read_addr  : in  std_logic_vector (W_ADDRESS-1 downto 0);  --! Read address.
    write_addr : in  std_logic_vector (W_ADDRESS-1 downto 0);  --! Write address.
    we         : in  std_logic;         --! Write enable. Active high.
    re         : in  std_logic          --! Read enable. Active high. 
    );

end reg_bank_tech;

architecture struct of reg_bank_tech is

begin  -- architecture struct

  -- Instantiate the appropriate memories/wrappers here

end architecture struct;


-------------------------------------------------------------------------------
-- Title        Register Bank Memory Wrapper, 2 Clock Domains
-- Project      SHyLoC
-- Company      Thales Alenia Space Spain
-------------------------------------------------------------------------------
--! @file       reg_bank_tech.vhd
--! @author     Ricardo Pinto  <ricardo.pinto@thalesaleniaspace.com>
--! @date       2017-02-24
-------------------------------------------------------------------------------
--! @brief      Wrapper for technology-specific memories with 2 Clock Domains
-------------------------------------------------------------------------------
-- Copyright (c) 2017 Thales Alenia Space Spain
-------------------------------------------------------------------------------
--! @b Platform     Linux
--! @b Standard     VHDL'93/02
--! @b Revisions
--! @verbatim
--! Date        Version Author Description
--! 2017-02-23  1.0     rp  Created
--! @endverbatim
-------------------------------------------------------------------------------
--! @todo       
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--! reg_bank entity. Register bank to store intermediate data
entity reg_bank_2clk_tech is
  generic (RESET_TYPE : integer := 1;    --! Implement Asynchronous Reset (0) or Synchronous Reset (1)
           Cz         : natural := 15;   --! Number of components of the vectors.
           W          : natural := 16;   --! Bit width of the stored values.
           W_ADDRESS  : natural := 32);  --! Bit width of the address signal. 
  port (
    clkw       : in  std_logic;         -- ! Clock signal.
    rstw_n     : in  std_logic;         -- ! Reset signal. Active low.
    data_in    : in  std_logic_vector (W - 1 downto 0);  -- ! Input data to be stored.
    write_addr : in  std_logic_vector (W_ADDRESS-1 downto 0);  -- ! Write address.
    we         : in  std_logic;         -- ! Write enable. Active high
    clearw     : in  std_logic;         -- ! Clear signal.
    clkr       : in  std_logic;         -- ! Clock signal.
    rstr_n     : in  std_logic;         -- ! Reset signal. Active low.
    data_out   : out std_logic_vector (W -1 downto 0);   -- ! Output read data.
    read_addr  : in  std_logic_vector (W_ADDRESS-1 downto 0);  -- ! Read address.
    clearr     : in  std_logic;         -- ! Clear signal.
    re         : in  std_logic);        -- ! Read enable. Active low.

end entity reg_bank_2clk_tech;

architecture struct of reg_bank_2clk_tech is

begin  -- architecture struc

  

end architecture struct;
