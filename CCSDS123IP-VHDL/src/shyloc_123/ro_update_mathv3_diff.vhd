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
-- Design unit  : Rho update module
--
-- File name    : ro_update_mathv3_diff.vhd
--
-- Purpose      : Module computes the rho value used for updating the weights.
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
library shyloc_123; 
--use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;    

--!@file #ro_update_mathv3_diff.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Update of the weight scaling component (CCSDS 123.0-B-1, Section 4.8.2)
--!@details This operation takes one clock cycle. The result is needed for the subsequent update of te weight vector components.

entity ro_update_mathv3_diff is
  generic (
      RESET_TYPE: integer := 1;     --! Reset flavour (0: asynchronous; 1: synchronous).
      T_INC: integer := 4;          --! Weight update factor change interval
      W_RO: integer := 5;       --! Bit width of the scaling component. log2(MAX_RO)+1
      W_T: integer := 32        --! Bit width of signal t. 
      );
  port (
      clk: in std_logic;                --! Clock signal.
      rst_n: in std_logic;              --! Reset signal. Active low.
      en: in std_logic;               --! Enable signal.
      clear: in std_logic;              --! Synchronous clear
      config_image: in config_123_image;        --! Image metadata configuration values.
      config_predictor: in config_123_predictor;    --! Predictor configuration.
      t: std_logic_vector (W_T-1 downto 0);     --! t coordinate t=x+y*Nx
      ro: out std_logic_vector(W_RO - 1 downto 0)   --! Weight update scaling component. 
      );
end ro_update_mathv3_diff;
      
architecture arch of ro_update_mathv3_diff is
begin

  process (clk, rst_n)
    variable diff: signed (t'length downto 0);
    variable t_val: std_logic_vector(T_INC downto 0); 
    variable tmp_2, tmp_3, tmp_4: signed (W_T downto 0);
    variable t_inc_var: integer := 0;
    variable t_inc_const: integer := 0;
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      ro <= (others => '0');
    elsif (clk'event and clk = '1') then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        ro <= (others => '0');
      else
        if (en = '1') then
          diff := resize(signed(t), diff'length) - resize(signed('0'&config_image.Nx), diff'length);
          --turn t_inc into a constant, to avoid wasting resources.
          t_inc_var := to_integer(unsigned(config_predictor.TINC));
          case (t_inc_var) is
            when 4 =>
              t_inc_const := 4;
            when 5 =>
              t_inc_const := 5;
            when 6 =>
              t_inc_const := 6;
            when 7 =>
              t_inc_const := 7;
            when 8 =>
              t_inc_const := 8;
            when 9 =>
              t_inc_const := 9;
            when 10 =>
              t_inc_const := 10;
            when 11 =>
              t_inc_const := 11;
            when others =>
              t_inc_const := 4;
          end case;
          tmp_2 := shift_right(diff, t_inc_const);
          if tmp_2 > 0 then
            tmp_3 := resize(signed(config_predictor.VMIN), tmp_3'length) + resize(signed(tmp_2), tmp_3'length);
          else
            tmp_3 := resize(signed(config_predictor.VMIN), tmp_3'length);
          end if;

          if tmp_3 < signed(config_predictor.VMAX) then
            tmp_4 := resize(signed(tmp_3), tmp_3'length) + resize(signed('0'&config_image.D), tmp_3'length) -  resize(signed('0'&config_predictor.OMEGA), tmp_3'length);
            ro <= std_logic_vector(tmp_4(ro'high downto 0));
          else
            tmp_4 := resize(signed(config_predictor.VMAX), tmp_3'length) + resize(signed('0'&config_image.D), tmp_3'length) -  resize(signed('0'&config_predictor.OMEGA), tmp_3'length);
            ro <= std_logic_vector(tmp_4(ro'high downto 0)); 
          end if;
        end if;
      end if;
    end if;   
  end process;
  
  

end arch;