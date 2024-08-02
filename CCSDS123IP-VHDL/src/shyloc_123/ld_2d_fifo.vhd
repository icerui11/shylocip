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
-- Design unit  : Local differences FIFO
--
-- File name    : ld_2d_fifo.vhd
--
-- Purpose      : Stores a vector of local differences.
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
-- Instantiates : fifop2
--============================================================================


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library shyloc_123; 
--use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;

library shyloc_utils;    


--!@file #ld_2d_fifo.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief 2d fifo structure to store the local differences vector

entity ld_2d_fifo is
  generic (
    Cz: integer := 6;                 --! Number of elements in the local differences vector.
    W : integer := 18;                --! Bit width of each element in to be stored.
    NE : integer := 50;               --! Number of elements in the FIFO (not actually used, we allocate 2**W_ADDR elements).
    W_ADDR : integer := 9;              --! Bit width of the read and write pointers.
    RESET_TYPE: integer := 1;           --! Reset flavour (0) asynchronous (1) synchronous.
    EDAC: integer := 0;               --! EDAC enabled (0) disabled (1) or (3) enabled.
    TECH : integer := 0               --! Parameter used to change technology; (0) uses inferred memories.  
  );
  port(
    clk: in std_logic;                --! Clock.
    rst_n: in std_logic;              --! Reset value (active low).
    clr : in std_logic;               --! Clear flag (asynchronous), resets FIFO pointers.
    w_update: in std_logic;             --! Write enable.
    r_update : in std_logic;            --! Read enable.
    data_vector_in: in ld_array_type(0 to Cz-1);  --! Input vector of local differences to store.
    data_vector_out: out ld_array_type(0 to Cz-1);  --! Output vector of local differences to store.
    empty : out std_logic;              --! Empty flag.
    full : out std_logic;             --! Full flag.
    afull : out std_logic;              --! Almost full flag (raises when there is room for one element).
    aempty : out std_logic;             --! Almost empty flag (raises when there is one element left).
    edac_double_error: out std_logic        --! EDAC double error.
  );
  

end ld_2d_fifo;

architecture arch of ld_2d_fifo is
  signal empty_vector: std_logic_vector(0 to Cz-1);
  signal full_vector: std_logic_vector(0 to Cz-1);
  signal afull_vector: std_logic_vector(0 to Cz-1);
  signal aempty_vector: std_logic_vector(0 to Cz-1);
  signal edac_double_error_vector: std_logic_vector(0 to Cz-1);
  signal edac_double_error_vector_tmp: std_logic_vector(0 to Cz);
begin 

  --Empty, full, afull and aempty flag from FIFO 0 (they are all the same)
  empty <= empty_vector(0);
  full <= full_vector(0);
  afull <= afull_vector(0);
  aempty <= aempty_vector(0);
  edac_double_error <= edac_double_error_vector_tmp (Cz);
  
  edac_double_error_vector_tmp(0) <= '0';
  
  -----------------------------------------------------------------------------
  --Here we generate Cz FIFOs, each will store an element of the local differences vector.
  -----------------------------------------------------------------------------
  fifo_2d: for j in 0 to Cz-1 generate
    fifo_2d_wei: entity shyloc_utils.fifop2(arch)
    generic map (
      RESET_TYPE => RESET_TYPE,
      W => W,
      NE => NE,
      W_ADDR => W_ADDR, EDAC => EDAC, TECH => TECH) 
    port map (
      clk => clk,
      rst_n => rst_n,
      clr => clr,
      w_update => w_update,
      r_update => r_update,
      data_in => data_vector_in(j), 
      data_out => data_vector_out(j), 
      empty => empty_vector(j),
      full => full_vector(j),
      afull => afull_vector(j),
      aempty => aempty_vector(j), 
      edac_double_error => edac_double_error_vector(j)
    );
    edac_double_error_vector_tmp(j+1) <= edac_double_error_vector_tmp(j) or edac_double_error_vector(j);
  end generate fifo_2d;
end arch; --============================================================================