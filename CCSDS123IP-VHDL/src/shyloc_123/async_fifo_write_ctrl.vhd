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
-- Design unit  : Asynchronous FIFO write control
--
-- File name    : fifo_write_ctrl.vhd
--
-- Purpose      : Write control of an asynchronous FIFO
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--!@file #fifo_write_ctrl.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief  Write control of an asynchronous FIFO


--!@brief FIFO write control
entity async_fifo_write_ctrl is
  generic(N: natural;         --! (Bitwidth + 1) of the write pointer.
      RESET_TYPE: integer;        --! Reset type: (0) asynchronous reset (1) synchronous reset
      DIFFERENCE: integer);   --! Determines the difference between read and flag pointers that will make hfull flag go to 1. 
  port(
    clkw:       in std_logic;               --! Write clock.
    resetw:     in std_logic;                           --! Write reset (active low).
    async_clrw:   in std_logic;                           --! Asynchronous clear (resets the pointer values)
    r_ptr_in:     in std_logic_vector (N downto 0);       --! Read pointer value (gray, adapted to clkw).
    wr:       in std_logic;                           --! Write enable.
    full:       out std_logic;                          --! Full flag.
    hfull:      out std_logic;                          --! Half full flag. 
    w_ptr_out:    out std_logic_vector(N downto 0);       --! Write pointer (gray)
    w_addr:     out std_logic_vector(N-1 downto 0)    --! Memory write address (binary)
  );
end async_fifo_write_ctrl;

architecture arch of async_fifo_write_ctrl is
  signal w_ptr_reg, w_ptr_next: std_logic_vector (N downto 0);
  signal bin: std_logic_vector(N downto 0);
  signal gray1, bin1: std_logic_vector(N downto 0);
  signal bin_raddr: std_logic_vector (N downto 0);
  signal waddr_all: std_logic_vector(N-1 downto 0);
  signal waddr_all_binary: std_logic_vector(N-1 downto 0);
  signal waddr_msb, raddr_msb: std_logic;
  signal full_flag, hfull_flag: std_logic;
  signal bindiff: std_logic_vector(N downto 0);
  
begin
  process(clkw, resetw, async_clrw)
  begin
    if (resetw = '0' and RESET_TYPE = 0) then
      w_ptr_reg <= (others => '0');
    elsif (async_clrw = '1') then
      w_ptr_reg <= (others => '0');
    elsif clkw'event and clkw = '1' then
      if (resetw = '0' and RESET_TYPE = 1) then
        w_ptr_reg <= (others => '0');
      else
        w_ptr_reg <= w_ptr_next;
      end if;
    end if;
  end process;
  
  -- (N+1) bit Gray counter
  -- convert write pointer to binary and increment it by 1
  bin <= w_ptr_reg xor ('0'& bin(N downto 1));
  bin1 <= std_logic_vector(unsigned(bin) + 1);
  
  -- convert incremented value to gray
  gray1 <= bin1 xor ('0'& bin1(N downto 1));
  
  --update write pointer
  w_ptr_next <= (others => '0') when async_clrw = '1' else gray1 when wr = '1' and full_flag = '0' else w_ptr_reg;
  
  -- N-bit gray counter
  waddr_msb <= w_ptr_reg(N) xor w_ptr_reg(N-1);
  waddr_all <= waddr_msb & w_ptr_reg(N-2 downto 0);
  
  --check for FIFO full
  raddr_msb <= r_ptr_in(N) xor r_ptr_in(N-1);
  
  full_flag <= '1' when r_ptr_in(N) /= w_ptr_reg(N) and
        r_ptr_in(N-2 downto 0) = w_ptr_reg(N-2 downto 0) and raddr_msb = waddr_msb else '0';
        
  --check for FiFO half full
  
  -- convert synchronized read pointer to binary
  bin_raddr <= r_ptr_in xor ('0'& bin_raddr(N downto 1));
    
  -- add the desired number of positions to the converted write pointer 
  bindiff <= std_logic_vector(unsigned(bin) + DIFFERENCE);
  
  hfull_flag <= '1' when (unsigned(not bindiff(N) & bindiff(N-1 downto 0)) - unsigned(bin_raddr)) <= DIFFERENCE  
               else '0';  
  --output
  w_addr <= waddr_all_binary;
  w_ptr_out <= w_ptr_reg;
  full <= full_flag;
    hfull <= hfull_flag;  
  
  -- converting gray to binary 
    process(waddr_all,waddr_all_binary)
    begin
    -- Update depending on N value
  waddr_all_binary <= waddr_all xor ('0' & waddr_all_binary(N-1 downto 1));
    end process ;

end arch; --============================================================================