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
--------------------------------------------------------------------------------
-- Company: IUMA, ULPGC
-- Author: Lucana Santos
-- e-mail: lsfalcon@iuma.ulpgc.es
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library shyloc_123; use shyloc_123.ccsds123_parameters.all; use shyloc_123.ccsds123_constants.all;    

--!@file #create_cdwv2.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Counter and accumulator update for the entropy coding stage (CCSDS 123.0-B-1; Section 5.4.3.2.2.1).
--!@details When the signal en is enabled, the counter and accumulator are updated based on the prediction 
--! residual of the previous sample (with coordinates (t-1, z)) and the current counter and accumulator values. 
--! For t = 1, the accumulator and counter are set to their initial values, according to the specifications 
--! in Section 5.4.3.2.2 and 5.4.3.2.3

entity create_cdwv2 is
  generic (
      W_ACC: integer := 23;         --! Maximum possible bit width of the entropy coder accumulator.
      W_COUNT: integer := 7;          --! Maximum possible bit width of the entropy coder counter.
      DRANGE: integer := 16;          --! Dynamic range of the input samples.
      W_MAX_CDW: integer := 32;         --! Maximum possible bit width of the generated codewords. (DRANGE+U_MAX).
      W_MAP: integer := 16;         --! Dynamic range of the input samples.
      U_MAX: integer := 32;           --! Unary length limit.
      W_NBITS: integer := 6;          --! Bit width of the signal which represents the number of bits of each codeword. log2(W_BUFFER).
      W_T: integer := 32);          --! Bit width of signal t. 
  port(
    clk: in std_logic;                    --! Clock signal.
    rst_n: in std_logic;                  --! Reset signal. Active low.
    en: in std_logic;                   --! Enable signal.
    clear : in std_logic;                 --! Clear signal.
    config_sample: in config_123_sample;          --! Sample encoding relative configuration.
    config_image: in config_123_image;            --! Image relative configuration.
    t: in std_logic_vector (W_T-1 downto 0);        --! Coordinate t = x + Nx*y.
    acc: in std_logic_vector(W_ACC-1 downto 0);       --! Entropy coder accumulator.
    count: in std_logic_vector (W_COUNT - 1 downto 0);    --! Entropy coder counter. 
    mapped: in std_logic_vector(W_MAP-1 downto 0);      --! Mapped prediction residual.
    n_bits: out std_logic_vector (W_NBITS-1 downto 0);    --! Number of bits of the codeword.
    codeword: out std_logic_vector (W_BUFFER_GEN-1 downto 0)  --! Output codeword.
  );
end create_cdwv2;

