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
-- Design unit  : Packing top module
--
-- File name    : packing_top_123.vhd
--
-- Purpose      : Selects what to send to the bitpacking module, depending on
--          the selected input.
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
-- Instantiates : async_fifo_ctrl, reg_bank_2clk
--============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library shyloc_utils;
library shyloc_123; use shyloc_123.ccsds123_parameters.all; use shyloc_123.ccsds123_constants.all;    

--!@file #packing_top_123.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Performs the bit packing for the split bits and final bit stream.
--!@details 


entity packing_top_123 is
      generic (
        W_BUFFER : integer := 32;               --! Number of bits of the output buffer
        W_NBITS : integer := 6
        );
      port (
        clk: in std_logic;                          --! Clock signal.
        rst_n: in std_logic;                        --! Reset signal. Active low.
        
        en: in std_logic;                         --! Enable packer.
        clear: in std_logic;                        --! Synchronous clear signal.
        config_image: in config_123_image;                  --! Image configuration.
        
        config_valid: in std_logic;                     --! Flag to validate the configuration.             
        flag_pack_header: in std_logic;                   --! Flag to enable packing the generated header.
        
        header: in  std_logic_vector (W_BUFFER-1 downto 0);         --! 121 Header values to pack.
        n_bits_header: in std_logic_vector(W_NBITS_HEAD_GEN-1 downto 0);  --! Number of bits in the header.
        
        codeword_in: in std_logic_vector(W_BUFFER-1 downto 0);        --! Partial bitstream to pack in the output buffer.
        n_bits_in: in std_logic_vector(W_NBITS-1 downto 0);         --! Number of bits in the codeword_in.
        
        flush: in std_logic;                      --! Flag to perform a flush at the end of the compressed file.
        buff_out: out std_logic_vector (W_BUFFER-1 downto 0);     --! Output word.
        buff_full: out std_logic                    --! Flag to validate the output word.
      );
end packing_top_123;


architecture arch of packing_top_123 is

  signal n_bits: std_logic_vector (W_NBITS-1 downto 0);
  signal codeword: std_logic_vector (W_BUFFER-1 downto 0);
  --signal W_BUFFER_resolved: std_logic_vector(W_W_BUFFER_GEN-1 downto 0);
  
begin
    --Select W_BUFFER_resolved value depending on configuration
    
    --W_BUFFER_resolved <= config_image.D when config_image.
    
    process (flag_pack_header, header, n_bits_header, codeword_in, n_bits_in)
    begin
      if flag_pack_header = '1' then
        codeword <= header;
        --WARNING!!: what if n_bits_header'length < n_bits'length?
        n_bits <= std_logic_vector(resize(unsigned(n_bits_header), n_bits'length));
      else
        codeword <= codeword_in;
        --WARNING!!: what if n_bits_header'length < n_bits'length?
        n_bits <= std_logic_vector(resize(unsigned(n_bits_in), n_bits'length));
      end if;
    end process;
    
    -- Bit packing module
    final_packer: entity shyloc_utils.bitpackv2(arch)
    generic map (
      W_W_BUFFER_GEN => W_W_BUFFER_GEN,
      RESET_TYPE => RESET_TYPE,
      W_BUFFER => W_BUFFER_GEN, 
      W_NBITS => W_NBITS)
    port map (
      clk => clk, 
      rst_n => rst_n, 
      en => en,
      clear => clear, 
      W_BUFFER_configured => config_image.W_BUFFER,
      config_valid => config_valid,
      n_bits => n_bits,
      flush => flush, 
      codeword => codeword, 
      buff_out => buff_out, 
      buff_full => buff_full
    );  
      
end arch;