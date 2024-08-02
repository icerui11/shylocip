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
-- Design unit  : Clip operation
--
-- File name    : clip.vhd
--
-- Purpose      : Clips the input value between a maximum and a minimum
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
-- Instantiates : 
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--!@file #clip.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Clips the input value between a maximum and a minimum (assuming W_CLIP is always bigger than W_BOUND)

entity clip is
  generic (
      -- will depend on what is going to be sent, either smax/smin or wmax/wmin or vmaxvmin; assumes signed input
      W_BOUND: integer := 16; --! Bit widht of the max and min and clipped output
       W_CLIP: integer := 16); --! Bit width of the input data to clip
  port (
    min: in std_logic_vector (W_BOUND-1 downto 0);    --! Minimum bound.
    max: in std_logic_vector (W_BOUND-1 downto 0);    --! Maximum bound.
    clipin: in std_logic_vector (W_CLIP - 1 downto 0);  --! Input value to clip.
    clipout: out std_logic_vector (W_BOUND-1 downto 0)  --! Output value to clip.
    );
end clip;

architecture arch of clip is
  signal sig_min: signed (clipin'high downto 0);
  signal sig_max: signed (clipin'high  downto 0);
  signal sig_clipin: signed (clipin'high  downto 0);

begin
  sig_min <= resize (signed(min), clipin'length);
  sig_max <= resize (signed(max), clipin'length);
  sig_clipin <= signed (clipin);
  
  clipout <= std_logic_vector(resize (sig_min, max'length)) when (sig_clipin < sig_min) else
         std_logic_vector(resize (sig_max, max'length)) when (sig_clipin > sig_max) else
         std_logic_vector(resize(sig_clipin, max'length));
end arch;