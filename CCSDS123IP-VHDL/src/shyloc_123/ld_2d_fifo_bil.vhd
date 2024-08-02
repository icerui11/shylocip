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
-- Design unit  : Local differences FIFO for BIL order.
--
-- File name    : ld_2d_fifo_bil.vhd
--
-- Purpose      : Stores a vector of local differences for BIL order.
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

--!@file #ld_2d_fifo_bil.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief 2d fifo structure to store the central ld values for BIL
--!@details It has one input corresponding to the central local difference and the output is a vector 
--!The elements are shifted appropriately, and moved from a FIFO to the other, to form the necessary vector.
--!The central local differences value arrives to the FIFO 0
--!When it is read it is moved to FIFO 1 
--!And so on, until it is out of the FIFO.
--!The FIFO needs to be reset after every line is compressed in all bands. 

entity ld_2d_fifo_bil is
  generic (
    Cz: integer := 6;           --! Number of elements in the local differences and weights vectors
    W : integer := 8;         --! Bit width of each element in to be stored.
    NE : integer := 4;          --! Number of elements in the FIFO (not actually used, we allocate 2**W_ADDR elements).
    W_ADDR : integer := 9;        --! Bit width of the read and write pointers.
    RESET_TYPE: integer := 1;     --! Reset flavour (0) asynchronous (1) synchronous.
    EDAC: integer := 0;         --! EDAC enabled (0) disabled (1) or (3) enabled.
    TECH : integer := 0               --! Parameter used to change technology; (0) uses inferred memories.
  );
  port(
    clk: in std_logic;                --! Clock.
    rst_n: in std_logic;              --! Reset value (active low).
    clr : in std_logic;                             --! Clear flag (asynchronous), resets FIFO pointers.
    w_update: in std_logic;                         --! Write enable.
    r_update : in std_logic_vector (0 to Cz-1);     --! Vector of read enables, one per element in the local differences vector.
    en_shift: in std_logic;                         --! When = '1', elements in the FIFO are shifted in the next raising clk. 
    data_in: in std_logic_vector(W-1 downto 0);   --! Input vector of local differences to store.
    data_vector_out: out ld_array_type(0 to Cz-1);  --! Output vector of local differences to store.
    empty : out std_logic;                          --! Empty flag.
    full : out std_logic;                           --! Full flag.
    afull : out std_logic;                          --! Almost full flag (raises when there is room for one element).
    aempty : out std_logic;                          --! Almost empty flag (raises when there is one element left).
    edac_double_error: out std_logic        --! EDAC double error.
  );
  

end ld_2d_fifo_bil;

architecture arch_bil of ld_2d_fifo_bil is

  signal data_vector_tmp_out: ld_array_type(0 to Cz-1);
  signal r_update_intermediate: std_logic_vector(0 to Cz-1);
  signal w_update_intermediate: std_logic_vector(0 to Cz-1);
  signal empty_vector: std_logic_vector(0 to Cz-1);
  signal full_vector: std_logic_vector(0 to Cz-1);
  signal afull_vector: std_logic_vector(0 to Cz-1);
  signal aempty_vector: std_logic_vector(0 to Cz-1);
  signal clear: std_logic;
  
  signal edac_double_error_vector: std_logic_vector(0 to Cz-1);
  signal edac_double_error_vector_tmp: std_logic_vector(0 to Cz);
  
begin 
  -----------------------------------------------------------------------------
  -- Output assignment
  -----------------------------------------------------------------------------
  clear <= clr;
  empty <= empty_vector(0);
  full <= full_vector(0);
  afull <= afull_vector(0);
  aempty <= aempty_vector(0);
  edac_double_error <= edac_double_error_vector_tmp (Cz);
  edac_double_error_vector_tmp(0) <= '0';
  
  -----------------------------------------------------------------------------
  -- Register
  -----------------------------------------------------------------------------
  process (clk, rst_n)
  begin
    if (rst_n = '0' and RESET_TYPE = 0) then
      r_update_intermediate <= (others => '0');
    elsif clk'event and clk = '1' then
      if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
        r_update_intermediate <= (others => '0');
      else
        if (en_shift = '1') then
          r_update_intermediate <= r_update;
        else
          r_update_intermediate <= (others => '0');
        end if;
      end if;
    end if;
  end process;
  
  data_vector_out <= data_vector_tmp_out;
  
  fifo_2d: for j in 0 to Cz-1 generate
    gen_ld_new: if j = 0 generate
      -----------------------------------------------------------------------------
      --!@brief FIFO 0 to store the central local differences values
      -----------------------------------------------------------------------------
      fifo_ld_0: entity shyloc_utils.fifop2(arch)
      generic map (
        RESET_TYPE => RESET_TYPE, W => W,
        NE => NE,
        W_ADDR => W_ADDR, 
		EDAC => EDAC, 
        TECH => TECH) 
      port map (
        clk => clk,
        rst_n => rst_n,
        clr => clr,
        w_update => w_update,
        r_update => r_update(j),
        data_in => data_in, -- Central local difference goes here
        data_out => data_vector_tmp_out(0), -- Element 0 of the local differences vectors
        empty => empty_vector(j),
        full => full_vector(j),
        afull => afull_vector(j),
        aempty => aempty_vector(j), 
        edac_double_error => edac_double_error_vector(j)
      );
    end generate gen_ld_new;
    
    gen_ld_other: if j > 0 generate
      -----------------------------------------------------------------------------
      --!@brief FIFO to store the values read from FIFO 0
      -----------------------------------------------------------------------------
      fifo_ld_Z: entity shyloc_utils.fifop2(arch)
      generic map (
        RESET_TYPE => RESET_TYPE, W => W,
        NE => NE,
        W_ADDR => W_ADDR, 
		EDAC => EDAC, 
        TECH => TECH) 
      port map (
        clk => clk,
        rst_n => rst_n,
        clr => clr,
        w_update => r_update_intermediate(j-1), 
        r_update => r_update(j), 
        data_in => data_vector_tmp_out(j-1), -- and we move to the other
        data_out => data_vector_tmp_out(j), -- Elements 1 to Cz-1 of the local differences vectors
        empty => empty_vector(j),
        full => full_vector(j),
        afull => afull_vector(j),
        aempty => aempty_vector(j), 
        edac_double_error => edac_double_error_vector(j)
        );
    end generate gen_ld_other;
    edac_double_error_vector_tmp(j+1) <= edac_double_error_vector_tmp(j) or edac_double_error_vector(j);
  end generate fifo_2d;
end arch_bil; --============================================================================