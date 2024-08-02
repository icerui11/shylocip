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
-- Design unit  : fifop2_EDAC with EDAC module
--
-- File name    : fifop2_EDAC.vhd
--
-- Purpose      : Provides a FIFO memory element, includes EDAC.
--
-- Note         :
--
-- Library      : shyloc_utils
--
-- Author       : Lucana Santos
--
-- Instantiates : edac_core(EDAC_RTL(RTL))
--============================================================================

--!@file #fifop2_EDAC.vhd#
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

--! fifop2_EDAC entity. FIFO memory element. 
entity fifop2_EDAC is
  generic (
    RESET_TYPE  : integer := 1;     --! Reset type (Synchronous or asynchronous).
    W     : integer := 16;    --! Bit width of the input.
    NE      : integer := 16;    --! Number of elements of the FIFO.
    W_ADDR    : integer := 4;     --! Bit width of the address.
    TECH    : integer := 0      --! Parameter used to change technology; (0) uses inferred memories.  
    );    
    
  port (
    
    -- System Interface
    clk   : in std_logic;     --! Clock signal.
    rst_n : in std_logic;     --! Reset signal. Active low.
    
    -- Control Interface
    clr         : in std_logic;   --! Clear signal.
    w_update      : in std_logic;   --! Write request.
    r_update      : in std_logic;   --! Read request.
    hfull       : out std_logic;  --! Flag to indicate half full FIFO.
    empty       : out std_logic;  --! Flag to indicate empty FIFO.
    full        : out std_logic;  --! Flag to indicate full FIFO.
    afull       : out std_logic;  --! Flag to indicate almost full FIFO.
    aempty        : out std_logic;  --! Flag to indicate almost empty FIFO.
    edac_double_error : out std_logic;  --! Signals that there has been an EDAC double error (uncorrectable)
    -- Data Interface
    data_in   : in std_logic_vector(W-1 downto 0);  --! Data to store in the FIFO, supported bit widths are (4, 8, 16, 24, 32, 40, 48, 64).
    data_out  : out std_logic_vector(W-1 downto 0)  --! Read data from the FIFO.
    );
    
end fifop2_EDAC;

--! @brief Architecture of fifop2_EDAC  
architecture arch of fifop2_EDAC is
  function get_check_bits (a: in integer) return integer;
  function align_byte (a: integer) return integer;
  function get_edac_type (a: integer) return integer;
  function get_check_bits (a: in integer) return integer is
    variable check_bits : integer := 0;
  begin
    if a = 4 then
      check_bits := 4;
    elsif a > 4 then
      check_bits := 8;
    else
      --pragma translate_off
      assert false report "Unsupported bit width for EDAC cannot get check bits" severity failure;
      --pragma translate_on
      check_bits := 8;
    end if;
    return check_bits;
  end function;
  
  --! Change bit width of input samples so that they can be
  --! processed by the EDAC IP core.
  --! Supported bit widths are (4, 8, 16, 24, 32, 40, 48, 64).
  function align_byte (a: integer) return integer is
    variable W_BYTE: integer := 0;
  begin
    if (a <= 4) then
      W_BYTE := 4;
    elsif (a > 4) and (a <= 8) then
      W_BYTE := 8;
    elsif (a > 8) and (a <= 16) then
      W_BYTE := 16;
    elsif (a > 16) and (a <= 24) then
      W_BYTE := 24;
    elsif (a > 24) and (a <= 32) then
      W_BYTE := 32;
    elsif (a > 32) and (a <= 40) then
      W_BYTE := 40;
    elsif (a > 40) and (a <= 48) then
      W_BYTE := 48;
    elsif (a > 48) and (a <= 64) then
      W_BYTE := 64;
    else
      --pragma translate_off
      assert false report "Unsupported bit width for EDAC cannot align to byte" severity failure;
      --pragma translate_on
      W_BYTE := 64;
    end if;
    return W_BYTE;
  end function;
  
  function get_edac_type (a: integer) return integer is
    variable EDACTtype : integer := 0;
  begin
    case a is
      when 4 =>
        EDACTtype := 0;
      when 8 =>
        EDACTtype := 1;
      when 16 =>
        EDACTtype := 3;
      when 24 =>
        EDACTtype := 5;
      when 32 =>
        EDACTtype := 6;
      when 40 =>
        EDACTtype := 8;
      when 48 =>
        EDACTtype := 9;
      when 64 =>
        EDACTtype := 10;
      when others =>
        --pragma translate_off
        assert false report "Unsupported bit width for EDAC" severity failure;
        --pragma translate_on
        EDACTtype := 0;
    end case;
    return EDACTtype;
  end function;
  
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
  
  -- validates that data were read from registers bank
  signal valid_data_read : std_logic;
  
  constant W_BYTE : integer := align_byte (W); --Supported bit widths are (4, 8, 16, 24, 32, 40, 48, 64)
  constant EDACType : integer := get_edac_type (W_BYTE);
  constant CHECK_BITS : integer := get_check_bits (W_BYTE);
    
  signal data_in_edac: std_logic_vector (W_BYTE-1 downto 0);
  signal data_out_edac: std_logic_vector (W_BYTE-1 downto 0); 
  signal data_to_store_edac : std_logic_vector (W_BYTE + CHECK_BITS -1 downto 0);
  signal data_read_edac : std_logic_vector (W_BYTE-1 + CHECK_BITS downto 0);
  
  -- EDAC signals
   signal EDACDout:    std_logic_vector(0 to 63)     := (others => '0');        -- Output data word
   signal EDACPout:    std_logic_vector(0 to 7)      := (others => '0');        -- Output check bits
   signal EDACDin:     std_logic_vector(0 to 63)     := (others => '0');         -- Input data word
   signal EDACPin:     std_logic_vector(0 to 7)      := (others => '0');         -- Input check bits
   signal EDACCorr:    std_logic_vector(0 to 63)     := (others => '0');        -- Corrected data
   signal EDACsErr:    Std_ULogic := '0';                               -- Single error
   signal EDACdErr:    Std_ULogic := '0';                               -- Double error
   signal EDACuErr:    Std_ULogic := '0';                               -- Uncorrectable error
  
