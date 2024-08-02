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
-- Design unit  : Localdiff module
--
-- File name    : localdiffv3.vhd
--
-- Purpose      : Module compute the central and directional local differences.
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

--!@file #localdiffv3.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es

--!@brief Calculates the local differences for prediction (CCSDS 123.0-B-1; Section 4.5).
--!@details  This module calculates the local differences. If the compressor is configured 
--! with full prediction, the local differences module computes the directional local 
--! differences (north, west and north west) or the central local differences depending on the 
--! input signal mode.
--! When the compressor is configured with reduced prediction, only the 
--! central local difference is calculated. 
--! The output can represent the central local difference or the directional local differences, 
--! the latter only when full prediction is enabled. 


entity localdiffv3 is
  generic (
       RESET_TYPE: integer;
       DRANGE: integer := 16;     --! Bit width of the input samples.
       PREDICTION_MODE: integer := 0; --! Full prediction (0) or reduced prediction (1).
       W_LS: integer := 19;       --! Bit width of the local sum signal (DRANGE + 3)
       W_LD: integer := 20);      --! Bit width of the local differences signal (DRANGE + 4).
  port(
    clk: in std_logic;                    --! Clock signal.
    rst_n: in std_logic;                  --! Reset signal. Active low.
    sign: in std_logic;                   --! Input samples are signed (1) or unsigned (0).
    en: in std_logic;                   --! Enable signal.
    clear: in std_logic;                  --! Synchronous clear signal. 
    config_predictor: in config_123_predictor;        --! Configuration values of the predictor. 
    mode: in std_logic;                   --! Calculate directional local differences (0) or central local differences (1).
    opcode_ld: in std_logic_vector(4 downto 0);       --! Code indicating the relative position of a sample in the spatial dimension.
    s: in std_logic_vector (DRANGE-1 downto 0);       --! Current sample to be compressed, s(x, y, z)
    s_left: in std_logic_vector (DRANGE-1 downto 0);    --! Left neighbour of the current sample, s(x-1, y, z)
    s_top: in std_logic_vector (DRANGE-1 downto 0);     --! Top neighbour of the current sample,  s(x, y+1, z)
    s_top_left: in std_logic_vector (DRANGE-1 downto 0);  --! Top left neighbour of the current sample, s(x-1 , y+1, z)
    ls: in std_logic_vector(W_LS-1 downto 0);       --! Local sum result for the current sample.
    ls_predict: out std_logic_vector(W_LS-1 downto 0);    --! Local sum result for predictor.
    s_predict: out std_logic_vector ((DRANGE+1)-1 downto 0);  --! Current sample to be compressed for predictor
    opcode_predict: out std_logic_vector (4 downto 0);      --! Opcode value. 
    ld : out std_logic_vector(W_LD-1 downto 0);         --! Local difference output (registered).  
    ld_n : out std_logic_vector(W_LD-1 downto 0);       --! Directional north local difference output (registered).  
    ld_w : out std_logic_vector(W_LD-1 downto 0);       --! Directional west local difference output (registered).  
    ld_nw : out std_logic_vector(W_LD-1 downto 0)       --! Directional northwest difference output (registered).  
  );
end localdiffv3;

--!@brief Architecture definition
architecture arch_shyloc of localdiffv3 is
  signal s_r: std_logic_vector (DRANGE-1 downto 0);
  signal opcode: std_logic_vector (3 downto 0);
begin
-----------------------------------------------------------------------------
-- Output assignments
-----------------------------------------------------------------------------
s_r <= s;
opcode <= opcode_ld(3 downto 0);


process (clk, rst_n)
  variable d1, d2, d3, d4, d5: signed (W_LD-1 downto 0);
  variable ld_central: std_logic_vector(W_LD-1 downto 0);
  variable ld_north: std_logic_vector(W_LD-1 downto 0);
  variable ld_west: std_logic_vector(W_LD-1 downto 0);
  variable ld_north_west: std_logic_vector(W_LD-1 downto 0);

begin
  if (rst_n = '0' and RESET_TYPE = 0) then
    ld <= (others => '0');
    ld_n <= (others => '0');
    ld_w <= (others => '0');
    ld_nw <= (others => '0');
    ls_predict <= (others => '0');
    s_predict <= (others => '0');
    opcode_predict <= (others => '0');
  elsif (clk'event and clk = '1') then
    if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
      ld <= (others => '0');
      ld_n <= (others => '0');
      ld_w <= (others => '0');
      ld_nw <= (others => '0');
      ls_predict <= (others => '0');
      s_predict <= (others => '0');
      opcode_predict <= (others => '0');
    else
      if(en = '1') then
        if (sign = '1') then -- signed input
          d1 := resize (signed (s_r), W_LD);
          d2 := resize (signed (s_left), W_LD);
          d3 := resize (signed (s_top), W_LD);
          d4 := resize (signed (s_top_left), W_LD);
          d5 := resize (signed (ls), W_LD);
        else -- unsigned input
          d1 := resize (signed ('0'& s_r), W_LD);
          d2 := resize (signed ('0'& s_left), W_LD);
          d3 := resize (signed ('0'& s_top), W_LD);
          d4 := resize (signed ('0' & s_top_left), W_LD);
          d5 := resize (signed (ls), W_LD);
        end if;
        
        -- Behaviour depends on prediction mode.
        if (config_predictor.PREDICTION = "0") then
          if (opcode (1 downto 0 ) = "11") then -- y > 0, x > 0
            ld_north := std_logic_vector ((d3 sll 2) - d5);
            ld_west := std_logic_vector ((d2 sll 2) - d5);
            ld_north_west := std_logic_vector ((d4 sll 2) - d5);
            ld_central := std_logic_vector ((d1 sll 2) - d5);
            
          elsif (opcode (1 downto 0 ) = "10") then -- x = 0, y > 0
            ld_north := std_logic_vector ((d3 sll 2) - d5);
            ld_west := std_logic_vector ((d3 sll 2) - d5);
            ld_north_west := std_logic_vector ((d3 sll 2) - d5);
            ld_central := std_logic_vector ((d1 sll 2) - d5);
          
          elsif (opcode (1 downto 0 ) = "01") then -- y = 0, x > 0
            ld_central := std_logic_vector ((d1 sll 2) - d5);
            ld_north := (others => '0');
            ld_west := (others => '0');
            ld_north_west := (others => '0');
          else
            ld_central := (others => '0');
            ld_north := (others => '0');
            ld_west := (others => '0');
            ld_north_west := (others => '0');
          end if;
          --Output registers assignment
          ld  <= ld_central;
          ld_n <= ld_north;
          ld_w <= ld_west;
          ld_nw <= ld_north_west;
          
        else
          ld_central := std_logic_vector ((d1 sll 2) - d5);
          ld <= ld_central;
        end if;
        ls_predict <= ls;
        s_predict <= std_logic_vector(d1(s_predict'high downto 0));
        opcode_predict <= opcode_ld;
      end if;
    end if;
  end if;
end process;

end arch_shyloc;