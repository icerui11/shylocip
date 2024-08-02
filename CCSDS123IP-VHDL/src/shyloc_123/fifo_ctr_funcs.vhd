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
-- Design unit  : FIFO control functions package
--
-- File name    : fifo_ctr_funcs.vhd
--
-- Purpose      : Package includes functions to control the read
--          and write enables from the FIFOs storing the
--          neighbouring samples at the input of the compressor.  
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

--!@file #fifo_ctrl_funcs.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Controls the read and write enables in the FIFOs depending on opcode

package fifo_ctrl is
  function ctrl_fifo_read (opcode: std_logic_vector (4 downto 0)) return std_logic_vector;
  function ctrl_fifo_write (opcode: std_logic_vector (4 downto 0)) return std_logic_vector;
end fifo_ctrl;


package body fifo_ctrl is
  
  -----------------------------------------------------------------------------
  --! Determine from which of the FIFOs to read depending on the
  --! relative location of a sample (opcode)
  -----------------------------------------------------------------------------
  function ctrl_fifo_read (opcode: std_logic_vector (4 downto 0)) return std_logic_vector  is
    variable result: std_logic_vector (4 downto 0);
  begin
  
  case (opcode) is
    when "00000" | "10000" => -- x = 0; y = 0;
      result(0) := '1'; --current sample
      result(1) := '0'; --top right neighbour
      result(2) := '0'; --top
      result(3) := '0'; --left
      result(4) := '0'; --top left
    when "00001" => -- y = 0; 0 < x < Nx-1
      result(0) := '1';
      result(1) := '0'; 
      result(2) := '0';
      result(3) := '0';
      result(4) := '1';
    when "10001" => -- y = 0; x = Nx-1
      result(0) := '1';
      result(1) := '1'; 
      result(2) := '0';
      result(3) := '0';
      result(4) := '1';
    when "01010" | "11010" => --11010 code added for FIFO top right control
      result(0) := '1';
      result(1) := '1'; 
      result(2) := '1';
      result(3) := '0';
      result(4) := '0';
    when "01111" | "00111" | "11111"=>
      result(0) := '1';
      result(1) := '1';
      result(2) := '1';
      result(3) := '1';
      result(4) := '1';
    when "10111" =>
      result(0) := '1';
      result(1) := '0'; 
      result(2) := '1';
      result(3) := '1';
      result(4) := '1';
    when others => 
      result(0) := '0';
      result(1) := '0';
      result(2) := '0';
      result(3) := '0';
      result(4) := '0';
    end case;
    return result;
  end;

  -----------------------------------------------------------------------------
  --! Determine in which of the FIFOs to read depending on the
  --! relative location of a sample (opcode)
  -----------------------------------------------------------------------------
  function ctrl_fifo_write (opcode: std_logic_vector (4 downto 0)) return std_logic_vector  is
    variable result: std_logic_vector (2 downto 0);
  begin
    case opcode is
      when "00000" | "10000" =>
        result(0) := '0'; --top
        result(1) := '1'; --left
        result(2) := '0'; --top_left
      when "00001" =>
        result(0) := '0';
        result(1) := '1';
        result(2) := '0';
      when "10001" | "00111" => 
        result(0) := '1';
        result(1) := '0';
        result(2) := '0';
      when "01010" | "01111" | "11010" | "11111" =>
        result(0) := '1';
        result(1) := '1';
        result(2) := '1';
      when "10111"  =>
        result(0) := '0';
        result(1) := '0';
        result(2) := '0';
      when others =>
        result(0) := '0';
        result(1) := '0';
        result(2) := '0';
    end case;
    return result;
  end;
end fifo_ctrl;
  