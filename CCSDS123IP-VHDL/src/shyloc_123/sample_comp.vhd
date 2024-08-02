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
-- Design unit  : Sample-Adaptive Entropy Encoder components
--
-- File name    : sample_comp.vhd
--
-- Purpose      : Components to perform the encoding under the sample adaptive approach
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
-- Instantiates : fifo_curr (fifop2), opcode_update (opcode_update(bip_arch)), update_counters (count_updatev2(arch_bip)), opcode_update (opcode_update(bsq_arch)), update_counters (count_updatev2(arch)), opcode_update (opcode_update(bil_arch)), update_counters (count_updatev2(arch_bil)), createcdw (create_cdwv2), bit_pack (packing_top_123)
--============================================================================

--!@file #sample_comp.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Institute for Applied Microelectronics (IUMA), University of Las Palmas de Gran Canaria, Campus Universitario de Tafira s/n, 35017, Las Palmas de Gran Canaria, Canary Islands, Spain
--!@email  lsfalcon@iuma.ulpgc.es, agomez@iuma.ulpgc.es, roberto@iuma.ulpgc.es
--!@brief Components instantiation and connection to perform the encoding under the sample adaptive approach

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

--! Use shyloc_utils library
library shyloc_utils;     

--! sample_comp entity Components to perform the encoding under the sample adaptive approach
--! Components instantiation and connection
entity sample_comp is
  generic (DRANGE       : integer := 16;    --! Dynamic range of the input samples.
       W_ADDR_BANK    : integer := 2;     --! Bit width of the address signal in the register banks.
       W_ADDR_IN_IMAGE  : integer := 16;    --! Bit width of the image coordinates (x, y, z).
       PREDICTION_TYPE  : integer := 0;      --! (0) BIP-base; (1) BIP-mem; (2) BSQ; (3) BIL; (4)BIL-mem.
       W_BUFFER     : integer := 64     --! Bit width of the output buffer.
      );
  port (
    -- System Interface
    clk   : in std_logic;   --! Clock signal.
    rst_n : in std_logic;   --! Reset signal. Active low.
    
    -- Configuration and Control Interface
    config_sample   : in config_123_sample;   --! Sample-Adaptive Encoder relative configuration.
    config_image    : in config_123_image;    --! Image relative configuration.
    config_valid    : in std_logic;       --! Configuration validation.
    clear       : in std_logic;       --! Clear signal.
    flush       : in std_logic;       --! Flag to perform a flush at the end of the compressed file.
    sample_ready    : out std_logic;      --! Sample-Adaptive Encoder is ready to encode samples.
    edac_double_error : out std_logic;      --! edac flag
    -- Data Input Interface
    data_in       : in std_logic_vector(W_MAP-1 downto 0);        --! Sample to compress.
    data_in_valid   : in std_logic;                     --! New sample validation.
    is_header_in    : in std_logic;                     --! Input word is a header word.
    header        : in std_logic_vector(W_BUFFER-1 downto 0);       --! Header to be sent directly to packer.
    n_bits_header   : in std_logic_vector(W_NBITS_HEAD_GEN-1 downto 0);   --! Number of bits of the header.
    
    -- Data Output Interface
    en_opcode   : in std_logic;                       --! Opcode enable signal.
    en_update   : in std_logic;                       --! Count update enable signal. 
    en_create   : in std_logic;                       --! Codeword creation enable signal.
    en_bitpack    : in std_logic;                       --! Bitpack enable signal.
    buff_out    : out std_logic_vector (W_BUFFER-1 downto 0);       --! Output word (With compressed sample/s).
    buff_full   : out std_logic;                      --! Output word validation.
    t_opcode    : out std_logic_vector (W_ADDR_IN_IMAGE*2-1 downto 0);    --! t coordinate.
    z_opcode    : out std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);    --! z coordinate.
    opcode      : out std_logic_vector (4 downto 0);            --! Code indicating the relative position of a sample in the spatial. 
    
    -- Sample FIFO Interface
    r_update_curr : in std_logic;                 --! Read request from the samples FIFO.
    clear_curr    : in std_logic;                 --! Clear request.    
    empty_curr    : out std_logic;                --! Samples FIFo is empty.
    aempty_curr   : out std_logic                 --! Samples FIFo is almost empty.
    
    );
end sample_comp;

