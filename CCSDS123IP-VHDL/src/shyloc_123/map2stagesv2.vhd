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
-- Design unit  : Map
--
-- File name    : map2stagesv2.vhd
--
-- Purpose      : Maps the prediction residuals to integer values. 
--
-- Note         : 
--
-- Library      : 
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
-- Instantiates : 
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library shyloc_123; use shyloc_123.ccsds123_parameters.all; use shyloc_123.ccsds123_constants.all;    

--!@file #map2stagesv2.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Mapping of the prediction residuals (CCSDS 123.0-B-1; Section 4.9).
--!@details The module completes the mapping two cycles after the assertion of signal en.


entity map2stagesv2 is
  generic (W_S_SIGNED: integer := 17;       --! Bit width of the input samples, represented as signed integers (DRANGE +1)
       W_SCALED: integer := 34;       --! Bit width of the input samples, represented as signed integers.
       W_SMAX: integer := 17;         --! Bit width of parameters smax, smin, smid (represented as signed).
       W_MAP: integer := 16);         --! Bit width of the mapped prediction residuals.
  port (
    clk: in std_logic;                    --! Clock signal.
    rst_n: in std_logic;                  --! Reset signal. Active low.
    clear: in std_logic;                  --! Clear signal.  
    en: in std_logic;                   --! Enable signal.
    s_signed: in std_logic_vector(W_S_SIGNED -1 downto 0);  --! Current sample to be compressed represented as a signed value.
    smax: in std_logic_vector(W_SMAX-1 downto 0);           --! Smax value coming from predictor
    smin: in std_logic_vector(W_SMAX-1 downto 0);         --! Smin value coming from predictor
    s_scaled: in std_logic_vector(W_SCALED - 1 downto 0); --! Scaled predicted sample.
    valid: out std_logic;                 --! Validates mapped residual
    mapped: out std_logic_vector (W_MAP - 1 downto 0)   --! Mapped prediction residual.
  );
end map2stagesv2;

architecture arch of map2stagesv2 is

  signal mapped_tmp, mapped_tmp_next: signed (mapped'high downto 0);
  signal omg_tmp, omg_tmp_next: signed (s_scaled'high+1 downto 0);
  signal s_scaled_parity: std_logic;

  signal pred_residual_tmp, pred_residual_next: signed (s_scaled'high downto 0);
  signal valid_reg: std_logic;
begin
  
-----------------------------------------------------------------------------
-- Output assignments
-----------------------------------------------------------------------------
  mapped <= std_logic_vector(mapped_tmp);
  
-----------------------------------------------------------------------------
-- Registers
-----------------------------------------------------------------------------
  process(clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      mapped_tmp <= (others => '0');
      omg_tmp <= (others => '0');
      pred_residual_tmp <= (others => '0');
      s_scaled_parity <= '0';
      valid_reg <= '0';
      valid <= '0';
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        mapped_tmp <= (others => '0');
        omg_tmp <= (others => '0');
        pred_residual_tmp <= (others => '0');
        s_scaled_parity <= '0';
        valid_reg <= '0';
        valid <= '0';
      else
        if (en = '1') then
          omg_tmp <= omg_tmp_next;
          pred_residual_tmp <= pred_residual_next;
          s_scaled_parity <= s_scaled(0);   
          valid_reg <= '1';
        else
          valid_reg <= '0';
        end if;
        valid <= valid_reg;
        mapped_tmp <= mapped_tmp_next;
      end if;
    end if;
  end process;
  
-----------------------------------------------------------------------------
-- Combinatorial logic
----------------------------------------------------------------------------- 
  process (s_signed, s_scaled, smax, smin, omg_tmp, pred_residual_tmp, s_scaled_parity)
    variable s_pred: signed (s_scaled'high downto 0);
    variable pred_residual: signed(s_pred'high downto 0);  
    variable omg_tmp1, omg_tmp2: signed (s_pred'high + 1 downto 0);
    variable omg: signed (s_pred'high + 1 downto 0);
    variable abs_pred_residual: signed(s_pred'high downto 0);
    variable mapped_var: signed (s_pred'high + 1 downto 0); 
    
  begin

    s_pred := signed(s_scaled(s_scaled'high)&s_scaled(s_scaled'high downto 1)); 
    pred_residual := resize(signed(s_signed), pred_residual'length) - s_pred;
    
    omg_tmp1:= resize(s_pred, omg_tmp1'length) - resize(signed(smin), omg_tmp1'length); 
    omg_tmp2:= resize(signed(smax), omg_tmp2'length) - resize(s_pred, omg_tmp2'length);
    
    if (omg_tmp1 < omg_tmp2) then
      omg_tmp_next <= omg_tmp1;
    else
      omg_tmp_next <= omg_tmp2;
    end if;
    
    pred_residual_next <= pred_residual;
    
    abs_pred_residual := abs(pred_residual_tmp);
    omg := signed(omg_tmp);
    
    if (abs_pred_residual > omg) then
      mapped_var := resize(abs_pred_residual, mapped_var'length) + resize(omg, mapped_var'length);
    else
      if (s_scaled_parity = '0') then -- even
        if (pred_residual_tmp >= to_signed(0, pred_residual_tmp'length)) then 
          mapped_var := abs_pred_residual&'0';
        else
          mapped_var := abs_pred_residual&'0' - 1;
        end if;
      else
        if (pred_residual_tmp <= to_signed(0, pred_residual_tmp'length)) then
          mapped_var := abs_pred_residual&'0';
        else
          mapped_var := abs_pred_residual&'0' - 1;
        end if;
      end if;
    end if;
    
    mapped_tmp_next <= mapped_var(W_MAP-1 downto 0);

end process;
      
    
    
end arch;