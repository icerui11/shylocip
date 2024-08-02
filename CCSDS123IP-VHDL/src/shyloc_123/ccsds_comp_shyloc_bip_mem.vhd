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
-- Design unit  : CCSDS123 components BIP-MEM predictor
--
-- File name    : ccsds_comp_shyloc_bip_mem.vhd
--
-- Purpose      : Binds the components of the CCSDS123 predictor
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
-- Instantiates: 
--============================================================================
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>-

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
library shyloc_123; 
use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;    

library shyloc_utils;
use shyloc_utils.amba.all;
use shyloc_123.ccsds_ahb_types.all;

--!@file #ccsds_comp_shyloc_bip_mem.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Makes the connections between the different modules of the CCSDS compressor,
--! architecture bip-mem


entity ccsds_comp_shyloc_bip_mem is
  generic (DRANGE: integer := 16;       --! Dynamic range of the input samples
      -- W_ADDR_BANK: integer := 2;     --! Bit width of the address signal in the register banks.
       W_ADDR_IN_IMAGE: integer := 16;  --! Bit width of the image coordinates (x, y, z)
       HMINDEX_123 : integer := 1;    --! AHB master index
       W_BUFFER: integer := 64;     --! Bit width of the output buffer.
       RESET_TYPE: integer:= 1      --! Reset flavour (0) asynchronous (1) 
      );
  port (
    clk: in std_logic;                        --! Clock signal.
    rst_n: in std_logic;                      --! Reset signal. Active low.
    
    --Input sample FIFO
    w_update_curr: in std_logic;                  --! Write enable in the CURR FIFO.  Active high.
    r_update_curr: in std_logic;                  --! Read enable in the CURR FIFO. Active high.
    
    -- Neighbour FIFOs
    w_update_top: in std_logic;                   --! Write enable in the TOP FIFO. Active high.
    r_update_top: in std_logic;                   --! Read enable in the TOP FIFO. Active high. 
    
    w_update_top_left: in std_logic;                --! Write enable in the TOP LEFT FIFO. Active high. 
    r_update_top_left: in std_logic;                --! Read enable in the TOP LEFT FIFO. Active high.
    
    w_update_top_right_ahbo: in std_logic;              --! Write enable in the TOP RIGHT FIFO. Active high. 
                                    --! Write enable in the TOP RIGHT FIFO. Active high. 
    r_update_top_right_ahbi: in std_logic;              --! Read enable in the TOP RIGHT FIFO. Active high.
    
    w_update_left: in std_logic;                  --! Write enable in the LEFT FIFO.  Active high.
    r_update_left: in std_logic;                  --! Read enable in the LEFT FIFO. Active high.
    
    s: in std_logic_vector (DRANGE-1 downto 0);           --! Current sample to be compressed, s(x, y, z) - Input to CURR FIFO
    en_opcode: in std_logic;                    --! Enable opcode
    
    s_out: out std_logic_vector (DRANGE-1 downto 0);        --! Current sample to be compressed, s(x, y, z) - Read from CURR FIFO sent to FSM
    s_in_left: in std_logic_vector (DRANGE-1 downto 0);       --! Sample to be stored in LEFT FIFO. Comes from FSM.
    s_in_top_right: in std_logic_vector (DRANGE-1 downto 0);    --! Sample to be stored in TOP RIGHT FIFO. Comes from FSM.
    
    opcode: out std_logic_vector(4 downto 0);           --! Opcode to know the relative positon of a sample.
    en_localsum: in std_logic;                    --! Enable signal for local sum module. Active high.
    opcode_localsum: in std_logic_vector (4 downto 0);        --! Opcode read by localsum module.
    z_opcode: out std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);  --! z from opcode, just to control it arrives correctly to localsum
    z_ls: in std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);     --! z input to localsum
    t_opcode: out std_logic_vector (W_T-1 downto 0);        --! t coordinate output of opcode to be sent to FSM
    t_ls: in std_logic_vector (W_T-1 downto 0);           --! t coordinate input to ls module
    ls_out: out std_logic_vector (DRANGE+2 downto 0);       --! Local sum
    
    en_localdiff: in std_logic;                   --! Enable localdiff computation. 
    s_in_localdiff: in std_logic_vector (DRANGE-1 downto 0);    --! Current sample - Input of localdiff module
    ld_out: out std_logic_vector(W_LD-1 downto 0);          --! Central local diff value.
    
    en_localdiff_shift: in std_logic;               --! Activates the shift of the localdiff vector.  
    sign: in std_logic;                       --! Input data are signed (1) or unsigned (0).
  
    finished: out std_logic;                    --! Finished flag, activated when all residuals have been produced.
    config_valid: in std_logic;                   --! Validates the configuration. 
    config_image : in config_123_image;               --! Image metadata configuration values
    config_predictor: in config_123_predictor;            --! Predictor configuration values
    clear : in std_logic;                     --! Synchronous clear to reset all registers. 
    
    --Current FIFO
    empty_curr: out std_logic;                    --! CURR FIFO flag empty.               
    aempty_curr: out std_logic;                   --! CURR FIFO flag almost empty.
    full_curr: out std_logic;                   --! CURR FIFO flag full. 
    afull_curr: out std_logic;                    --! CURR FIFO flag almost full.
    clear_curr: in std_logic;                   --! Clear input to FIFOs
    
    -- AHB FIFOs (store the top right neighbours)
    full_top_right_ahbo: out std_logic;               --! TOP RIGHT FIFO flag full.   
    empty_top_right_ahbi: out std_logic;              --! TOP RIGHT FIFO flag empty.
    full_top_right_ahbi: out std_logic;               --! TOP RIGHT FIFO flag full. 
    
    -- AHB related signals
    clk_ahb: in std_logic;                      --! AHB clock
    rst_ahb: in std_logic;                      --! AHB reset
    ahbmi: in ahb_mst_in_type;                    --! AHB input
    ahbmo: out ahb_mst_out_type;                  --! AHB output
    ahbm_status: out ahbm_123_status;               --! AHB status
    config_ahbm: in config_123_ahbm;                --! Compressor configuration values needed by AHB master
    
    fifo_full_pred: out std_logic;                  --! Signals that there was an attempt to write in a full FIFO.
    pred_edac_double_error: out std_logic;              --! EDAC double error.
    mapped : out std_logic_vector(DRANGE-1 downto 0);       --! Mapped prediction residual to be encoded
    mapped_valid : out std_logic                  --! Validates the mapped prediction residual for 1 clk. 
    
    );