begin


  -- Wrong assigment of data_out -> data_out should be EDACCorr
  -- data_out <= data_read_edac (W-1 downto 0);
  -- proposed solution
  data_out <= EDACCorr(W_BYTE-W to W_BYTE-1);
  
  
  ---------------------------------------------------------
  -- Resize to align to possible inputs of the EDAC IP core
  ---------------------------------------------------------
  data_in_edac <= std_logic_vector(resize (unsigned(data_in), W_BYTE));
  
  ------------------
  --!@brief EDAC IP
  ------------------
  edac_core: entity shyloc_utils.EDAC_RTL(RTL)
    generic map(EDACType => EDACType)  -- EDAC type selection
    port map(
        DataOut => EDACDout,
        CheckOut => EDACPout,
        DataIn => EDACDin, 
        CheckIn => EDACPin, 
        DataCorr => EDACCorr, 
        SingleErr => EDACsErr, 
        DoubleErr => EDACdErr,
        MultipleErr => EDACuErr);                   -- Uncorrectable error
    
    EDACDout(0 to W_BYTE-1) <= data_in_edac;
    data_to_store_edac <=  EDACPout & data_in_edac;
    EDACDin(0 to W_BYTE-1) <= data_read_edac (W_BYTE-1 downto 0);
    EDACPin <= data_read_edac (W_BYTE-1 + CHECK_BITS downto W_BYTE);
    
    -- EDAC double error is not what matters here, we want to mark uncorrectable errors!! 
    edac_double_error <= EDACuErr when valid_data_read = '1' else '0';

  -------------------
  --! Valida data read to check EDAC double error
  -------------------
  process (clk, rst_n, clr)
  begin
    if (rst_n = '0') then
      valid_data_read <= '0';
    elsif (clr = '1') then
      valid_data_read <= '0';
    elsif (clk'event and clk = '1') then
      if (re_ram = '1') then
        valid_data_read <= '1';
      end if; 
    end if;
  end process;

  ------------------
  --!@brief reg_bank
  ------------------
  fifo_bank: entity shyloc_utils.reg_bank(arch)
      generic map 
        (Cz => 2**W_ADDR,
        W => W_BYTE + CHECK_BITS,
        W_ADDRESS => W_ADDR, 
        TECH => TECH)
      port map (
        clk => clk,
        rst_n => rst_n,
        clear => clr,
        data_in => data_to_store_edac,
        data_out => data_read_edac, 
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
      -- here pointer diff equals the number of elements used
      pointer_diff := signed('0'&w_pointer) - signed('0'&r_pointer);
    else
      -- here pointer diff equals the number of elements left
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
    
    
     
