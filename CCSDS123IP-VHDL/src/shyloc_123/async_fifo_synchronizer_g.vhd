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
-- Design unit  : Asynchronous FIFO 2-ff synchronizer
--
-- File name    : async_fifo_synchronizer_g.vhd
--
-- Purpose      : Synchronizes the read and write pointers of the asynnchronous FIFO.
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
--
--============================================================================

--!@brief 2-ff synchronizer
library ieee;
use ieee.std_logic_1164.all;

--!@file #async_fifo_synchronizer_g.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Synchronizes the read and write pointers of the asynchronous FIFO.


entity async_fifo_synchronizer_g is
  generic(N: natural;           --! Bit width of in_async and out_sync.
      RESET_TYPE: integer);     --! Reset type: (0) asynchronous reset (1) synchronous reset
  port(
    clk: in std_logic;          --! Clock signal. 
    reset: in std_logic;        --! Reset signal (active low).
    clear: in std_logic;        --! Clear flag (synchronous).
    in_async: in std_logic_vector(N-1 downto 0);  --! Input logic vector to be adapted (from another clk domain).
    out_sync: out std_logic_vector(N-1 downto 0)  --! Logic vector adapted to clk.
  );
end async_fifo_synchronizer_g;

architecture two_ff_arch of async_fifo_synchronizer_g is 
  signal meta_reg, sync_reg: std_logic_vector(N-1 downto 0);
  signal meta_next, sync_next: std_logic_vector(N-1 downto 0);
  
begin
  --two registers
  process(clk, reset, clear)
  begin 
    if (reset = '0' and RESET_TYPE = 0) then
      meta_reg <= (others => '0');
      sync_reg <= (others => '0');
    elsif clear = '1' then
      meta_reg <= (others => '0');
      sync_reg <= (others => '0');
    elsif clk'event and clk = '1' then
      if (reset = '0' and RESET_TYPE = 1) then
        meta_reg <= (others => '0');
        sync_reg <= (others => '0');
      else
        meta_reg <= meta_next;
        sync_reg <= sync_next;
      end if;
    end if;
  end process;  

  --next state logic
  meta_next <= in_async;
  sync_next <= meta_reg;
  --output
  out_sync <= sync_reg;
end two_ff_arch; --============================================================================
  