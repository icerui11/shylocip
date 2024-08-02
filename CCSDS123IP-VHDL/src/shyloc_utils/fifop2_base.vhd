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
-- Design unit  : fifop2 module
--
-- File name    : fifop2_base.vhd
--
-- Purpose      : Provides a FIFO memory element. 
--
-- Note         :
--
-- Library      : shyloc_utils
--
-- Author       : 
--
-- Instantiates : fifo_bank (reg_bank)
--============================================================================

--!@file #fifop2_base.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Provides a FIFO memory element. 
--!@details The number of element in the FIFO is power of two.

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! Use shyloc_utils
library shyloc_utils;

--! fifop2_base entity. FIFO memory element. 
entity fifop2_base is
  generic (
    RESET_TYPE  : integer := 1;     --! Reset type (Synchronous or asynchronous).
    W     : integer := 16;    --! Bit width of the input.
    NE      : integer := 16;    --! Number of elements of the FIFO.
    W_ADDR    : integer := 4;     --! Bit width of the address.
    TECH    : integer := 0);    --! Parameter used to change technology; (0) uses inferred memories.
  port (
    
    -- System Interface
    clk   : in std_logic;     --! Clock signal.
    rst_n : in std_logic;     --! Reset signal. Active low.
    
    -- Control Interface
    clr     : in std_logic;   --! Clear signal.
    w_update  : in std_logic;   --! Write request.
    r_update  : in std_logic;   --! Read request.
    hfull   : out std_logic;  --! Flag to indicate half full FIFO.
    empty   : out std_logic;  --! Flag to indicate empty FIFO.
    full    : out std_logic;  --! Flag to indicate full FIFO.
    afull   : out std_logic;  --! Flag to indicate almost full FIFO.
    aempty    : out std_logic;  --! Flag to indicate almost empty FIFO.
    
    -- Data Interface
    data_in   : in std_logic_vector(W-1 downto 0);  --! Data to store in the FIFO.
    data_out  : out std_logic_vector(W-1 downto 0)  --! Read data from the FIFO.
    );
    
end fifop2_base;

--! @brief Architecture of fifop2_base  
architecture arch of fifop2_base is
  
  -- signals to control FIFO's capacity
  constant HALF   : integer := 2**W_ADDR/2;
  constant TOTAL    : integer := 2**(W_ADDR+1);
  signal is_empty   : std_logic;
  signal is_full    : std_logic;
  signal is_hfull   : std_logic;
  
  -- signals to perform read and write operations 
  signal r_pointer  : unsigned(W_ADDR downto 0);
  signal w_pointer  : unsigned(W_ADDR downto 0);
  signal we_ram   : std_logic;
  signal re_ram   : std_logic;
  signal en_rami    : std_logic;
  
begin

  ------------------
  --!@brief reg_bank
  ------------------
  fifo_bank: entity shyloc_utils.reg_bank(arch)
      generic map 
        (RESET_TYPE => RESET_TYPE,
        Cz => 2**W_ADDR,
        W => W,
        W_ADDRESS => W_ADDR, 
        TECH => TECH)
      port map (
        clk => clk,
        rst_n => rst_n,
        clear => clr,
        data_in => data_in,
        data_out => data_out, 
        read_addr => std_logic_vector(r_pointer(r_pointer'high - 1 downto 0)),
        write_addr => std_logic_vector(w_pointer(w_pointer'high - 1 downto 0)),
        we => we_ram,
        re => re_ram);
        
  ------------------
  --! Enable updates
  ------------------
  we_ram <= w_update and (not(is_full));
  re_ram <= r_update and (not(is_empty));
  
  en_rami <= re_ram or we_ram;
  
  -------------------
  --! Flag assignments
  -------------------
  empty <= is_empty;
  full <= is_full;
  hfull <= is_hfull;
  
  -------------------
  --! Pointers update
  -------------------
  process (clk, rst_n, clr)
  begin
    if (rst_n = '0') then
      r_pointer <= (others => '0');
      w_pointer <= (others => '0');
    elsif (clr = '1') then
      r_pointer <= (others => '0');
      w_pointer <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (re_ram = '1') then
        r_pointer <= r_pointer + 1;
      end if;
      if (we_ram = '1') then
        w_pointer <= w_pointer + 1; 
      end if;     
    end if;
  end process;
  
  ----------------
  --! Flags update
  ----------------
  process (r_pointer, w_pointer)
    variable pointer_diff: signed(W_ADDR+1 downto 0);
  begin   
    if (r_pointer(w_pointer'high-1 downto 0) = w_pointer(w_pointer'high-1 downto 0)) then 
      if (w_pointer(w_pointer'high) /= r_pointer(r_pointer'high)) then 
        is_full <= '1';
        is_empty <= '0';
      else
        is_full <= '0';
        is_empty <= '1';
      end if;
    else
      is_full <= '0';
      is_empty <= '0';
    end if;
    -- checking if FIFO is half full
    if signed('0'&w_pointer) >= signed('0'&r_pointer) then
      --here pointer diff equals the number of elements used
      pointer_diff := signed('0'&w_pointer) - signed('0'&r_pointer);
    else
      --here pointer diff equals the number of elements left
      pointer_diff := signed('0'&r_pointer)- signed('0'&w_pointer);
      pointer_diff := TOTAL - pointer_diff-1;
    end if;
    
    if (pointer_diff >= HALF) then
      is_hfull <= '1';
    else
      is_hfull <= '0';
    end if;
    -- end of checking if FIFO is half full
    if ((w_pointer(w_pointer'high-1 downto 0) = r_pointer(r_pointer'high-1 downto 0)-1)) then
      afull <= '1';
    else
      afull <= '0';
    end if;
      if (r_pointer(r_pointer'high-1 downto 0) = w_pointer(w_pointer'high-1 downto 0)-1) then
      aempty <= '1';
    else
      aempty <= '0';
    end if;
  end process;
      
end arch;
    
    
     