end ccsds_comp_shyloc_bip_mem;

architecture arch_bip_mem of ccsds_comp_shyloc_bip_mem is

  --Output from FIFO left
  signal s_left: std_logic_vector(DRANGE-1 downto 0);
  --Output from FIFO TOP
  signal s_top: std_logic_vector(DRANGE-1 downto 0);
  --Output from FIFO TOP LEFT
  signal s_top_left: std_logic_vector(DRANGE-1 downto 0);
  --Output from FIFO TOP RIGHT
  signal s_top_right: std_logic_vector(DRANGE-1 downto 0);
  -- Output from FIFO CURR
  signal s_curr: std_logic_vector(DRANGE-1 downto 0);
  --Opcode value used by localdiff
  signal  opcode_ld     :       std_logic_vector(4 downto 0);
  -- Left neighbour used by localdiff
  signal  s_left_ld   :       std_logic_vector(DRANGE-1 downto 0);
  -- Top neighbour used by localdiff  
  signal  s_top_ld    :       std_logic_vector(DRANGE-1 downto 0);
  -- Top left neighbour used by localdiff 
  signal  s_top_left_ld :       std_logic_vector(DRANGE-1 downto 0);    
  
  --Top right FIFO received from AHB interface
  signal s_top_right_from_ahbi: std_logic_vector(DRANGE-1 downto 0);
  --Localsum value
  signal ls: std_logic_vector(W_LS-1 downto 0);
    
  -- Variable part of smax, smin and smid. 
  signal smax_var, smid_var, smin_var: std_logic_vector (1 downto 0);  
  
  --  signal s_signed: std_logic_vector (W_S_SIGNED-1 downto  0);
  --Ouput from opcode, to be sent to the output
  signal opcode_tmp: std_logic_vector(4 downto 0);
  -- Coordinate 'z' in different moments
  --  : output from opcode; input to localdiff shift, input to predictor, input to rho, input to mapped
  signal z, z_ld, z_predict, z_predictor, z_mapped, z_rho: std_logic_vector (W_ADDR_IN_IMAGE -1 downto 0);
  -- Coordinate 't' in different moments
  --  : output from opcode; input to rho
  signal t, t_rho: std_logic_vector(W_T-1 downto 0);
  --Central and directional localdiffs
  signal ld, ld_n, ld_w, ld_nw: std_logic_vector(W_LD-1 downto 0);
  -- Vector of central local differences
  signal ld_vector_central: ld_array_type(0 to P_MAX-1);
  -- Vector of localdifferences; vector of local differences used during the weight update
  signal ld_vector, ld_vector_to_update: ld_array_type(0 to Cz-1);
  -- Custom weight vector (not used), updated weight (output of weight update module), 
  -- updated weight (input to dot product), weight vector (input to weight update), 
  signal custom_wei_vector, wei_vector, updated_weight, wei_vector_updated, wei_vector_to_update:  wei_array_type (0 to Cz-1);
  -- Result of the dot product to be used by the predictor and valid
  signal result_dot: std_logic_vector(W_DZ-1 downto 0);
  signal valid_dot: std_logic;
  signal s_scaled : std_logic_vector (W_SCALED-1 downto 0); 
  --Sample to be compressed: output from localdiff, input to predictor, input to mapped
  signal s_predict, s_predictor, s_mapped: std_logic_vector (W_S_SIGNED-1 downto 0);
  --Localsum: output from localdiff, input to predictor
  signal ls_predict, ls_predictor : std_logic_vector (W_LS-1 downto 0);
  --Opcode: output from localdiff, input to predictor, input to rho, input to weight update
  signal opcode_predict, opcode_predictor, opcode_ro, opcode_weight, opcode_mapped: std_logic_vector(4 downto 0);
  -- Enable rho, enable weight update
  signal en_rho_update, en_update: std_logic;
  --Validates a the output of the predictor for one clk.
  signal valid_predictor: std_logic;
  -- Rho value (input to weight update)
  signal ro: std_logic_vector(W_RO - 1 downto 0);
  --Write and read enable of intermediate storage of ld vectors
  signal w_update_fifo_ld, r_update_fifo_ld: std_logic;
  --Write and read enable of intermediate storage of weight vector
  signal w_update_fifo_wei_tmp, r_update_fifo_wei_tmp, r_update_fifo_wei_update: std_logic;
  --Enable weight initialization
  signal en_init_weight: std_logic;
  --Validates the output of the weight update module for one clk.
  signal valid_weight_update: std_logic;
  
  -- Sample to be stored in AHB fifos. Correspond to top_right neighbours
  signal s_top_right_ahbi, s_top_right_ahbo: std_logic_vector(31 downto 0);
  signal s_top_right_tmp, s_in_top_right_tmp: std_logic_vector(31 downto 0);
  --Flags to signal that the AHB fifos are empty/full
  signal empty_top_right_ahbo: std_logic;
  --Read from AHB fifo, write to AHB fifo. 
  signal r_update_top_right_ahbo, w_update_top_right_ahbi: std_logic;
  signal full_top_right_ahbi_out: std_logic;  
  --Control signal for AHB module
  signal ctrl_ahbm1: ahbtb_ctrl_type;
  signal done: std_logic;
  --Resolved smin and smax values.
  signal smin, smax: std_logic_vector(W_SMAX -1 downto 0);
  signal clear_current_fifo: std_logic;
  --Validates output from localdiff shift for one clk. 
  signal valid_localdiff_shift: std_logic;
  --Half full flags for AHB fifo
  signal hfull_top_righ_ahbi: std_logic;
  --FIFOs full flags.
  signal full_curr_out, full_left, full_top_left, full_top, full_ld_to_update, full_wei_vector_to_update, full_wei_vector_updated, fifo_full_pred_out: std_logic;
  
  constant N_FIFOS : integer := 6;
  signal edac_double_error_vector: std_logic_vector (0 to N_FIFOS);
  signal edac_double_error_vector_tmp: std_logic_vector (0 to N_FIFOS+1);
  signal edac_double_error_out, edac_double_error_reg: std_logic;
  
