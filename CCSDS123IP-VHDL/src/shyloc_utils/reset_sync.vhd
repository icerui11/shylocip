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
-- Design unit  : Reset synchronizer module
--
-- File name    : reset_sync.vhd
--
-- Purpose      : External reset synchronization.
--
-- Note         :
--
-- Library      : shyloc_utils
--
-- Author       : Lucana Santos 
--
--============================================================================

--!@file #reset_sync.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  External reset synchronization.

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! Reset synchronizer entity. It synchronizes an asynchronous input with the corresponding system clock.
entity reset_sync is 
  port(
    clk: in std_ulogic;     --! Clock signal. 
    reset_in: in std_ulogic;  --! Input reset signal.
    reset_out: out std_ulogic --! Output reset synchronized.
  );
end;

--! @brief Architecture two_ff of synchronizer 
architecture two_ff of reset_sync is
  signal d1_a, q1_a, q1_b, q2_b: std_logic;
begin
  d1_a <= reset_in;
  reset_out <= q2_b;
  
  dffa: process(clk)
  begin
    if clk'event and clk = '1' then
      q1_a <= d1_a;
    end if;
  end process;

  
  dffb: process(clk)
  begin
    if clk'event and clk = '1' then
      q1_b <= q1_a;
      q2_b <= q1_b;
    end if;
  end process;

end two_ff;
