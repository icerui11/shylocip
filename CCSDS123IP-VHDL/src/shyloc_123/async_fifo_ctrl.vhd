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
-- Design unit  : Asynchronous FIFO control
--
-- File name    : async_fifo_ctrl.vhd
--
-- Purpose      : Asynchronous FIFO control. Binds read control, write control 
--          and pointers synchronizers.
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
-- Instantiates : async_fifo_read_ctrl, async_fifo_write_ctrl, 
--          async_fifo_synchronizer_g
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library shyloc_123;

--!@file #async_fifo_ctrl.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email  lsfalcon@iuma.ulpgc.es
--!@brief  Write control of an asynchronous FIFO

entity async_fifo_ctrl is 
  generic (DEPTH: natural;      --! Bit width of the address pointers. 
       RESET_TYPE: integer;     --! Reset type: (0) asynchronous reset (1) synchronous reset
       DIFFERENCE: integer);    --! Determines the difference between read and flag pointers that will make hfull flag go to 1. 
  port (
    clkw: in std_logic;                 --! Write clock.
    resetw: in std_logic;               --! Write reset (active low).
    async_clr: in std_logic;              --! Asynchronous clear (resets the pointer values)
    wr: in std_logic;                 --! Write enable.
    full: out std_logic;                --! Full flag.
    hfull: out std_logic;                               --! Half full flag.
    w_addr: out std_logic_vector(DEPTH-1 downto 0);   --! Memory write address.
    clkr: in std_logic;                 --! Read clock.
    resetr: in std_logic;                               --! Read reset (active low).
    rd: in std_logic;                                   --! Read enable. 
    empty: out std_logic;                               --! Empty flag.
    r_addr: out std_logic_vector(DEPTH-1 downto 0)      --! Read address (binary).
  );                                                      
end async_fifo_ctrl;                                        
 
architecture arch of async_fifo_ctrl is
  signal r_ptr_in: std_logic_vector (DEPTH downto 0);
  signal r_ptr_out: std_logic_vector(DEPTH downto 0);
  signal w_ptr_in: std_logic_vector (DEPTH downto 0);
  signal w_ptr_out: std_logic_vector (DEPTH downto 0);
begin
  read_ctrl: entity shyloc_123.async_fifo_read_ctrl(arch)
    generic map (N => DEPTH, RESET_TYPE => RESET_TYPE)
    port map(clkr => clkr, resetr =>resetr, async_clrr => async_clr, rd => rd, 
        w_ptr_in => w_ptr_in, empty => empty, 
        r_ptr_out => r_ptr_out, r_addr => r_addr);

  write_ctrl: entity shyloc_123.async_fifo_write_ctrl(arch)
    generic map (N => DEPTH, RESET_TYPE => RESET_TYPE, DIFFERENCE => DIFFERENCE)
    port map(clkw => clkw, resetw =>resetw, async_clrw => async_clr, wr => wr, 
        r_ptr_in => r_ptr_in, full => full, hfull => hfull,
        w_ptr_out => w_ptr_out, w_addr => w_addr);
        
  sync_w_ptr: entity shyloc_123.async_fifo_synchronizer_g(two_ff_arch)
    generic map(N => DEPTH+1, RESET_TYPE => RESET_TYPE)
    port map (clk => clkr, reset => resetw, clear => async_clr, in_async => w_ptr_out,  out_sync => w_ptr_in);
    
  synch_r_ptr: entity shyloc_123.async_fifo_synchronizer_g(two_ff_arch)
    generic map(N => DEPTH+1, RESET_TYPE => RESET_TYPE)
    port map(clk => clkw, reset =>resetr,  clear => async_clr, in_async => r_ptr_out, out_sync => r_ptr_in);
    
end arch; --============================================================================
--============================================================================--
-- Design unit  : Asynchronous FIFO control with almost empty flag
--
-- File name    : async_fifo_ctrl.vhd
--
-- Purpose      : Asynchronous FIFO control. Binds read control, write control 
--          and pointers synchronizers. Includes almost empty flag
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
-- Instantiates : async_fifo_read_ctrl, async_fifo_write_ctrl, 
--          async_fifo_synchronizer_g
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library shyloc_123;

entity async_fifo_ctrl_v2 is 
  generic (DEPTH: natural;       --! Bit width of the address pointers. 
       RESET_TYPE: integer;     --! Reset type: (0) asynchronous reset (1) synchronous reset
       DIFFERENCE: integer);    --! Determines the difference between read and flag pointers that will make hfull flag go to 1. 
  port (
    clkw: in std_logic;                  --! Write clock.
    resetw: in std_logic;                --! Write reset (active low).
    async_clr: in std_logic;              --! Asynchronous clear (resets the pointer values)
    wr: in std_logic;                  --! Write enable.
    full: out std_logic;                --! Full flag.
    hfull: out std_logic;                               --! Half full flag.
    w_addr: out std_logic_vector(DEPTH-1 downto 0);    --! Memory write address.
    clkr: in std_logic;                  --! Read clock.
    resetr: in std_logic;                               --! Read reset (active low).
    rd: in std_logic;                                   --! Read enable. 
    empty: out std_logic;                               --! Empty flag.
    aempty: out std_logic;                --! almost empty flag.
    r_addr: out std_logic_vector(DEPTH-1 downto 0)      --! Read address (binary).
  );                                                      
end async_fifo_ctrl_v2;                                        
 
architecture arch of async_fifo_ctrl_v2 is
  signal r_ptr_in: std_logic_vector (DEPTH downto 0);
  signal r_ptr_out: std_logic_vector(DEPTH downto 0);
  signal w_ptr_in: std_logic_vector (DEPTH downto 0);
  signal w_ptr_out: std_logic_vector (DEPTH downto 0);
begin
  read_ctrl: entity shyloc_123.async_fifo_read_ctrl_v2(arch)
    generic map (N => DEPTH, RESET_TYPE => RESET_TYPE)
    port map(clkr => clkr, resetr =>resetr, async_clrr => async_clr, rd => rd, 
        w_ptr_in => w_ptr_in, empty => empty, aempty => aempty,
        r_ptr_out => r_ptr_out, r_addr => r_addr);

  write_ctrl: entity shyloc_123.async_fifo_write_ctrl(arch)
    generic map (N => DEPTH, RESET_TYPE => RESET_TYPE, DIFFERENCE => DIFFERENCE)
    port map(clkw => clkw, resetw =>resetw, async_clrw => async_clr, wr => wr, 
        r_ptr_in => r_ptr_in, full => full, hfull => hfull,
        w_ptr_out => w_ptr_out, w_addr => w_addr);
        
  sync_w_ptr: entity shyloc_123.async_fifo_synchronizer_g(two_ff_arch)
    generic map(N => DEPTH+1, RESET_TYPE => RESET_TYPE)
    port map (clk => clkr, reset => resetw, clear => async_clr, in_async => w_ptr_out,  out_sync => w_ptr_in);
    
  synch_r_ptr: entity shyloc_123.async_fifo_synchronizer_g(two_ff_arch)
    generic map(N => DEPTH+1, RESET_TYPE => RESET_TYPE)
    port map(clk => clkw, reset =>resetr,  clear => async_clr, in_async => r_ptr_out, out_sync => r_ptr_in);
    
end arch; --============================================================================