--! @brief Architecture of sample_comp Components to perform the encoding under the sample adaptive approach
architecture arch of sample_comp is

  -- Accumulator and counter signals
  signal acc    : std_logic_vector(W_ACC-1 downto 0);
  signal count  : std_logic_vector (W_COUNT - 1 downto 0);

  -- Codeword creation
  signal codeword : std_logic_vector (W_BUFFER_GEN-1 downto 0);
  signal n_bits : std_logic_vector (W_NBITS-1 downto 0);
  
  -- Opcode 
  signal opcode_tmp : std_logic_vector (4 downto 0);
  signal t      : std_logic_vector (W_T-1 downto 0);
  signal z      : std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);
  
  -- Bitpack signals
  signal en_bitpack_resolved  : std_logic;
  signal flag_pack_header   : std_logic;
  
  -- Samples FIFO signals
  signal full_curr  : std_logic;
  signal afull_curr : std_logic;
  signal hfull_curr : std_logic;
  signal mapped   : std_logic_vector(DRANGE-1 downto 0);
  
  -- edac signals
  signal edac_double_error_out  : std_logic;
  signal edac_double_error_reg  : std_logic;
  signal edac_double_error_curr : std_logic;
  signal edac_double_error_count  : std_logic;
  
begin

  ---------------------
  --! Output assignments
  ---------------------
  sample_ready <= not hfull_curr and config_valid; 
  opcode <= opcode_tmp;
  t_opcode <= t;
  z_opcode <= z;

  ------------------------------------
  --! Data Output Interface assignments 
  --! @brief Activates the packing when the FSM tells us to do so or when there is a valid header
  ------------------------------------
  en_bitpack_resolved <= en_bitpack or is_header_in when config_image.DISABLE_HEADER(0) = '0' else en_bitpack;
  flag_pack_header <= is_header_in when  config_image.DISABLE_HEADER(0) = '0' else '0';
  
  ------------------------------------
  --! Output assignments for EDAC
  ------------------------------------
  edac_double_error_out <= edac_double_error_curr or edac_double_error_count;
  
  ------------------------------------
  --! Register for EDAC double error
  ------------------------------------
  reg_edac_error: entity shyloc_123.ff1bit(arch)
    generic map (RESET_TYPE => RESET_TYPE) 
    port map (rst_n => rst_n, clk => clk, clear => clear, din => edac_double_error_out, dout => edac_double_error_reg);
  edac_double_error <= edac_double_error_reg;
  --pragma translate_off
  assert edac_double_error_reg = '0' report "SAMPLE EDAC double error detected - compressor should stop now" severity warning;
  --pragma translate_on
  
  -----------------------------
  --!@brief Neighbour CURR FIFO
  -----------------------------
  	-- EDAC here disabled, this FIFO is expected to be
    -- implemented by FFs instead of BRAM due to limited size.
    -- assign EDAC => EDAC if you wish generic parameter value to 
    -- be passed.
    -- Check your synthesis results to ensure no BRAM is used, otherwise
    -- enable edac by assigning EDAC => EDAC
  fifo_curr: entity shyloc_utils.fifop2(arch)
  generic map (
    RESET_TYPE => RESET_TYPE,
    W => W_CURR_SAMPLE,
    NE => NE_CURR_SAMPLE,
    W_ADDR => W_ADDR_CURR_SAMPLE, 
    EDAC => 0,
    TECH => TECH) 
  port map (
    clk => clk,
    rst_n => rst_n,
    clr => clear,
    w_update => data_in_valid,
    r_update => r_update_curr,
    data_in => data_in, 
    data_out => mapped, 
    empty => empty_curr,
    hfull => hfull_curr, 
    full => full_curr,
    afull => afull_curr,
    aempty => aempty_curr, 
    edac_double_error => edac_double_error_curr);
  
  -------------------------------
  --!@brief Opcode update for BIP 
  -------------------------------
  gen_bip: if PREDICTION_TYPE = 0 or PREDICTION_TYPE = 1 generate 
    opcode_update: entity shyloc_123.opcode_update(bip_arch)
    generic map(RESET_TYPE => RESET_TYPE,
      Nx => Nx_GEN,
      Ny => Ny_GEN, 
      Nz => Nz_GEN, 
      W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
      W_T => W_T
    )
    port map(
      clk => clk, 
      rst_n => rst_n,
      en => en_opcode, 
      clear => clear, 
      config_image => config_image,
      z => z, 
      t => t, 
      opcode => opcode_tmp
    );

    ----------------------------------------------
    --!@brief Update accumulator and counter (BIP)
    ----------------------------------------------
    update_counters: entity shyloc_123.count_updatev2(arch_bip)
      generic map(
        INIT_COUNT_E => INIT_COUNT_E_GEN, 
        W_MAP => W_MAP,  
        ACC_INIT_CONST => ACC_INIT_CONST_GEN, 
        RESC_COUNT_SIZE => RESC_COUNT_SIZE_GEN,
        W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
        W_T => W_T,
        W_ACC => W_ACC,
        W_COUNT => W_COUNT)
      port map (
        clk => clk,
        rst_n => rst_n,
        t => t, --not sure if this is correct
        z => z,
        clear => clear, 
        config_image => config_image, 
        config_sample => config_sample,
        opcode => opcode_tmp,
        mapped_prev => mapped, 
        en => en_update, 
        edac_double_error => edac_double_error_count,
        acc => acc,
        count => count);
  end generate gen_bip;
  
  -------------------------------
  --!@brief Opcode update for BSQ
  -------------------------------
  gen_bsq: if PREDICTION_TYPE = 2 generate 
    opcode_update: entity shyloc_123.opcode_update(bsq_arch)
    generic map(
      RESET_TYPE => RESET_TYPE,
      Nx => Nx_GEN,
      Ny => Ny_GEN, 
      Nz => Nz_GEN, 
      W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
      W_T => W_T
    )
    port map(
      clk => clk, 
      rst_n => rst_n,
      en => en_opcode, 
      clear => clear, 
      config_image => config_image,
      z => z, 
      t => t, 
      opcode => opcode_tmp
    );

    ----------------------------------------------
    --!@brief Update accumulator and counter (BSQ)
    ----------------------------------------------
    update_counters: entity shyloc_123.count_updatev2(arch)
      generic map(
        INIT_COUNT_E => INIT_COUNT_E_GEN, 
        W_MAP => W_MAP,  
        ACC_INIT_CONST => ACC_INIT_CONST_GEN, 
        RESC_COUNT_SIZE => RESC_COUNT_SIZE_GEN,
        W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
        W_T => W_T,
        W_ACC => W_ACC,
        W_COUNT => W_COUNT)
      port map (
        clk => clk,
        rst_n => rst_n,
        t => t, --not sure if this is correct
        z => z,
        clear => clear, 
        config_image => config_image, 
        config_sample => config_sample,
        opcode => opcode_tmp,
        mapped_prev => mapped, 
        en => en_update, 
        edac_double_error => edac_double_error_count,
        acc => acc,
        count => count);
  end generate gen_bsq;
  
  
  -------------------------------
  --!@brief Opcode update for BIL
  -------------------------------
  -- Modified by AS: PREDICTION_TYPE = 4 (BIL-MEM) included
  gen_bil: if ((PREDICTION_TYPE = 3) or (PREDICTION_TYPE = 4)) generate 
    opcode_update: entity shyloc_123.opcode_update(bil_arch)
    generic map(
      RESET_TYPE => RESET_TYPE,
      Nx => Nx_GEN,
      Ny => Ny_GEN, 
      Nz => Nz_GEN, 
      W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
      W_T => W_T
    )
    port map(
      clk => clk, 
      rst_n => rst_n,
      en => en_opcode, 
      clear => clear, 
      config_image => config_image,
      z => z, 
      t => t, 
      opcode => opcode_tmp
    );

    ----------------------------------------------
    --!@brief Update accumulator and counter (BIL)
    ----------------------------------------------
    update_counters: entity shyloc_123.count_updatev2(arch_bil)
      generic map(
        INIT_COUNT_E => INIT_COUNT_E_GEN, 
        W_MAP => W_MAP,  
        ACC_INIT_CONST => ACC_INIT_CONST_GEN, 
        RESC_COUNT_SIZE => RESC_COUNT_SIZE_GEN,
        W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
        W_T => W_T,
        W_ACC => W_ACC,
        W_COUNT => W_COUNT)
      port map (
        clk => clk,
        rst_n => rst_n,
        t => t, --not sure if this is correct
        z => z,
        clear => clear, 
        config_image => config_image, 
        config_sample => config_sample,
        opcode => opcode_tmp,
        mapped_prev => mapped, 
        en => en_update, 
        edac_double_error => edac_double_error_count,
        acc => acc,
        count => count);
  end generate gen_bil;
    
  -------------------------
  --!@brief Create codeword
  -------------------------
  createcdw: entity shyloc_123.create_cdwv2(arch)
    generic map  (
      W_ACC => W_ACC,
      W_COUNT => W_COUNT,
      DRANGE => D_GEN,
      W_MAX_CDW => W_MAX_CDW, 
      W_MAP => W_MAP,
      U_MAX => U_MAX_GEN, 
      W_NBITS => W_NBITS,
      W_T => W_T) 
    port map(
      clk => clk,
      rst_n => rst_n,
      clear => clear, 
      config_image => config_image, 
      config_sample => config_sample,
      en => en_create,
      t => t, --t is only used to know if it's the first sample
      --could be replaced by opcode!
      acc => acc,
      count => count,
      mapped => mapped,
      n_bits => n_bits,
      codeword => codeword);
    
    ---------------
    --!@Bit packing
    ---------------
    bit_pack: entity shyloc_123.packing_top_123(arch)
      generic map (
        W_BUFFER => W_BUFFER_GEN,
        W_NBITS => W_NBITS)
      port map (
        clk => clk,
        rst_n => rst_n,
        en => en_bitpack_resolved,
        clear => clear, 
        config_image => config_image,
        config_valid => config_valid,
        flush => flush,
        flag_pack_header => flag_pack_header,
        header => header,
        n_bits_header => n_bits_header,
        n_bits_in => n_bits,
        codeword_in => codeword,
        buff_out => buff_out, 
        buff_full => buff_full);
end arch;
