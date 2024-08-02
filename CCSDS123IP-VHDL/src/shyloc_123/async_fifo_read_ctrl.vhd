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
-- Design unit  : Asynchronous FIFO read control
--
-- File name    : async_fifo_read_ctrl.vhd
--
-- Purpose      : Read control of an asynchronous FIFO
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

--!@file #fifo_read_ctrl.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief  Read control of an asynchronous FIFO


entity async_fifo_read_ctrl is
  generic(N: natural;         --! (Bitwidth + 1) of the write pointer.
      RESET_TYPE: integer);   --! Reset type: (0) asynchronous reset (1) synchronous reset
  port(
    clkr: in std_logic;               --! Read clock.
    resetr: in std_logic;             --! Read reset (active low).
    async_clrr: in std_logic;           --! Asynchronous clear (resets the pointer values).
    w_ptr_in: in std_logic_vector(N downto 0);    --! Write pointer value (gray, adapted to clkr).
    rd: in std_logic;               --! Read enable.
    empty: out std_logic;             --! Empty flag.
    r_ptr_out: out std_logic_vector(N downto 0);  --! Output read pointer (gray).
    r_addr: out std_logic_vector(N-1 downto 0)    --! Read address (binary).
  );
end async_fifo_read_ctrl;

architecture arch of async_fifo_read_ctrl is
  signal r_ptr_reg, r_ptr_next: std_logic_vector(N downto 0);
  signal gray1, bin, bin1: std_logic_vector(N downto 0);
  signal raddr_all: std_logic_vector (N-1 downto 0);
  signal raddr_all_binary: std_logic_vector(N-1 downto 0);
  signal waddr_msb, raddr_msb: std_logic;
  signal empty_flag: std_logic;
begin
  process(clkr, resetr, async_clrr)
  begin
    if (resetr = '0' and RESET_TYPE = 0) then
      r_ptr_reg <= (others => '0');
    elsif async_clrr = '1' then
      r_ptr_reg <= (others => '0');
    elsif (clkr'event and clkr = '1') then
      if (resetr = '0' and RESET_TYPE = 1) then
        r_ptr_reg <= (others => '0');
      else
        r_ptr_reg <= r_ptr_next;
      end if;
    end if;
  end process;
  
  --(N+1) bit gray counter
  bin <= r_ptr_reg xor ('0'&bin(N downto 1));
  bin1 <= std_logic_vector(unsigned(bin) + 1);
  gray1 <= bin1 xor ('0' & bin1(N downto 1));
  
  --update read pointer
  r_ptr_next <=  (others => '0') when async_clrr = '1' else gray1 when rd = '1' and empty_flag = '0' else r_ptr_reg;
  
  --N bit gray counter
  raddr_msb <= r_ptr_reg(N) xor r_ptr_reg(N-1);
  raddr_all <= raddr_msb& r_ptr_reg(N-2 downto 0);
  waddr_msb <= w_ptr_in(N) xor w_ptr_in (N-1);
  
  --check for FIFO empty
  empty_flag <= '1' 
        when w_ptr_in(N) = r_ptr_reg(N) and w_ptr_in(N-2 downto 0) = r_ptr_reg(N-2 downto 0) and 
        raddr_msb = waddr_msb else '0';
  
  r_addr <= raddr_all_binary;
  r_ptr_out <= r_ptr_reg;
  empty <= empty_flag;
  
    -- converting gray to binary 
    process(raddr_all,raddr_all_binary)
    begin
    -- Update depending on N value
    raddr_all_binary <= raddr_all xor ('0' & raddr_all_binary(N-1 downto 1));
    end process;  
end arch; --============================================================================
  
--============================================================================--
-- Design unit  : Asynchronous FIFO read control with almost empty flag
--
-- File name    : async_fifo_read_ctrl.vhd
--
-- Purpose      : Read control of an asynchronous FIFO with almost empty flag
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

entity async_fifo_read_ctrl_v2 is
  generic(N: natural;         --! (Bitwidth + 1) of the write pointer.
      RESET_TYPE: integer);    --! Reset type: (0) asynchronous reset (1) synchronous reset
  port(
    clkr: in std_logic;                --! Read clock.
    resetr: in std_logic;              --! Read reset (active low).
    async_clrr: in std_logic;            --! Asynchronous clear (resets the pointer values).
    w_ptr_in: in std_logic_vector(N downto 0);    --! Write pointer value (gray, adapted to clkr).
    rd: in std_logic;                --! Read enable.
    empty: out std_logic;              --! Empty flag.
    aempty: out std_logic;              --! almost empty flag.
    r_ptr_out: out std_logic_vector(N downto 0);  --! Output read pointer (gray).
    r_addr: out std_logic_vector(N-1 downto 0)    --! Read address (binary).
  );
end async_fifo_read_ctrl_v2;

architecture arch of async_fifo_read_ctrl_v2 is
  signal r_ptr_reg, r_ptr_next: std_logic_vector(N downto 0);
  signal gray1, bin, bin1, bin_w: std_logic_vector(N downto 0);
  signal raddr_all: std_logic_vector (N-1 downto 0);
  signal raddr_all_binary: std_logic_vector(N-1 downto 0);
  signal waddr_msb, raddr_msb: std_logic;
  signal empty_flag, aempty_flag: std_logic;
begin
  process(clkr, resetr, async_clrr)
  begin
    if (resetr = '0' and RESET_TYPE = 0) then
      r_ptr_reg <= (others => '0');
    elsif async_clrr = '1' then
      r_ptr_reg <= (others => '0');
    elsif (clkr'event and clkr = '1') then
      if (resetr = '0' and RESET_TYPE = 1) then
        r_ptr_reg <= (others => '0');
      else
        r_ptr_reg <= r_ptr_next;
      end if;
    end if;
  end process;
  
  --(N+1) bit gray counter
  bin <= r_ptr_reg xor ('0'&bin(N downto 1));
  bin1 <= std_logic_vector(unsigned(bin) + 1);
  gray1 <= bin1 xor ('0' & bin1(N downto 1));
  
  --update read pointer
  r_ptr_next <=  (others => '0') when async_clrr = '1' else gray1 when rd = '1' and empty_flag = '0' else r_ptr_reg;
  
  --N bit gray counter
  raddr_msb <= r_ptr_reg(N) xor r_ptr_reg(N-1);
  raddr_all <= raddr_msb& r_ptr_reg(N-2 downto 0);
  waddr_msb <= w_ptr_in(N) xor w_ptr_in (N-1);
  
  bin_w <= w_ptr_in xor ('0'&bin_w(N downto 1));
  
  --check for FIFO empty and almost empty
  empty_flag <= '1' 
        when w_ptr_in(N) = r_ptr_reg(N) and w_ptr_in(N-2 downto 0) = r_ptr_reg(N-2 downto 0) and 
        raddr_msb = waddr_msb else '0';
        
  aempty_flag <= '1' 
        when (bin_w = bin1) else '0';
  
  r_addr <= raddr_all_binary;
  r_ptr_out <= r_ptr_reg;
  empty <= empty_flag;
  aempty <= aempty_flag;
  
    -- converting gray to binary 
    process(raddr_all,raddr_all_binary)
    begin
    -- Update depending on N value
    raddr_all_binary <= raddr_all xor ('0' & raddr_all_binary(N-1 downto 1));
    end process;  
end arch; --============================================================================
  