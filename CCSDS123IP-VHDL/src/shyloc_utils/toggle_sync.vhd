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
-- Design unit  : synchronizer module
--
-- File name    : synchronizer.vhd
--
-- Purpose      : It synchronizes an asynchronous input with the corresponding system clock.
--
-- Note         :
--
-- Library      : shyloc_utils
--
-- Author       :
--============================================================================

--!@file #synchronizer.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  It synchronizes an asynchronous input with the corresponding system clock.

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! synchronizer entity. It synchronizes an asynchronous input with the corresponding system clock.
entity synchronizer is 
  port(
    rst: in std_ulogic;       --! Reset signal.
    clk_a: in std_ulogic;     --! Clock signal for domain a.
    clk_b: in std_ulogic;     --! Clock signal for domain b.
    input_a: in std_ulogic;   --! Input signal in domain a.
    output_b: out std_ulogic  --! Output signal in domain b.
  );
end;

--! @brief Architecture toggle of synchronizer 
architecture toggle of synchronizer is
  -- clk domain a
  signal d1_a, q1_a: std_logic;
  -- clk domain b
  signal q1_b, q2_b, q3_b: std_logic;
  
begin
  mux1: d1_a <= not q1_a when input_a = '1' else q1_a;
  output: output_b <= q3_b xor q2_b;
  
  dffa: process(clk_a, rst)
  begin
    if rst = '0' then
      q1_a <= '0';
    elsif clk_a'event and clk_a = '1' then
      q1_a <= d1_a;
    end if;
  end process;
  
  dffb: process(clk_b, rst)
  begin
    if rst = '0' then
      q1_b <= '0';
      q2_b <= '0';
      q3_b <= '0';
    elsif clk_b'event and clk_b = '1' then
      q1_b <= q1_a;
      q2_b <= q1_b;
      q3_b <= q2_b;
    end if;
  end process;
end toggle;

--! @brief Architecture two_ff of synchronizer 
architecture two_ff of synchronizer is
  signal d1_a, q1_a, q1_b, q2_b: std_logic;
begin
  d1_a <= input_a;
  output_b <= q2_b;
  
  dffa: process(clk_a, rst)
  begin
    if rst = '0' then
      q1_a <= '0';
    elsif clk_a'event and clk_a = '1' then
      q1_a <= d1_a;
    end if;
  end process;

  
  dffb: process(clk_b, rst)
  begin
    if rst = '0' then
      q1_b <= '0';
      q2_b <= '0';
    elsif clk_b'event and clk_b = '1' then
      q1_b <= q1_a;
      q2_b <= q1_b;
    end if;
  end process;

end two_ff;
