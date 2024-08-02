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
-- Design unit  : Asynchronous FIFO
--
-- File name    : async_fifo.vhd
--
-- Purpose      : Asynchronous FIFO with empty, full and hfull flags. 
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
-- Instantiates : async_fifo_ctrl, reg_bank_2clk
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_123;
library shyloc_utils;
use shyloc_utils.shyloc_functions.all;

--!@file #async_fifo.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email  lsfalcon@iuma.ulpgc.es
--!@brief  Asynchronous FIFO with empty, full and hfull flags. 

entity async_fifo is 
  generic(
    W: integer := 32;         --! Bit width of the data to be stored in the FIFO.
    NE: integer := 16;          --! Number of elements in the FIFO -> log2(NE) = DEPTH.
    DIFFERENCE: integer := 4;     --! Determines the difference between read and flag pointers that will make hfull flag go to 1.
    RESET_TYPE: integer := 0;            --! Reset type: (0) asynchronous reset (1) synchronous reset.
    TECH : integer := 0               --! Parameter used to change technology; (0) uses inferred memories.
  );
  port (
    clkw: in std_logic;                   --! Write clock.
    resetw: in std_logic;                                   --! Write reset (active low)
    wr: in std_logic;                                       --! Write enable.
    async_clr: in std_logic;                                --! Asynchronous clear (resets the pointer values).
    full: out std_logic;                                    --! Full flag.
    hfull: out std_logic;                                   --! Half full flag.
    data_in: in std_logic_vector (W-1 downto 0);            --! Data input.
    data_out: out std_logic_vector (W-1 downto 0);          --! Data output.
    clkr: in std_logic;                                     --! Read clock. 
    resetr: in std_logic;                                   --! Read reset (active low)
    rd: in std_logic;                                       --! Read enable. 
    empty: out std_logic                                    --! Empty flag.
  );
end async_fifo;

architecture arch of async_fifo is
  constant DEPTH: integer := log2(NE);
  signal w_addr: std_logic_vector(DEPTH-1 downto 0);
  signal r_addr: std_logic_vector(DEPTH-1 downto 0);
begin
  --!@brief Asynchronous FIFO control 
  fifo_ctrl: entity shyloc_123.async_fifo_ctrl(arch)
    generic map (
      DEPTH => DEPTH, 
      RESET_TYPE => RESET_TYPE,
      DIFFERENCE => DIFFERENCE
    )
    port map(
      clkw => clkw,
      resetw => resetw,
      wr => wr,
      async_clr => async_clr,
      full => full,
      hfull => hfull,
      w_addr => w_addr,
      clkr => clkr,
      resetr => resetr,
      rd => rd, 
      empty => empty,
      r_addr => r_addr
    );
  
  --!@brief Register bank to store the data
  mem: entity shyloc_utils.reg_bank_2clk(arch)
    generic map(
      Cz => 2**DEPTH, 
      W => W, 
      W_ADDRESS => DEPTH,
      RESET_TYPE => RESET_TYPE,
                TECH => TECH
    )
    port map(
      clkw  =>  clkw,
      clearw => async_clr, 
      rstw_n  => resetw,  
      data_in =>  data_in,  
      write_addr => w_addr, 
      we  =>  wr,   
      clkr  => clkr,
      clearr => async_clr,
      rstr_n  =>  resetr, 
      data_out => data_out,   
      read_addr =>  r_addr,
      re    =>  rd
    );

end arch; --============================================================================
  --============================================================================--
-- Design unit  : Asynchronous FIFO with almost empty flag
--
-- File name    : async_fifo.vhd
--
-- Purpose      : Asynchronous FIFO with empty, aempty, full and hfull flags. 
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
-- Instantiates : async_fifo_ctrl, reg_bank_2clk
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_123;
library shyloc_utils;
use shyloc_utils.shyloc_functions.all;

entity async_fifo_v2 is 
  generic(
    W: integer := 32;          --! Bit width of the data to be stored in the FIFO.
    NE: integer := 16;           --! Number of elements in the FIFO -> log2(NE) = DEPTH.
    DIFFERENCE: integer := 4;      --! Determines the difference between read and flag pointers that will make hfull flag go to 1.
    RESET_TYPE: integer := 0;            --! Reset type: (0) asynchronous reset (1) synchronous reset.
    TECH : integer := 0                --! Parameter used to change technology; (0) uses inferred memories.
  );
  port (
    clkw: in std_logic;                    --! Write clock.
    resetw: in std_logic;                                   --! Write reset (active low)
    wr: in std_logic;                                       --! Write enable.
    async_clr: in std_logic;                                --! Asynchronous clear (resets the pointer values).
    full: out std_logic;                                    --! Full flag.
    hfull: out std_logic;                                   --! Half full flag.
    data_in: in std_logic_vector (W-1 downto 0);            --! Data input.
    data_out: out std_logic_vector (W-1 downto 0);          --! Data output.
    clkr: in std_logic;                                     --! Read clock. 
    resetr: in std_logic;                                   --! Read reset (active low)
    rd: in std_logic;                                       --! Read enable. 
    empty: out std_logic;                                   --! Empty flag.
    aempty: out std_logic                                   --! Almost empty flag.
  );
end async_fifo_v2;

architecture arch of async_fifo_v2 is
  constant DEPTH: integer := log2(NE);
  signal w_addr: std_logic_vector(DEPTH-1 downto 0);
  signal r_addr: std_logic_vector(DEPTH-1 downto 0);
begin
  --!@brief Asynchronous FIFO control 
  fifo_ctrl_v2: entity shyloc_123.async_fifo_ctrl_v2(arch)
    generic map (
      DEPTH => DEPTH, 
      RESET_TYPE => RESET_TYPE,
      DIFFERENCE => DIFFERENCE
    )
    port map(
      clkw => clkw,
      resetw => resetw,
      wr => wr,
      async_clr => async_clr,
      full => full,
      hfull  => hfull,
      w_addr => w_addr,
      clkr => clkr,
      resetr => resetr,
      rd => rd, 
      empty => empty,
      aempty => aempty,
      r_addr => r_addr
    );
  
  --!@brief Register bank to store the data
  mem: entity shyloc_utils.reg_bank_2clk(arch)
    generic map(
      Cz => 2**DEPTH, 
      W => W, 
      W_ADDRESS => DEPTH,
      RESET_TYPE => RESET_TYPE,
      TECH => TECH
    )
    port map(
      clkw  =>  clkw,
      clearw => async_clr, 
      rstw_n  => resetw,  
      data_in  =>  data_in,   
      write_addr =>  w_addr,  
      we  =>  wr,    
      clkr  => clkr,
      clearr => async_clr,
      rstr_n  =>  resetr,  
      data_out =>  data_out,   
      read_addr  =>  r_addr,
      re    =>  rd
    );

end arch; --============================================================================
  
  