begin
  ----------------------------------------------------------------------------- 
  -- Output assignments
  -----------------------------------------------------------------------------
  opcode <= opcode_tmp;
  ls_out <= ls;
  s_out <= s_curr;
  ld_out <= ld;
  full_top_right_ahbi <= full_top_right_ahbi_out;
  z_opcode <= z;
  full_curr <= full_curr_out;
  
  -- Output assignments for EDAC
  edac_double_error_vector_tmp(0) <= '0';
  gen_edac_error: for j in 0 to N_FIFOS generate
    edac_double_error_vector_tmp(j+1) <= edac_double_error_vector_tmp(j) or edac_double_error_vector(j); 
  end generate gen_edac_error;
  edac_double_error_out <= edac_double_error_vector_tmp(N_FIFOS+1);
  -- Register EDAC error
  reg_edac_error: entity shyloc_123.ff1bit(arch)
    generic map (RESET_TYPE => RESET_TYPE) 
    port map (rst_n => rst_n, clk => clk, clear => clear, din => edac_double_error_out, dout => edac_double_error_reg);
  pred_edac_double_error <= edac_double_error_reg;
  --pragma translate_off
  assert edac_double_error_reg = '0' report "BIP-MEM: EDAC double error detected - compressor should stop now" severity warning;
  --pragma translate_on
  
  -- Generate FIFO_Full Flag
  fifo_full_pred_out <= '1' when full_curr_out = '1' and w_update_curr = '1'else '0';
  fifo_full_pred <=  fifo_full_pred_out;
  --pragma translate_off
  assert fifo_full_pred_out = '0' report "Input FIFO is full, possible loss of data - compressor should stop now." severity warning;
  --pragma translate_on
  
  ----------------------------------------------------------------------------- 
  -- Calculate smax, smin, smid
  -----------------------------------------------------------------------------
  with sign select
    smax_var(smax_var'high  downto 0) <= (others => '0') when '1',
                       "01" when '0', 
                       (others => '0') when others;

  with sign select
    smid_var(smid_var'high downto 0) <= (others => '0') when '1',
                      "01"          when '0', 
                      (others => '0') when others;

  with sign select   
    smin_var(smin_var'high downto 0) <= "11"  when '1',
                    (others => '0') when '0', 
                    (others => '0') when others;

  clear_current_fifo <= clear_curr or clear;
  
  ----------------------------------------------------------------------------- 
  --!@brief CURR FIFO
  -----------------------------------------------------------------------------
  	-- EDAC here disabled, this FIFO is expected to be
    -- implemented by FFs instead of BRAM due to limited size.
    -- assign EDAC => EDAC if you wish generic parameter value to 
    -- be passed.
    -- Check your synthesis results to ensure no BRAM is used, otherwise
    -- enable edac by assigning EDAC => EDAC
  fifo_0_curr: entity shyloc_utils.fifop2(arch)
  generic map (
    RESET_TYPE => RESET_TYPE,
    W => W,
    NE => NE_CURR,
    W_ADDR => W_ADDR_CURR, EDAC => 0, TECH => TECH) 
  port map (
    clk => clk,
    rst_n => rst_n,
    clr => clear_current_fifo,
    w_update => w_update_curr,
    r_update => r_update_curr,
    data_in => s, 
    data_out => s_curr, 
    empty => empty_curr,
    full => full_curr_out,
    afull => afull_curr,
    aempty => aempty_curr, 
    edac_double_error => edac_double_error_vector(0)
    );
    
  -----------------------------------------------------------------------------   
  --!@brief Neighbour LEFT FIFO.
  ----------------------------------------------------------------------------- 
  fifo_1_left: entity shyloc_utils.fifop2(arch)
  generic map (
    RESET_TYPE => RESET_TYPE,
    W => W,
    NE => NE_LEFT_BIP,
    W_ADDR => W_ADDR_LEFT_BIP, EDAC => EDAC, TECH => TECH) 
  port map (
    clk => clk,
    rst_n => rst_n,
    clr => clear,
    w_update => w_update_left,
    r_update => r_update_left,
    data_in => s_in_left, 
    data_out => s_left, 
    full => full_left, 
    edac_double_error => edac_double_error_vector(1)
    );
  
  ----------------------------------------------------------------------------- 
  --!@brief Neighbour TOP FIFO.
  ----------------------------------------------------------------------------- 
  fifo_2_top: entity shyloc_utils.fifop2(arch)
    generic map (
      RESET_TYPE => RESET_TYPE,
      W => W,
      NE => NE_TOP_BIP,
      W_ADDR => W_ADDR_TOP_BIP, EDAC => EDAC, TECH => TECH)  
    port map (
      clk => clk,
      rst_n => rst_n,
      clr => clear,
      w_update => w_update_top,
      r_update => r_update_top,
      data_in => s_top_right,
      data_out => s_top, 
      full => full_top, 
      edac_double_error => edac_double_error_vector(2)
      );
      
  ----------------------------------------------------------------------------- 
  --!@brief Neighbour TOP LEFT FIFO.  
  ----------------------------------------------------------------------------- 
  fifo_3_top_left: entity shyloc_utils.fifop2(arch)
    generic map (
      RESET_TYPE => RESET_TYPE,
      W => W,
      NE => NE_TOP_LEFT_BIP,
      W_ADDR => W_ADDR_TOP_LEFT_BIP, EDAC => EDAC, TECH => TECH)  
    port map (
      clk => clk,
      rst_n => rst_n,
      clr => clear,
      w_update => w_update_top_left,
      r_update => r_update_top_left,
      data_in => s_top,
      data_out => s_top_left, 
      full => full_top_left, 
      edac_double_error => edac_double_error_vector(3)
      );
      
  -- Resize to 32 bits, input to AHB FIFO
  s_in_top_right_tmp <= std_logic_vector(resize(unsigned(s_in_top_right), s_in_top_right_tmp'length));
  
  
  ----------------------------------------------------------------------------- 
  --!@brief Neighbour TOP RIGHT FIFO -- to interface with AHB
  ----------------------------------------------------------------------------- 
  fifo_top_right_to_ahb: entity shyloc_123.async_fifo(arch)
      generic map(
        W => 32,
        NE => NE_AHB_FIFO_BIP,
        RESET_TYPE => RESET_TYPE,
        TECH => TECH
      )
      port map (
        clkw => clk, 
        resetw => rst_n, 
        async_clr => clear,
        wr => w_update_top_right_ahbo, 
        full => full_top_right_ahbo, 
        data_in => s_in_top_right_tmp, 
        data_out => s_top_right_ahbo, 
        clkr => clk_ahb, 
        resetr => rst_ahb, 
        rd => r_update_top_right_ahbo,
        empty => empty_top_right_ahbo
      );  
  
  ----------------------------------------------------------------------------- 
  --!@brief Control for AHB master interface (reads/writes from FIFOs and
  --! generates data/control signals
  ----------------------------------------------------------------------------- 
  ahbmemio: entity shyloc_123.ahbtbm_ctrl_bi(arch_shyloc)
    generic map  (W => 32)
    port map (
      rst_ahb   => rst_ahb,
      clk_ahb  => clk_ahb, 
      
      rst_s   => rst_n,
      clk_s  => clk, 
      clear_s => clear,
      config_valid_s => config_valid, 
      config_ahbm => config_ahbm, 
      ahbm_status => ahbm_status, 
      config_image_s => config_image, 
      config_predictor_s => config_predictor,
      --input FIFO
      data_out_in => s_top_right_ahbo, 
      rd_in => r_update_top_right_ahbo, 
      empty_in => empty_top_right_ahbo,
    
      --output FIFO
      data_in_out => s_top_right_ahbi, 
      wr_out => w_update_top_right_ahbi, 
      full_out => full_top_right_ahbi_out, 
      hfull_out => hfull_top_righ_ahbi,
    
      done => done, 
      ctrli => ctrl_ahbm1.i, --to ahbtbm1
      ctrlo => ctrl_ahbm1.o
    );
  
  ----------------------------------------------------------------------------- 
  --!@brief AHB master interface
  ----------------------------------------------------------------------------- 
  ahbmctrl: entity shyloc_123.ccsds123_ahb_mst(rtl)
  port map(rst_ahb, clk_ahb, ctrl_ahbm1.i, ctrl_ahbm1.o, ahbmi, ahbmo);
  
  ----------------------------------------------------------------------------- 
  --!@brief Neighbour TOP RIGHT FIFO -- values read from AHB master interface
  ----------------------------------------------------------------------------- 
  fifo_top_right_from_ahb: entity shyloc_123.async_fifo(arch)
    generic map(
      W => 32,
      NE => NE_AHB_FIFO_BIP, 
      DIFFERENCE => DIFFERENCE_AHB_BIP,
      RESET_TYPE => RESET_TYPE,
      TECH => TECH
    )
    port map (
      clkw => clk_ahb, 
      resetw => rst_ahb, 
      async_clr => clear,
      wr => w_update_top_right_ahbi, 
      full => full_top_right_ahbi_out, 
      data_in => s_top_right_ahbi, 
      data_out => s_top_right_tmp, 
      clkr => clk, 
      resetr => rst_n, 
      rd => r_update_top_right_ahbi,
      empty => empty_top_right_ahbi,
      hfull => hfull_top_righ_ahbi
  );
      
  -- Resize to DRANGE bits, to continue
  s_top_right_from_ahbi <= s_top_right_tmp (DRANGE-1 downto 0);
  
  ----------------------------------------------------------------------------- 
  --!@brief Pipeline register: STORAGE OF TOP_RIGHT sample from AHB to send to TOP FIFO
  ----------------------------------------------------------------------------- 
  top_right_out_delay:  entity shyloc_123.shift_ff(arch)
  generic map (N => DRANGE, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => s_top_right_from_ahbi, dout => s_top_right);
  
   
  ----------------------------------------------------------------------------- 
  --!@brief Opcode module: bip_arch architecture
  ----------------------------------------------------------------------------- 
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
    t => t_opcode, 
    opcode => opcode_tmp
  );
  
  -----------------------------------------------------------------------------
  --!@brief LOCAL SUM
  -----------------------------------------------------------------------------
  localsum_core: entity shyloc_123.localsumv2(arch)
  generic map (
      DRANGE => DRANGE,
      LOCAL_SUM_MODE => LOCAL_SUM_GEN,
      W_LS => W_LS)
  port map (
      clk => clk, 
      rst_n => rst_n, 
      sign => sign, 
      en => en_localsum, 
      clear => clear, 
      config_predictor => config_predictor, 
      s_left => s_left, 
      s_top => s_top, 
      s_top_left => s_top_left, 
      s_top_right => s_top_right, 
      opcode_ls => opcode_localsum, 
      ls => ls,
      opcode_ld => opcode_ld,
      s_left_ld => s_left_ld, 
          s_top_ld =>  s_top_ld,
            s_top_left_ld => s_top_left_ld);
  
  ----------------------------------------------------------------------------- 
  --!@brief Register: store z between ls and ld. Output is updated 1 clk after
  --! en_localsum
  ----------------------------------------------------------------------------- 
  -- Modified by AS: shift_ff_en component replaced by simple register with enable (ff_en), as the number of stages is always 1
  z_ls_ld: entity shyloc_123.ff_en(arch)
    generic map (N => W_ADDR_IN_IMAGE, RESET_TYPE => RESET_TYPE)
    port map( rst_n => rst_n, clk => clk, en => en_localsum, clear => clear, din => z_ls, dout => z_ld);
  -- z_ls_ld: entity shyloc_123.shift_ff_en(arch)
    -- generic map (N => W_ADDR_IN_IMAGE, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
    -- port map( rst_n => rst_n, clk => clk, en => en_localsum, clear => clear, din => z_ls, dout => z_ld);

  -----------------------------------------------------------------------------
  --!@brief LOCAL DIFF
  -----------------------------------------------------------------------------
  localdiff_core: entity shyloc_123.localdiffv3(arch_shyloc)
  generic map (
      RESET_TYPE => RESET_TYPE,
      DRANGE => DRANGE,
      PREDICTION_MODE => PREDICTION_GEN,
      W_LS => W_LS,
      W_LD => W_LD)
  port map (
      clk => clk, 
      rst_n => rst_n, 
      sign => sign, 
      en => en_localdiff,
      clear => clear, 
      config_predictor => config_predictor, 
      mode => '0',
      opcode_ld => opcode_ld,
      s => s_in_localdiff, 
      s_left => s_left_ld, 
      s_top => s_top_ld, 
      s_top_left => s_top_left_ld,
      ls => ls,         
      ld => ld, 
      ld_n  => ld_n, 
      ld_w  => ld_w,
      ld_nw  => ld_nw,
      s_predict => s_predict, 
      opcode_predict => opcode_predict,
      ls_predict => ls_predict
      );
      
  -----------------------------------------------------------------------------
  --!@brief generation of localdiff vector for full prediction
  -----------------------------------------------------------------------------
  gen_vector_full: if PREDICTION_GEN = 0 generate
    ld_vector(0) <= ld_n;
    ld_vector(1) <= ld_w;
    ld_vector(2) <= ld_nw;
    gen_central_condition: if P_MAX > 0 generate
      gen_central: for i in 3 to Cz-1 generate
        ld_vector(i) <= ld_vector_central(i-3);
      end generate gen_central;
    end generate gen_central_condition;
  end generate gen_vector_full;
    
  -----------------------------------------------------------------------------
  --!@brief generation of localdiff vector for reduced prediction
  -----------------------------------------------------------------------------   
  gen_vector_reduced: if PREDICTION_GEN = 1 generate
    gen_central_condition: if P_MAX > 0 generate
      gen_central: for i in 0 to Cz-1 generate
        ld_vector(i) <= ld_vector_central(i);
      end generate gen_central;
    end generate gen_central_condition;
  end generate gen_vector_reduced;
      
  ----------------------------------------------------------------------------- 
  --!@brief Register: store z between ld and prediction. Output is updated 1 clk after
  --! en_localdiff
  ----------------------------------------------------------------------------- 
  -- Modified by AS: shift_ff_en component replaced by simple register with enable (ff_en), as the number of stages is always 1
  z_ld_pred:entity shyloc_123.ff_en(arch)
    generic map (N => W_ADDR_IN_IMAGE, RESET_TYPE => RESET_TYPE)
    port map( rst_n => rst_n, clk => clk, en => en_localdiff, clear => clear, din => z_ld, dout => z_predict);
  -- z_ld_pred:entity shyloc_123.shift_ff_en(arch)
    -- generic map (N => W_ADDR_IN_IMAGE, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
    -- port map( rst_n => rst_n, clk => clk, en => en_localdiff, clear => clear, din => z_ld, dout => z_predict);
    
  -----------------------------------------------------------------------------
  --!@brief Shift localdiff vector for each sample if P_MAX > 0
  ----------------------------------------------------------------------------- 
  gen_localdiff_shift: if P_MAX > 0 generate
    localdiff_shift_core: entity shyloc_123.localdiff_shift(arch)
    generic map(
      NBP => P_MAX,
      W_LD => W_LD, 
      W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE,
      RESET_TYPE => RESET_TYPE
    )
    port map(
      clk => clk, 
      rst_n => rst_n,
      en => en_localdiff_shift, 
      z => z_predict,
      config_image => config_image,
      clear => clear,
      config_predictor => config_predictor, 
      ld  => ld, 
      ld_vector => ld_vector_central --!Array of local differences
    );
  end generate gen_localdiff_shift;

  -----------------------------------------------------------------------------
  --!@brief DOT PRODUCT -- multipliers + adders tree when Cz > 0
  -----------------------------------------------------------------------------
  gen_dot_product: if Cz > 0 generate
    dot_product_core: entity shyloc_123.mult_acc_shyloc(arch)
    generic map(
      Cz    =>  Cz, 
      W_LD  =>  W_LD, 
      W_WEI =>  W_WEI, 
      W_RES =>  W_DZ,
      RESET_TYPE => RESET_TYPE
    )
    port map(
      clk => clk, 
      rst_n => rst_n, 
      en => en_localdiff_shift, --not sure if this will always be like this or i'll need the signal at the control
      clear => clear,
      result => result_dot, 
      valid => valid_dot,
      ld_vector => ld_vector,
      wei_vector => wei_vector_updated
    );
  end generate gen_dot_product;
  
  -----------------------------------------------------------------------------
  --!@brief DOT PRODUCT -- forced to zero when Cz = 0 
  -----------------------------------------------------------------------------
  gen_dot_product_cz0: if Cz = 0 generate
    valid_dot_cz0_st1: entity shyloc_123.ff1bit(arch)
      generic map (RESET_TYPE => RESET_TYPE)
      port map (rst_n => rst_n, clk => clk, clear => clear, din => en_localdiff_shift, dout => valid_localdiff_shift);
    valid_dot_cz0_st2: entity shyloc_123.ff1bit(arch)
      generic map (RESET_TYPE => RESET_TYPE)
      port map (rst_n => rst_n, clk => clk, clear => clear, din => valid_localdiff_shift, dout => valid_dot);
    result_dot <= (others => '0');
  end generate gen_dot_product_cz0;
  

  -- Write ld vector in FIFO when there's a valid localdiff_vector
  -- Note that for first sample in each band the vector is not needed
  w_update_fifo_ld <= en_localdiff_shift;
  w_update_fifo_wei_tmp <= en_localdiff_shift;
  
  -- Only read from the FIFO when needed, before performing the dot product
  r_update_fifo_wei_update <= '1' when en_localdiff = '1' and opcode_ld(3 downto 0) /= "0000" else '0';
  
  -----------------------------------------------------------------------------
  -- Generate ld and weight vectors storge when Cz > 0; otherwise they are not needed
  -----------------------------------------------------------------------------
  
  gen_vectors_temp_storage: if Cz > 0 generate
    -----------------------------------------------------------------------------
    --!@brief Store ld vectors until weight update operation
    -----------------------------------------------------------------------------
	-- EDAC here disabled, this FIFO is expected to be
    -- implemented by FFs instead of BRAM due to limited size.
    -- assign EDAC => EDAC if you wish generic parameter value to 
    -- be passed.
    -- Check your synthesis results to ensure no BRAM is used, otherwise
    -- enable edac by assigning EDAC => EDAC
    fifo_4_ld_vector_temp_storage: entity shyloc_123.ld_2d_fifo(arch)
    generic map(
      Cz => Cz, --number of FIFOs
      W => W_LD, --bit width of the elements
      NE =>NE_DOT_TO_UPDATE_BIP, --number of elements in FIFO, not really used
      W_ADDR => W_ADDR_DOT_TO_UPDATE_BIP,
      RESET_TYPE => RESET_TYPE, EDAC => 0, TECH => TECH
    )
    port map(
      clk => clk,
      rst_n => rst_n,
      clr  => clear,
      w_update  => w_update_fifo_ld,
      r_update => r_update_fifo_ld,
      data_vector_in => ld_vector,
      data_vector_out => ld_vector_to_update, 
      full => full_ld_to_update, 
      edac_double_error => edac_double_error_vector(4)
    );
    
    -----------------------------------------------------------------------------
    --!@brief STORAGE OF LD VECTORS to be used later during update
    -----------------------------------------------------------------------------
	-- EDAC here disabled, this FIFO is expected to be
    -- implemented by FFs instead of BRAM due to limited size.
    -- assign EDAC => EDAC if you wish generic parameter value to 
    -- be passed.
    -- Check your synthesis results to ensure no BRAM is used, otherwise
    -- enable edac by assigning EDAC => EDAC
	-- NOTE: a false EDAC error might be signalled here when EDAC is enabled, 
	-- since trash is stored and read for the first iteration.
    fifo_5_wei_vector_temp_storage: entity shyloc_123.wei_2d_fifo(arch)
    generic map(
      Cz => Cz,
      W => W_WEI,
      NE => NE_DOT_TO_UPDATE_BIP,
      W_ADDR => W_ADDR_DOT_TO_UPDATE_BIP,
      RESET_TYPE => RESET_TYPE, EDAC => 0, TECH => TECH
    )
    port map(
      clk => clk,
      rst_n => rst_n,
      clr  => clear,
      w_update  => w_update_fifo_wei_tmp,
      r_update => r_update_fifo_wei_tmp,
      data_vector_in => wei_vector_updated,
      data_vector_out => wei_vector_to_update, 
      full => full_wei_vector_to_update, 
      edac_double_error => edac_double_error_vector(5)
    );
  end generate gen_vectors_temp_storage;
  
  gen_vectors_temp_no_storage: if Cz = 0 generate
    edac_double_error_vector(4) <= '0';
    edac_double_error_vector(5) <= '0';
  end generate gen_vectors_temp_no_storage;
  
  -----------------------------------------------------------------------------
  --!@brief Pipeline register: LS for predictor -- it is a delay of HEIGHT_TREE + 1 cycles
  -----------------------------------------------------------------------------
  ls_delay: entity shyloc_123.shift_ff(arch)
  generic map (N => W_LS,
       N_STAGES => HEIGHT_TREE + 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => ls_predict, dout => ls_predictor);
  
  -----------------------------------------------------------------------------
  --!@brief Pipeline register: opcode for predictor -- it is a delay of HEIGHT_TREE + 1 cycles
  -----------------------------------------------------------------------------
  opcode_delay: entity shyloc_123.shift_ff(arch)
  generic map (N => 5, N_STAGES => HEIGHT_TREE + 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => opcode_predict, dout => opcode_predictor);
  
  -----------------------------------------------------------------------------
  --!@brief Pipeline register: current sample for predictor -- it is a delay of HEIGHT_TREE + 1 cycles
  -----------------------------------------------------------------------------
  s_delay: entity shyloc_123.shift_ff(arch)
  generic map (N => W_S_SIGNED, N_STAGES => HEIGHT_TREE + 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => s_predict, dout => s_predictor);
  
  -----------------------------------------------------------------------------
  --!@brief Pipeline register: z sample for predictor -- it is a delay of HEIGHT_TREE + 1 cycles
  -----------------------------------------------------------------------------
  z_delay: entity shyloc_123.shift_ff(arch)
  generic map ( N => z'length, 
      N_STAGES => HEIGHT_TREE + 1, --adjust if not correct!!!
      RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => z_predict, dout => z_predictor);
  
  -----------------------------------------------------------------------------
  --!@brief PREDICTOR CORE
  -----------------------------------------------------------------------------
  predictor_core: entity shyloc_123.predictor2stagesv2(arch)
  generic map (RESET_TYPE => RESET_TYPE, OMEGA => OMEGA_GEN, 
       W_S_SIGNED => W_S_SIGNED, 
       R => R_GEN, 
       W_DZ => W_DZ, 
       NBP => P_MAX, 
       W_SCALED => W_SCALED, 
       W_SMAX => W_SMAX, 
       W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, 
       W_LS => W_LS
      )
  port map (
     clk => clk, 
     rst_n => rst_n, 
     opcode => opcode_predictor, 
     config_image => config_image, 
     en => valid_dot, --connecting en_predictor to valid_dot
    clear => clear, 
    config_predictor => config_predictor,
     z => z_predictor, --this is not really needed
     s => s_predictor, 
     smax_var => smax_var, 
     smin_var => smin_var,
     smid_var => smid_var, 
     dz => result_dot, 
     ls => ls_predictor, 
     valid => valid_predictor,
     smin => smin, 
    smax => smax,
     s_mapped => s_mapped,
     s_scaled =>  s_scaled 
  );
  
  -----------------------------------------------------------------------------
  --!@brief Pipeline register: store opcode between predictor and rho 
  -----------------------------------------------------------------------------
  opcode_delay_ro: entity shyloc_123.shift_ff(arch)
  generic map (N => 5, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => opcode_predictor, dout => opcode_ro);
  
  -----------------------------------------------------------------------------
  --!@brief Pipeline register: store "rho enable" between predictor and rho 
  -----------------------------------------------------------------------------
  rho_enable: entity shyloc_123.ff1bit(arch)
  generic map (RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => valid_dot, dout => en_rho_update);

  -----------------------------------------------------------------------------
  --!@brief Pipeline register: store z between predictor and rho 
  -----------------------------------------------------------------------------
  z_delay_pred_rho: entity shyloc_123.shift_ff(arch)
  generic map (N => W_ADDR_IN_IMAGE, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => z_predictor, dout => z_rho);

  -----------------------------------------------------------------------------
  --!@brief Pipeline register: store t between opcode and rho 
  ----------------------------------------------------------------------------- 
  t_delay_ls_rho: entity shyloc_123.shift_ff(arch)
  generic map (N => W_T, N_STAGES => 2 + HEIGHT_TREE + 1 + 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => t_ls, dout => t_rho);

  -----------------------------------------------------------------------------
  --!@brief RHO UPDATE for weight update module
  -----------------------------------------------------------------------------
  ro_core: entity shyloc_123.ro_update_mathv3_diff (arch)
  generic map( 
      RESET_TYPE => RESET_TYPE,
      T_INC => T_INC_GEN,
      W_RO => W_RO,
      W_T => W_T
  )
  port map (
      clk => clk, 
      rst_n => rst_n,
      en => en_rho_update,
      clear => clear, 
      config_image => config_image, 
      config_predictor => config_predictor,
      t => t_rho, 
      ro => ro
  );
  
  -----------------------------------------------------------------------------
  --!@brief Pipeline register: store z between rho and mapped 
  -----------------------------------------------------------------------------
  z_delay_rho_mapped: entity shyloc_123.shift_ff(arch)
  generic map (N => W_ADDR_IN_IMAGE, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => z_rho, dout => z_mapped);
  
  -----------------------------------------------------------------------------
  --!@brief Finished signal generation: one cycle after last mapped residual is issued
  -----------------------------------------------------------------------------
  --CYCLES MAP is (cycles map +1)
  finished_gen_core: entity shyloc_123.finished_gen(arch)
    generic map(CYCLES_MAP  => 3, W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE,  Nz => Nz_GEN, RESET_TYPE => RESET_TYPE)
    port map( rst_n => rst_n, clk => clk, 
      en => valid_predictor, 
      clear => clear, 
      config_image => config_image,
      opcode_mapped => opcode_weight, 
      z_mapped => z_mapped,
      finished => finished);
      
  -----------------------------------------------------------------------------
  --!@brief MAP CORE
  -----------------------------------------------------------------------------
  map_core: entity shyloc_123.map2stagesv2(arch)
  generic map (W_S_SIGNED => W_S_SIGNED,
       W_SCALED => W_SCALED, 
       W_SMAX => W_SMAX,
       W_MAP => W_MAP)
  port map (
    clk => clk, 
    rst_n => rst_n,
    clear => clear,
    en => valid_predictor,
    s_signed => s_mapped,
    smin => smin, 
    smax => smax,
    s_scaled => s_scaled,
    valid => mapped_valid,
    mapped => mapped
  );
  
  -- Read ld vector from FIFOs to be used in weight update.
  --note that for first sample in each band the vector is not needed.
  r_update_fifo_ld <= en_rho_update;
  r_update_fifo_wei_tmp <= en_rho_update;
  
  -----------------------------------------------------------------------------
  --!@brief Pipeline register: opcode between rho and update weight 
  -----------------------------------------------------------------------------
  opcode_delay_weights: entity shyloc_123.shift_ff(arch)
  generic map (N => 5, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => opcode_ro, dout => opcode_weight);
  
  -- Enable update or initialization depending on opcode
  en_init_weight <= valid_predictor when opcode_weight(3 downto 0) = "0000" else '0';
  en_update <= valid_predictor when opcode_weight(3 downto 0) /= "0000" else '0';

  -----------------------------------------------------------------------------
  -- Weight update oprations if Cz > 0
  -----------------------------------------------------------------------------
  gen_wei_update: if Cz > 0 generate
    -----------------------------------------------------------------------------
    --!@brief WEIGHT UPDATE MODULE
    -----------------------------------------------------------------------------
    wei_update_core: entity shyloc_123.weight_update_shyloc_top(arch_bip)
    generic map (
        DRANGE => DRANGE,
        W_WEI => W_WEI,
        W_LD => W_LD,
        W_SCALED => W_SCALED,
        W_RO => W_RO,
        WE_MIN => WE_MIN,
        WE_MAX => WE_MAX,
        MAX_RO => MAX_RO,
        Cz => Cz,
        TABLE => WEIGHT_INIT_GEN,
        PREDICTION_MODE => PREDICTION_GEN,
        OMEGA => OMEGA_GEN, 
        RESET_TYPE => RESET_TYPE
        )
    port map (                                
      clk => clk,
      rst_n => rst_n,
      en_update => en_update,
      en_init => en_init_weight,
      clear => clear, 
      config_valid => config_valid,
      config_predictor => config_predictor, 
      s_signed => s_mapped, -- they are shyloc_123ing in paralell
      s_scaled => s_scaled,
      ld_vector => ld_vector_to_update,
      custom_wei_vector => custom_wei_vector,
      wei_vector => wei_vector_to_update,
      ro => ro, 
      valid => valid_weight_update,
      updated_weight => updated_weight
      );

    -----------------------------------------------------------------------------
    --!@brief STORAGE OF WEIGHT VECTORS to be used in dot product
    -----------------------------------------------------------------------------
    fifo_6_wei_update_storage: entity shyloc_123.wei_2d_fifo(arch)
    generic map (
      Cz => Cz,
      W => W_WEI,
      NE => NE_WEIGHT_UPDATE_BIP,
      W_ADDR => W_ADDR_WEIGHT_UPDATE_BIP,
      RESET_TYPE => RESET_TYPE, EDAC => EDAC, TECH => TECH
    )
    port map(
      clk => clk,
      rst_n => rst_n,
      clr  => clear,
      w_update  => valid_weight_update, -- write when there's a valid weight
      r_update => r_update_fifo_wei_update, -- read when... see on top
      data_vector_in => updated_weight, -- from weight update module
      data_vector_out => wei_vector_updated, -- to dot product module
      full => full_wei_vector_updated, 
      edac_double_error => edac_double_error_vector(6)
    );
  end generate gen_wei_update;
  
  gen_no_wei_update: if Cz = 0 generate
    edac_double_error_vector(6) <= '0';
  end generate gen_no_wei_update; 
end arch_bip_mem;
