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
-- Design unit  : sample top module
--
-- File name    : sample_top.vhd
--
-- Purpose      : Component instantiation and fsm instantiation of the Sample-Adaptive Entropy Encoder
--
-- Note         :
--
-- Library      : shyloc_123
--
-- Author       :
--                Institute for Applied Microelectronics (IUMA)
--                University of Las Palmas de Gran Canaria
--                Campus Universitario de Tafira s/n
--                35017, Las Palmas de Gran Canaria
--                Canary Islands, Spain
--
-- Contact      : lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--
-- Instantiates : components (sample_comp), fsm (sample_fsm)
--============================================================================

--!@file #sample_top.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief  Component instantiation and fsm instantiation of the Sample-Adaptive Entropy Encoder

--! Use standard library
library ieee;
--! Use logic elements
use ieee.std_logic_1164.all;
--! Use numeric elements
use ieee.numeric_std.all;

--! Use shyloc_123 library
library shyloc_123; 
--! Use generic shyloc123 parameters
use shyloc_123.ccsds123_parameters.all; 
--! Use constant shyloc123 constants
use shyloc_123.ccsds123_constants.all;     

--! sample_top entity  Top module of the Sample-Adaptive Entropy Encoder
entity sample_top is
  generic (DRANGE       : integer := D_GEN;       --! Dynamic range.
       PREDICTION_TYPE  : integer := PREDICTION_TYPE;  --! (0) BIP-base; (1) BIP-mem; (2) BSQ; (3) BIL (4) BIL-MEM.
       W_BUFFER     : integer := W_BUFFER_GEN);   --! Bit width of the output buffer.
  port (
    -- System Interface
    clk   : in std_logic;   --! Clock signal.
    rst_n : in std_logic;   --! Reset signal. Active low.
    
    -- Configuration and Control Interface
    config_image        : in config_123_image;    --! Image relative configuration.
    config_sample       : in config_123_sample;   --! Sample-Adaptive Encoder relative configuration.
    config_valid        : in std_logic;       --! Configuration validation.
    clear             : in std_logic;       --! Clear signal.
    stop            : out std_logic;      --! Stop signal.
    eop             : out std_logic;      --! End of processing.
    fsm_invalid_state     : out std_logic;      --! Invalid state flag.
    sample_ready        : out std_logic;      --! Sample-Adaptive Encoder is ready to encode samples.
    sample_edac_double_error  : out std_logic;      --! Edac flag
    -- Data Input Interface
    data_in       : in std_logic_vector(W_MAP-1 downto 0);        --! Sample to compress.
    data_in_valid   : in std_logic;                     --! New sample validation.
    header        : in std_logic_vector(W_BUFFER-1 downto 0);       --! Header to be sent directly to packer.
    is_header_in    : in std_logic;                     --! Header validation.
    n_bits_header_in  : in std_logic_vector (W_NBITS_HEAD_GEN-1 downto 0);  --! Number of bits of the header.
    
    -- Data Output Interface
    buff_out    : out std_logic_vector (W_BUFFER-1 downto 0); --! Output word (With compressed sample/s).
    buff_full   : out std_logic                 --! Output word validation.
    
  );  
end sample_top;

--! @brief Architecture of sample_top Component instantiation and fsm instantiation of the Sample-Adaptive Entropy Encoder
architecture arch of sample_top is
  
  -- Coordinate signals
  signal t_opcode : std_logic_vector (W_T-1 downto 0);
  signal z_opcode : std_logic_vector (W_ADDR_IN_IMAGE -1 downto 0);
  signal opcode : std_logic_vector (4 downto 0);
  
  -- Samples FIFO control
  signal r_update_curr  : std_logic;
  signal empty_curr   : std_logic;
  signal aempty_curr    : std_logic;
  
  -- Control signals
  signal flush    : std_logic;
  signal clear_curr : std_logic;
  
  -- Component Enable signals
  signal en_opcode  : std_logic;
  signal en_update  : std_logic; 
  signal en_create  : std_logic;
  signal en_bitpack : std_logic; 
  
begin

  ------------------------------------
  --!@brief Sample-Adaptive components
  ------------------------------------
  components: entity shyloc_123.sample_comp(arch)
      generic map ( 
            DRANGE => DRANGE, 
            --W_ADDR_BANK => W_ADDR_BANK, 
            PREDICTION_TYPE => PREDICTION_TYPE, 
            W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE,
            W_BUFFER => W_BUFFER )
    
  
  port map (
      clk     =>  clk,      
      rst_n =>  rst_n,        
      t_opcode => t_opcode, 
      z_opcode => z_opcode, 
      config_valid => config_valid, 
      config_sample => config_sample, 
      config_image => config_image, 
      clear => clear, 
      data_in => data_in, 
      data_in_valid => data_in_valid,
      is_header_in => is_header_in, 
      r_update_curr => r_update_curr,
      empty_curr => empty_curr, 
      aempty_curr => aempty_curr,
      sample_ready => sample_ready,
      en_opcode => en_opcode, 
      en_update => en_update,
      en_create => en_create,
      opcode => opcode,
      clear_curr => clear_curr,
      en_bitpack => en_bitpack, 
      flush => flush, 
      n_bits_header => n_bits_header_in, 
      header => header,
      edac_double_error => sample_edac_double_error,
      buff_full => buff_full, 
      buff_out => buff_out
      );

  -----------------------------
  --!@brief Sample-Adaptive FSM
  -----------------------------
  fsm: entity shyloc_123.sample_fsm (arch)
  generic map(
    DRANGE => DRANGE,            
    --W_ADDR_BANk => W_ADDR_BANk,       
    W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE)  
    
  port map (
      clk => clk,
      rst_n => rst_n,
      config_valid => config_valid,
      config_image => config_image,
      clear => clear,       
      eop => eop, 
      stop => stop, 
      fsm_invalid_state => fsm_invalid_state,
      t_opcode => t_opcode, 
      z_opcode => z_opcode, 
      r_update_curr => r_update_curr, 
      empty_curr => empty_curr, 
      aempty_curr => aempty_curr, 
      clear_curr => clear_curr,
      opcode => opcode,
      en_opcode => en_opcode,
      en_create => en_create, 
      en_bitpack => en_bitpack,
      en_update => en_update, 
      flush => flush 
  );
end arch;
  