architecture arch of create_cdwv2 is

  constant N_K: integer := DRANGE-2;
  constant W_SHIFTED: integer := N_K + W_ACC;  -- W_ACC is by definition > W_COUNT
  signal cdw_tmp: std_logic_vector (codeword'high downto 0);
  type arr_type is array (N_K downto 0) of std_logic_vector(W_SHIFTED-1 downto 0);

  -- Registers for second pipeline stage
  signal mapped_reg: std_logic_vector(W_MAP-1 downto 0);  
  signal t_reg: std_logic_vector (W_T-1 downto 0);
  signal ones_cmb, ones_reg: std_logic_vector(N_K downto 0);
  signal k_cmb, k_reg: signed (W_D_GEN downto 0);
  
  -- Stores the sign of the result of the subtraction
  signal tmp, tmp_reg: std_logic_vector (acc'high+2 downto 0);
  signal n_bits_next: std_logic_vector (W_NBITS-1 downto 0);
begin

  -- Output register
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      codeword <= (others => '0');
      n_bits   <= (others => '0');
      mapped_reg <=  (others => '0');
      t_reg <=  (others => '0');
      k_reg <= (others => '0');
      ones_reg <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        codeword <= (others => '0');
        n_bits   <= (others => '0');
        mapped_reg <=  (others => '0');
        t_reg <=  (others => '0');
        k_reg <= (others => '0');
        ones_reg <= (others => '0');
      else
        
        codeword <=std_logic_vector(resize(unsigned(cdw_tmp), codeword'length));
        n_bits <= n_bits_next;
        
        if (en = '1') then
          --pipeline registers
          mapped_reg <= mapped;
          t_reg <= t;
          k_reg <= k_cmb;
          ones_reg <= ones_cmb;
        end if;
      end if;
    end if;
  end process;

  -- Combinational logic
  process (count, acc)
    variable v1: unsigned (count'high + 6 downto 0);
    variable v2: unsigned (v1'high - 7 downto 0);
    variable v3: unsigned (acc'high+1 downto 0); 
  begin
    v1 := (resize(unsigned(count), v1'length) sll 5) + (resize(unsigned(count), v1'length) sll 4) + (resize(unsigned(count), v1'length));
    v2 := v1(v1'high downto 7);
    v3 := resize(v2, v3'length) +  resize(unsigned(acc), v3'length);
    tmp <= '0'&std_logic_vector(v3); 
  end process;

  process (count, tmp,  mapped_reg, k_reg, t_reg, ones_reg, config_sample, config_image)
    variable k: integer := 0;
    variable k_stage2: integer := 0;
    variable mask1: unsigned (codeword'high downto 0);
    variable u: unsigned(DRANGE - 1 downto 0);
    variable p: arr_type;
    variable ones: std_logic_vector(N_K downto 0);
    variable N_K_conf: integer := DRANGE - 2;
    variable DRANGE_conf: integer := DRANGE;
    variable U_MAX_conf: integer := U_MAX;
  begin
  ones(0) := '0';
  p(0) := (others => '0');
  
  DRANGE_conf := to_integer(unsigned(config_image.D));
  N_K_conf := DRANGE_conf - 2;
  
  for j in 1 to N_K loop --
    p(j) := std_logic_vector(resize(signed(tmp),p(1)'length)-(resize(signed('0'&count), p(1)'length) sll j)); 
    ones(j) := p(j)(p(j)'high);
    if j > N_K_conf then
      ones(j) := '1';
    end if;
  end loop;
  
  for i in 1 to N_K loop
    if (ones (i) = '1') then
      k := i-1; 
      exit;
    else 
      k := N_K;
    end if;
  end loop;
  
  U_MAX_conf := to_integer(unsigned(config_sample.U_MAX));
  
  if k > N_K_conf then
    k := N_K_conf;
  end if;
  
  ones_cmb <= ones;
  k_cmb <= to_signed(k, W_D_GEN+1);

  ------------------ stage2 -------------------------------------------
  k_stage2 := to_integer(k_reg);
  u := resize(unsigned(mapped_reg) srl k_stage2, u'length); 
  if (t_reg = std_logic_vector(to_unsigned(0, W_T))) then
    n_bits_next <= std_logic_vector(to_unsigned(DRANGE_conf, n_bits'length));
    cdw_tmp(mapped_reg'high downto 0) <= mapped_reg;
    cdw_tmp(cdw_tmp'high downto mapped_reg'high+1) <= (others => '0');
  else
    if(u < to_unsigned(U_MAX_conf, u'length)) then
      n_bits_next <= std_logic_vector(to_unsigned(k_stage2, n_bits'length) + 1 + resize(u, n_bits'length));
      mask1 := resize (unsigned(not(ones_reg))srl 1, codeword'length) + 1;    
      cdw_tmp <= std_logic_vector((resize(unsigned(not(ones_reg)) srl 1, codeword'length) and resize(unsigned(mapped_reg), codeword'length)) + mask1);
    else
      n_bits_next <= std_logic_vector(to_unsigned(U_MAX_conf + DRANGE_conf, n_bits'length));
      cdw_tmp(mapped_reg'high downto 0) <= mapped_reg;
      cdw_tmp(cdw_tmp'high downto mapped_reg'high+1) <= (others => '0');
    end if;
  end if;
  end process;
end arch;