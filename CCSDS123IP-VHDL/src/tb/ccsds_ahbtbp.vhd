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
library IEEE;
use IEEE.std_logic_1164.all;

library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;

use work.ahbtbp.all;

--library shyloc_123;
--use shyloc_123.config123_package.all;
		

package ccsds_ahbtbp is
--pragma translate_off

type config_word is array (integer range <>) of std_logic_vector(31 downto 0);

-----------------------------------------------------------------------------
-- AMBA AHB write access (Inc Burst) - IUMA
-----------------------------------------------------------------------------
procedure ahbwrite(
  constant address  : in  std_logic_vector(31 downto 0);
  constant data     : in  config_word;
  constant size     : in  std_logic_vector(1 downto 0);
  constant count    : in  integer;
  constant debug    : in  integer;
  signal   ctrl     : inout ahbtb_ctrl_type);
  
-----------------------------------------------------------------------------
-- AMBA AHB read access (Inc Burst) - IUMA
-----------------------------------------------------------------------------
procedure ahbread(
  constant address  : in  std_logic_vector(31 downto 0); -- Start address
  constant data     : in  config_word; -- Start data
  constant size     : in  std_logic_vector(1 downto 0);
  constant count    : in  integer;
  constant debug    : in  integer;
  signal   ctrl     : inout ahbtb_ctrl_type);

--pragma translate_on
end package;


package body ccsds_ahbtbp is
--pragma translate_off
-----------------------------------------------------------------------------
-- AMBA AHB write access (Inc Burst) - IUMA
-----------------------------------------------------------------------------
procedure ahbwrite(
  constant address  : in  std_logic_vector(31 downto 0);
  constant data     : in  config_word;
  constant size     : in  std_logic_vector(1 downto 0);
  constant count    : in  integer;
  constant debug    : in  integer;
  signal   ctrl     : inout ahbtb_ctrl_type) is
  variable vaddr    : std_logic_vector(31 downto 0);
  variable vdata    : std_logic_vector(31 downto 0);
  variable vhtrans  : std_logic_vector(1 downto 0);
  -- burst begins in 0
  variable index: integer := 0;
begin
  --ctrl.o <= ctrlo_nodrive;
  -- i could see which this index is depending on address and slave mask.
  -- but do I have that information here?
  index := 0;
  vaddr := address; vdata := data(index); vhtrans := "10";
  wait until ctrl.o.update = '1' and rising_edge(ctrl.o.clk);
  ctrl.i.ac.ctrl.use128 <= 0;
  ctrl.i.ac.ctrl.dbgl <= debug;
  ctrl.i.ac.hburst <= "000"; ctrl.i.ac.hsize <= '0' & size;
  ctrl.i.ac.hwrite <= '1'; ctrl.i.ac.hburst <= "001";
  ctrl.i.ac.hprot <= "1110";
  for i in 0 to count - 1 loop
    ctrl.i.ac.haddr <= vaddr; ctrl.i.ac.hdata <= vdata;
    ctrl.i.ac.htrans <= vhtrans; 
    wait until ctrl.o.update = '1' and rising_edge(ctrl.o.clk);
    vaddr := vaddr + x"4";
	index := index + 1;
	-- not sure why this function is written in a way that this is needed
	if (index = data'length) then index := 0; end if;
	vdata := data(index);
    vhtrans := "11";
  end loop;
  ctrl.i <= ctrli_idle;
end procedure ahbwrite;


-----------------------------------------------------------------------------
-- AMBA AHB read access (Inc Burst) - IUMA
-----------------------------------------------------------------------------
procedure ahbread(
  constant address  : in  std_logic_vector(31 downto 0);
  constant data     : in  config_word;
  constant size     : in  std_logic_vector(1 downto 0);
  constant count    : in  integer;
  constant debug    : in  integer;
  signal   ctrl     : inout ahbtb_ctrl_type) is
  variable vaddr    : std_logic_vector(31 downto 0);
  variable vdata    : std_logic_vector(31 downto 0);
  variable vhtrans  : std_logic_vector(1 downto 0);
  variable index : integer := 0;
begin
  --ctrl.o <= ctrlo_nodrive;
  index := 0;
  vaddr := address; vdata := data (index); vhtrans := "10";
  wait until ctrl.o.update = '1' and rising_edge(ctrl.o.clk);
  ctrl.i.ac.ctrl.use128 <= 0;
  ctrl.i.ac.ctrl.dbgl <= debug;
  ctrl.i.ac.hburst <= "000"; ctrl.i.ac.hsize <= '0' & size;
  ctrl.i.ac.hwrite <= '0'; ctrl.i.ac.hburst <= "001";
  ctrl.i.ac.hprot <= "1110";
  for i in 0 to count - 1 loop
    ctrl.i.ac.haddr <= vaddr; ctrl.i.ac.hdata <= vdata;
    ctrl.i.ac.htrans <= vhtrans; 
    wait until ctrl.o.update = '1' and rising_edge(ctrl.o.clk);
    vaddr := vaddr + x"4";
	index := index + 1;
	if (index = data'length) then index := 0; end if;
	vdata := data(index);
    vhtrans := "11";
  end loop;
  ctrl.i <= ctrli_idle;
end procedure ahbread;

--pragma translate_on
end package body ccsds_ahbtbp;