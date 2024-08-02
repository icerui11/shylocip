--============================================================================--
-- Design unit  : CCSDS123 components BIL-MEM predictor
--
-- File name    : ccsds_comp_shyloc_bil_mem.vhd
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

--!@file #ccsds_comp_shyloc_bil_mem.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Antonio Sanchez
--!@email ajsanchez@iuma.ulpgc.es
--!@brief Makes the connections between the different modules of the CCSDS compressor,
--! architecture bil-mem

entity ccsds_comp_shyloc_bil_mem is
  generic (DRANGE: integer := 16;        --! Dynamic range of the input samples
      -- W_ADDR_BANK: integer := 2;      --! Bit width of the address signal in the register banks.
       W_ADDR_IN_IMAGE: integer := 16;  --! Bit width of the image coordinates (x, y, z)
       HMINDEX_123 : integer := 1;    --! AHB master index    (only bip-mem)
       W_BUFFER: integer := 64;      --! Bit width of the output buffer.
       RESET_TYPE: integer:= 1      --! Reset flavour (0) asynchronous (1) 
      );
  port (
    clk: in std_logic;                        --! Clock signal.
    rst_n: in std_logic;                      --! Reset signal. Active low.
    
    --Input sample FIFO
    w_update_curr: in std_logic;                   --! Write enable in the CURR FIFO.   Active high.
    r_update_curr: in std_logic;                  --! Read enable in the CURR FIFO. Active high.
    
    -- Neighbour FIFOs
    w_update_top_right_ahbo: in std_logic;              --! Write enable in the TOP RIGHT FIFO. Active high.
    r_update_top_right_ahbi: in std_logic;              --! Read enable in the TOP RIGHT FIFO. Active high.
    
    s: in std_logic_vector (DRANGE-1 downto 0);            --! Current sample to be compressed, s(x, y, z) - Input to CURR FIFO
    en_opcode: in std_logic;                    --! Enable opcode
    
    s_out: out std_logic_vector (DRANGE-1 downto 0);        --! Current sample to be compressed, s(x, y, z) - Read from CURR FIFO sent to FSM
    s_in_left: in std_logic_vector (DRANGE-1 downto 0);        --! Sample to be stored in LEFT FIFO. Comes from FSM.
    s_in_top_right: in std_logic_vector (DRANGE-1 downto 0);    --! Sample to be stored in TOP RIGHT FIFO. Comes from FSM.
    
    opcode: out std_logic_vector(4 downto 0);            --! Opcode to know the relative positon of a sample.
    en_localsum: in std_logic;                    --! Enable signal for local sum module. Active high.
    opcode_localsum: in std_logic_vector (4 downto 0);        --! Opcode read by localsum module.
    z_opcode: out std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);  --! z from opcode, just to control it arrives correctly to localsum
    t_opcode: out std_logic_vector (W_T-1 downto 0);        --! t coordinate output of opcode to be sent to FSM  
    z_ls: in std_logic_vector (W_ADDR_IN_IMAGE-1 downto 0);     --! z input to localsum  
    t_ls: in std_logic_vector (W_T-1 downto 0);            --! t coordinate input to ls module  
    ls_out: out std_logic_vector (DRANGE+2 downto 0);        --! Local sum
    
    en_localdiff: in std_logic;                    --! Enable localdiff computation. 
    s_in_localdiff: in std_logic_vector (DRANGE-1 downto 0);    --! Current sample - Input of localdiff module
    ld_out: out std_logic_vector(W_LD-1 downto 0);          --! Central local diff value.
    
    en_localdiff_shift: in std_logic;                --! Activates the shift of the localdiff vector.  
    sign: in std_logic;                       --! Input data are signed (1) or unsigned (0).
  
    finished: out std_logic;                    --! Finished flag, activated when all residuals have been produced.
    config_valid: in std_logic;                    --! Validates the configuration. 
    config_image : in config_123_image;                --! Image metadata configuration values
    config_predictor: in config_123_predictor;            --! Predictor configuration values
    clear : in std_logic;                      --! Synchronous clear to reset all registers. 
    
    --Current FIFO
    empty_curr: out std_logic;                    --! CURR FIFO flag empty.                
    aempty_curr: out std_logic;                    --! CURR FIFO flag almost empty.
    full_curr: out std_logic;                    --! CURR FIFO flag full. 
    afull_curr: out std_logic;                    --! CURR FIFO flag almost full.
    hfull_record: out std_logic;                  --! Half full flag from record FIFO  
    clear_curr: in std_logic;                    --! Clear input to FIFOs
    
    -- AHB FIFOs (store the top right neighbours)
    full_top_right_ahbo: out std_logic;                --! TOP RIGHT FIFO flag full.   
    empty_top_right_ahbi: out std_logic;              --! TOP RIGHT FIFO flag empty.
    aempty_top_right_ahbi: out std_logic;              --! Modified by AS: TOP RIGHT FIFO flag almost empty.
    full_top_right_ahbi: out std_logic;                --! TOP RIGHT FIFO flag full.   
    
    -- AHB related signals
    clk_ahb: in std_logic;                      --! AHB clock  
    rst_ahb: in std_logic;                      --! AHB reset  
    ahbmi: in ahb_mst_in_type;                     --! AHB input  
    ahbmo: out ahb_mst_out_type;                   --! AHB output  
    ahbm_status: out ahbm_123_status;                --! AHB status  
    config_ahbm: in config_123_ahbm;                --! Compressor configuration values needed by AHB master
    
    fifo_full_pred: out std_logic;                  --! Signals that there was an attempt to write in a full FIFO.
    pred_edac_double_error: out std_logic;              --! EDAC double error.
    mapped : out std_logic_vector(DRANGE-1 downto 0);        --! Mapped prediction residual to be encoded
    mapped_valid : out std_logic                  --! Validates the mapped prediction residual for 1 clk. 
  );
end ccsds_comp_shyloc_bil_mem;

architecture arch_bil_mem of ccsds_comp_shyloc_bil_mem is

  signal s_left: std_logic_vector(DRANGE-1 downto 0);
  signal s_top: std_logic_vector(DRANGE-1 downto 0);
  signal s_top_left: std_logic_vector(DRANGE-1 downto 0);
  signal s_top_right: std_logic_vector(DRANGE-1 downto 0);
  
  signal  opcode_ld     :       std_logic_vector(4 downto 0);
  signal  s_left_ld    :       std_logic_vector(DRANGE-1 downto 0);    
  signal  s_top_ld    :       std_logic_vector(DRANGE-1 downto 0);    
  signal  s_top_left_ld  :       std_logic_vector(DRANGE-1 downto 0);
  
  signal s_curr: std_logic_vector(DRANGE-1 downto 0);
  signal ls: std_logic_vector(W_LS-1 downto 0);
  
  --Top right FIFO received from AHB interface
  signal s_top_right_from_ahbi: std_logic_vector(DRANGE-1 downto 0);  
  
  -- Variable part of smax, smin and smid. 
  signal smax_var, smid_var, smin_var: std_logic_vector (1 downto 0);
  
  signal opcode_tmp: std_logic_vector(4 downto 0);
  signal z_predict, z_predictor, z_rho, z_mapped: std_logic_vector(W_ADDR_IN_IMAGE -1 downto 0);
  signal z_tmp, z_predictor_dot: std_logic_vector(W_ADDR_IN_IMAGE -1 downto 0);
  signal t, t_rho: std_logic_vector(W_T-1 downto 0);
  signal t_predictor, t_predict: std_logic_vector(W_T-1 downto 0);  
  signal ld, ld_n, ld_w, ld_nw: std_logic_vector(W_LD-1 downto 0);
  signal ld_vector_central: ld_array_type(0 to P_MAX-1);
  signal ld_vector_central_cast: ld_array_type(0 to 0);  
  signal r_update_ld_central, valid_update_ld_central: std_logic_vector(0 to P_MAX-1);
  signal ld_vector, ld_vector_to_update: ld_array_type(0 to Cz-1);
  signal ld_vector_predict: ld_array_type(0 to Cz-1);  
  signal ld_vector_dir: ld_array_type(0 to 2);  
  signal ld_vector_dot: ld_array_type (0 to P_MAX-1);  
  signal custom_wei_vector, wei_vector, updated_weight, wei_vector_updated, wei_vector_to_update:  wei_array_type (0 to Cz-1);
  signal updated_weight_stored, we_vector_dot:  wei_array_type (0 to Cz-1);  
  signal result_dot: std_logic_vector(W_DZ-1 downto 0);
  signal valid_dot: std_logic;
  signal s_scaled : std_logic_vector (W_SCALED-1 downto 0);   --! Scaled predicted sample.
  signal s_predict, s_predictor, s_mapped: std_logic_vector (W_S_SIGNED-1 downto 0);
  signal s_predict_out, s_predictor_dot: std_logic_vector (W_S_SIGNED-1 downto 0);  
  signal ls_predict, ls_predictor: std_logic_vector (W_LS-1 downto 0);
  signal ls_predict_out, ls_predictor_dot: std_logic_vector (W_LS-1 downto 0);
  signal opcode_predict, opcode_predictor, opcode_ro, opcode_weight: std_logic_vector(4 downto 0);
  signal opcode_predict_out, opcode_predictor_dot, opcode_mac: std_logic_vector(4 downto 0);
  signal en_rho_update, en_update: std_logic;
  
  signal valid_predictor: std_logic;
  signal ro: std_logic_vector(W_RO - 1 downto 0);  
  signal w_update_fifo_ld, r_update_fifo_ld: std_logic;  
  
  signal localdiff_results_in, localdiff_results_out: ld_record_type;  
  
  signal w_update_fifo_wei_tmp, r_update_fifo_wei_tmp, r_update_fifo_wei_update: std_logic;
  signal en_init_weight: std_logic;
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
  
  signal opcode_weight_store, opcode_predict_reg, opcode_weight_reg: std_logic_vector(4 downto 0);
  signal w_update_weight: std_logic;  
  signal en_central_shift: std_logic;  
  
  signal w_update_record, r_update_record: std_logic;  
  signal empty_record, full_record, afull_record, aempty_record: std_logic;    
  
  signal w_update_central: std_logic;    
  signal en_multacc_shyloc: std_logic;
  signal valid_fifo_wei: std_logic;
  signal valid_ld_record: std_logic;  
  
  signal w_update_record_reg: std_logic;  
  signal en_update_reg: std_logic;  
  
  signal en_multacc_shyloc_selected: std_logic;    
  signal en_init_weight_reg: std_logic;  
  signal clear_current_fifo: std_logic;

  --Half full flags for AHB fifo
  signal hfull_top_righ_ahbi: std_logic;  
  
  signal smax, smin: std_logic_vector(W_SMAX-1 downto 0);
  
  signal valid_multacc_shyloc: std_logic;  
  signal full_curr_out, full_wei_vector_updated, fifo_full_pred_out: std_logic;
  signal full_top_right, full_ld_central: std_logic;  
  signal full_ld_to_update, full_wei_vector_to_update: std_logic; 
  -- The number of FIFOs with EDAC in the design is reduced in 1 wrt bil and bip-mem architectures
  constant N_FIFOS : integer := 5;    --6;
  signal edac_double_error_vector: std_logic_vector (0 to N_FIFOS);
  signal edac_double_error_vector_tmp: std_logic_vector (0 to N_FIFOS+1);
  signal edac_double_error_out, edac_double_error_reg: std_logic;
  signal wait_for_empty_reg: std_logic;
begin

  -----------------------------------------------------------------------------  
  -- Output assignments
  -----------------------------------------------------------------------------
  opcode <= opcode_tmp;
  ls_out <= ls;
  s_out <= s_curr;
  ld_out <= ld;  
  full_top_right_ahbi  <= full_top_right_ahbi_out;
  z_opcode <= z_tmp;  
  t_opcode <= t;  
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
    port map(rst_n => rst_n, clk => clk, clear => clear, din => edac_double_error_out, dout => edac_double_error_reg);
  pred_edac_double_error <= edac_double_error_reg;
  --pragma translate_off
  assert edac_double_error_reg = '0' report "BIL-MEM: EDAC double error detected - compressor should stop now" severity warning;
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
                    "01"           when '0', 
                    (others => '0') when others;

  with sign select   
    smin_var(smin_var'high downto 0) <= "11"   when '1',
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
      RESET_TYPE => RESET_TYPE, W => W, NE => NE_CURR,
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
  --!@brief Register for LEFT neighbour  
  -----------------------------------------------------------------------------
  left_delay: entity shyloc_123.shift_ff(arch)
  generic map ( N => DRANGE, N_STAGES => 1 , RESET_TYPE => RESET_TYPE)
  port map ( rst_n => rst_n, clk => clk, clear => clear,  din => s_in_left, dout => s_left);

  -----------------------------------------------------------------------------  
  --!@brief Register for TOP neighbour
  -----------------------------------------------------------------------------
  top_delay: entity shyloc_123.shift_ff(arch)
  generic map (N => DRANGE, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  port map ( rst_n => rst_n, clk => clk, clear => clear, din => s_top_right, dout => s_top);
  
  -----------------------------------------------------------------------------  
  --!@brief Register for TOP LEFT neighbour
  -----------------------------------------------------------------------------
  -- Modified by AS: shift_ff_en component replaced by simple register with enable (ff_en), as the number of stages is always 1
  top_left_delay: entity shyloc_123.ff_en(arch)
  generic map (N => DRANGE, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, en => en_localsum, clear => clear, din => s_top, dout => s_top_left);
  -- top_left_delay: entity shyloc_123.shift_ff_en(arch)
  -- generic map (N => DRANGE, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  -- port map (rst_n => rst_n, clk => clk, en => en_localsum, clear => clear, din => s_top, dout => s_top_left);

  -----------------------------------------------------------------------------  
  --!@brief Neighbour TOP RIGHT FIFO -- to interface with AHB  
  -----------------------------------------------------------------------------
  -- Resize to 32 bits, input to AHB FIFO
  s_in_top_right_tmp <= std_logic_vector(resize(unsigned(s_in_top_right), s_in_top_right_tmp'length));
  
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
  --! Modified by AS: New version of the FIFO with almost empty flag
  -----------------------------------------------------------------------------  
  fifo_top_right_from_ahb: entity shyloc_123.async_fifo_v2(arch)
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
      aempty => aempty_top_right_ahbi,
      hfull => hfull_top_righ_ahbi
    );
      
  -- Resize to DRANGE bits, to continue  
  s_top_right_from_ahbi <= s_top_right_tmp (DRANGE-1 downto 0);
  
  -----------------------------------------------------------------------------  
  --!@brief Pipeline register: STORAGE OF TOP_RIGHT sample from AHB to send to TOP FIFO  
  -----------------------------------------------------------------------------  
  top_right_out_delay:  entity shyloc_123.shift_ff(arch)
  generic map (N => DRANGE, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => s_top_right_from_ahbi,  dout => s_top_right);
  
  -----------------------------------------------------------------------------  
  --!@brief Opcode module: bil_arch architecture  
  -----------------------------------------------------------------------------
  opcode_update: entity shyloc_123.opcode_update(bil_arch)
    generic map(RESET_TYPE => RESET_TYPE, Nx => Nx_GEN, Ny => Ny_GEN, Nz => Nz_GEN, W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, W_T => W_T)
    port map(
      clk => clk, 
      rst_n => rst_n,
      en => en_opcode, 
      clear => clear, 
      config_image => config_image,
      z => z_tmp, 
      t => t,
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
           s_top_ld =>   s_top_ld,
            s_top_left_ld => s_top_left_ld
    );
  
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
    --Store opcode value, will help to trigger the prediction for the first sample  
    -----------------------------------------------------------------------------
    opcode_predict_delay: entity shyloc_123.shift_ff(arch)
    generic map (N => 5, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
    port map (rst_n => rst_n, clk => clk, clear => clear, din => opcode_predict, dout => opcode_predict_reg);
    
    -----------------------------------------------------------------------------
    --Store opcode value to evaluate when to read from weights FIFO  
    -----------------------------------------------------------------------------
    opcode_weight_delay_record: entity shyloc_123.shift_ff(arch)
    generic map (N => 5, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
    port map (rst_n => rst_n, clk => clk, clear => clear, din => opcode_weight,  dout => opcode_weight_reg);
    
    -----------------------------------------------------------------------------
    --Register Write enable for record FIFO  
    -----------------------------------------------------------------------------
    w_update_record <= en_localdiff_shift;
    record_write_enable_reg: entity shyloc_123.ff1bit(arch)
    generic map (RESET_TYPE => RESET_TYPE)
    port map (rst_n => rst_n, clk => clk, clear => clear, din => w_update_record, dout => w_update_record_reg);
    
    -----------------------------------------------------------------------------
    -- Register Enable weight update operation  
    -----------------------------------------------------------------------------
    weight_update_reg: entity shyloc_123.ff1bit(arch)
    generic map (RESET_TYPE => RESET_TYPE)
    port map (rst_n => rst_n, clk => clk, clear => clear, din => en_update,  dout => en_update_reg);
    
    -----------------------------------------------------------------------------
    --Register Enable init weight update operation    
    -----------------------------------------------------------------------------
    
    init_weight_update_reg: entity shyloc_123.ff1bit(arch)
    generic map (RESET_TYPE => RESET_TYPE)
    port map (rst_n => rst_n, clk => clk, clear => clear, din => en_init_weight, dout => en_init_weight_reg);
    
    -----------------------------------------------------------------------------
    --Select when to read from record FIFO    
    -----------------------------------------------------------------------------
    
    gen_r_update_record: if Cz > 0 generate
    -- Controls when to read from record FIFO
    -- I read immediately after writing "10000";
    -- Then after a weight init or weight update if the sample is not the last one
    -- in a line; in such case, I have already read before.
      wait_state: process(clk, rst_n)
        variable read_record_condition : std_logic := '0';
      begin
        if (rst_n = '0' and RESET_TYPE = 0) then
          wait_for_empty_reg <= '0';
        elsif clk'event and clk = '1' then
          if en_update_reg = '1' and opcode_weight_reg /= "10001" and 
          opcode_weight_reg /= "00111" and opcode_weight_reg /= "10111" then
            read_record_condition :=  '1';
          elsif en_init_weight_reg = '1' and opcode_weight_reg /= "10001" and 
               opcode_weight_reg /= "00111" and opcode_weight_reg /= "10111" then
            read_record_condition :=  '1';
          elsif w_update_record_reg = '1' and opcode_predict_reg = "10000" then
            read_record_condition :=  '1';
          else
            read_record_condition :=  '0';
          end if;
          if (clear = '1' or (rst_n = '0' and RESET_TYPE= 1)) then
            wait_for_empty_reg <= '0';
          else
            if empty_record = '1' then
              if read_record_condition = '1' then
                wait_for_empty_reg <= '1';
              end if;
            else
              wait_for_empty_reg <= '0';
            end if;
          end if;
        end if;
      end process;
      
      r_update_record <= w_update_record_reg when empty_record = '0' and opcode_predict_reg = "10000" else
               '1' when empty_record = '0' and opcode_predictor = "10001" else
               '1' when empty_record = '0' and opcode_predictor = "00111" else
               '1' when empty_record = '0' and opcode_predictor = "10111" else
               '1' when empty_record = '0' and en_update_reg = '1' and opcode_weight_reg /= "10001" and 
               opcode_weight_reg /= "00111" and opcode_weight_reg /= "10111" else
               ----- the problem is here ---
               --Are these conditions necessary? Init weights is only activated for t = 0...
               '1' when empty_record = '0' and en_init_weight_reg = '1' and opcode_weight_reg /= "10001" and 
               opcode_weight_reg /= "00111" and opcode_weight_reg /= "10111" else
               -- Condition added for cases in which samples arrive slowly
               '1' when empty_record = '0' and wait_for_empty_reg = '1' else
               '0';
    end generate  gen_r_update_record;
    
    gen_r_update_record_cz0: if Cz = 0 generate
      -- no need to wait for feedback loop - just read from FIFO and carry on
      r_update_record <= not empty_record;
    end generate gen_r_update_record_cz0;
    
    -----------------------------------------------------------------------------
    --Read weights when there is a valid record read and it is the first sample in a row (except first row)  
    -----------------------------------------------------------------------------
    r_update_fifo_wei_update <= '1' when valid_ld_record = '1' and (opcode_predictor = "01010" or opcode_predictor = "11010") else '0';
    
    --NOTE: THIS WILL NOT BE VALID WITH MEMORY INTERFACE (SEE BIP-MEM)
    -----------------------------------------------------------------------------
    --!@brief PIPELINE register: stores z from opcode to predictor inut  
    -----------------------------------------------------------------------------
    z_opcode_pred: entity shyloc_123.shift_ff(arch)
    generic map ( N => z_tmp'length, N_STAGES => 2, RESET_TYPE => RESET_TYPE) --adjust if not correct!!!  Delay decreased in 2 cycles
  --  port map (rst_n => rst_n, clk => clk, clear => clear, din => z_tmp, dout => z_predict);
    port map (rst_n => rst_n, clk => clk, clear => clear, din => z_ls, dout => z_predict);
    
    -----------------------------------------------------------------------------
    --!@brief PIPELINE register: stores t from opcode to predictor inut    
    -----------------------------------------------------------------------------
    t_opcode_pred: entity shyloc_123.shift_ff(arch)
    generic map ( N => W_T, N_STAGES => 2, RESET_TYPE => RESET_TYPE) --adjust if not correct!!!    Delay decreased in 2 cycles
  --  port map (rst_n => rst_n, clk => clk, clear => clear, din => t, dout => t_predict);
    port map (rst_n => rst_n, clk => clk, clear => clear, din => t_ls, dout => t_predict);
    
    -- Assigns values read from record FIFO to be input to the predictor module
    localdiff_results_in.opcode_predict <= opcode_predict;
    localdiff_results_in.ls_predict <= ls_predict;
    localdiff_results_in.s_predict <= s_predict;
    localdiff_results_in.z_predict <= z_predict;
    localdiff_results_in.t_predict <= t_predict;
    
  -----------------------------------------------------------------------------
  --!@brief generation of localdiff vector for prediction from values read from
  --! record FIFO      (only bil)
  -----------------------------------------------------------------------------
    gen_ld_vector_record_in_full: if PREDICTION_GEN = 0 generate
      localdiff_results_in.ld_vector (0) <= ld_n;
      localdiff_results_in.ld_vector (1) <= ld_nw;
      localdiff_results_in.ld_vector (2) <= ld_w;
      gen_central_ld_record_in: if P_MAX > 0 generate
        localdiff_results_in.ld_vector (3) <= ld;
      end generate;
    end generate gen_ld_vector_record_in_full;
    
    gen_ld_vector_record_in_reduced: if PREDICTION_GEN = 1 generate
      gen_central_ld_record_in: if P_MAX > 0 generate
        localdiff_results_in.ld_vector (0) <= ld;
      end generate;
    end generate gen_ld_vector_record_in_reduced;
    
  -----------------------------------------------------------------------------
  --!@brief RECORD FIFO: stores output from LOCALDIFF until prediction is ready  
  -----------------------------------------------------------------------------
    -- EDAC here disabled, this FIFO is expected to be
    -- implemented by FFs instead of BRAM due to limited size.
    -- assign EDAC => EDAC if you wish generic parameter value to 
    -- be passed.
    -- Check your synthesis results to ensure no BRAM is used, otherwise
    -- enable edac by assigning EDAC => EDAC
  
    record_fifo_2: entity shyloc_123.record_2d_fifo(arch)
      generic map (NE => NE_RECORD_BIL, W_ADDR  => W_ADDR_RECORD_BIL, EDAC => 0, TECH => TECH)
    port map(
        clk => clk, 
        rst_n => rst_n,
        clr => clear,
        w_update => w_update_record, 
        r_update  => r_update_record,
        data_record_in =>localdiff_results_in,  
        data_record_out => localdiff_results_out,
        hfull => hfull_record,
        empty => empty_record,
        full  => full_record,
        afull => afull_record,
        aempty => aempty_record, 
        -- Adjusted EDAC error index
        edac_double_error => edac_double_error_vector(1)
    );
    
    -- Assigns values read from record FIFO to be input to the predictor module    
    opcode_predictor <= localdiff_results_out.opcode_predict; 
    ls_predictor <= localdiff_results_out.ls_predict;         
    s_predictor <= localdiff_results_out.s_predict;
    z_predictor <= localdiff_results_out.z_predict;
    t_predictor <= localdiff_results_out.t_predict;    
    
  -----------------------------------------------------------------------------
  --!@brief Create ld vector for prediction from values read from record FIFO    
  -----------------------------------------------------------------------------
    gen_ld_vector_record_out: if Cz > 0 generate
      ld_vector_predict (0 to FULL*2) <= localdiff_results_out.ld_vector(0 to FULL*2);
      gen_ld_central: if P_MAX  > 0 generate
        ld_vector_predict (FULL*3) <= localdiff_results_out.ld_vector(FULL*3);
      end generate gen_ld_central;
    end generate gen_ld_vector_record_out;
    
  ----------------------------------------------------------------------------
  --!@brief Process to know if we need to update the vector of local differences  
  -----------------------------------------------------------------------------

    gen_ld_central_read: if P_MAX > 0 generate
      process (z_predictor, valid_ld_record, config_image, r_update_ld_central, config_predictor)
        variable r_update_ld_prev: std_logic_vector (0 to P_MAX-1) := (others => '0');
        variable pred_bound: integer := 0;
      begin
        r_update_ld_central <= (others => '0');
        r_update_ld_prev := r_update_ld_central;
        
        if (unsigned(z_predictor) < unsigned(config_predictor.P)) then
          pred_bound := to_integer(unsigned(z_predictor));
        else
          pred_bound := to_integer(unsigned(config_predictor.P));
        end if;
        
        if z_predictor > std_logic_vector  (to_unsigned(0, z_predict'length)) then
          if valid_ld_record = '1' then
            for i in 0 to P_MAX-1 loop
              -- Read the central local difference
              if i < pred_bound then
                r_update_ld_central(i) <='1';
              else
                r_update_ld_central(i) <='0';
              end if;
            end loop;
          end if;
        end if;
        if (unsigned(z_predictor) < unsigned(config_image.Nz)-1) then
          -- Move values in the FIFOs
          en_central_shift <= '1';
        else
          en_central_shift <= '0';
        end if;
      end process;
    end generate gen_ld_central_read;
    
    w_update_central <= valid_ld_record when unsigned(z_predictor) <  unsigned(config_image.Nz)-1  else '0';
    
    gen_ld_central_vector_fifo: if P_MAX > 0 generate
      ----------------------------------------------------------------------------
      --!@brief STORAGE OF LD VECTORS to be used later during update      
      --stores 1 central ld value and outputs the corresponding ld_vector (ld(z-1)... ld(z-P))
      ----------------------------------------------------------------------------
	-- EDAC here disabled, this FIFO is expected to be
    -- implemented by FFs instead of BRAM due to limited size.
    -- assign EDAC => EDAC if you wish generic parameter value to 
    -- be passed.
    -- Check your synthesis results to ensure no BRAM is used, otherwise
    -- enable edac by assigning EDAC => EDAC
      ld_central_vector_fifo_3: entity shyloc_123.ld_2d_fifo_bil(arch_bil)
      generic map(
        Cz => P_MAX,  --number of FIFOs -- one for each central ld
        W => W_LD,    --bit width of the elements
        NE => Nx_GEN,  --number of elements in FIFO, not really used
        W_ADDR => W_ADDR_CENTRAL_BIL,
        RESET_TYPE => RESET_TYPE, EDAC => 0, TECH => TECH
      )
      port map(
        clk => clk,
        rst_n => rst_n,
        clr  => clear,
        en_shift => en_central_shift,
        w_update  => w_update_central,
        r_update => r_update_ld_central, -- this is a vector
        data_in => ld_vector_predict(FULL*3), --from RECORD fifo
        data_vector_out => ld_vector_central, 
        full => full_ld_central,
        -- Adjusted EDAC error index
        edac_double_error => edac_double_error_vector(2)
      );
      
      valid_ld_central: entity shyloc_123.shift_ff(arch)
        generic map (N => P_MAX, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
        port map ( rst_n => rst_n, clk => clk,
          clear => clear, 
          din => r_update_ld_central, 
          dout => valid_update_ld_central -- this is controlled by z
        );
        
        --select the necessary central ld for MAC OR set to 0; depending on z
        --probably I need this for BIP also and I forgot to consider it
        --otherwise I will have a wrong value in MAC inputs
        gen_dot_ld: for i in 0 to P_MAX-1 generate
          ld_vector_dot (i) <= ld_vector_central(i) when valid_update_ld_central (i) = '1' else (others => '0');
        end generate;
    end generate gen_ld_central_vector_fifo;
    
    gen_no_ld_central_vector_fifo: if P_MAX = 0 generate
      -- Adjusted EDAC error index
      edac_double_error_vector(2) <= '0';  
    end generate gen_no_ld_central_vector_fifo;
    
    --register directional localdiff
    reg_dir: if PREDICTION_GEN = 0 generate
      gen_dir_ld: for i in 0 to 2 generate
        delay_ld_dir: entity shyloc_123.shift_ff(arch)
          generic map ( N => W_LD, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
          port map ( rst_n => rst_n, clk => clk,
            clear => clear, 
            din => ld_vector_predict(i), 
            dout => ld_vector_dir(i)
        );
      end generate gen_dir_ld;
    end generate reg_dir;
    ----------------------------------------------------------------------------
    --!@brief generation of localdiff vector for prediction    
    ----------------------------------------------------------------------------
    gen_vector_full: if PREDICTION_GEN = 0 generate
            ld_vector(0) <= ld_vector_dir (0);
            ld_vector(1) <= ld_vector_dir (1);
            ld_vector(2) <= ld_vector_dir (2);
            gen_central_condition: if P_MAX > 0 generate
              gen_central: for i in 3 to Cz-1 generate
                ld_vector(i) <= ld_vector_dot(i-3);
              end generate gen_central;
            end generate gen_central_condition;
          end generate gen_vector_full;
    
    gen_vector_reduced: if PREDICTION_GEN = 1 generate
      gen_central_condition: if P_MAX > 0 generate
        gen_central: for i in 0 to Cz-1 generate
          ld_vector(i) <= ld_vector_dot(i);
        end generate gen_central;
      end generate gen_central_condition;  
    end generate gen_vector_reduced;
      
  -- only read from the FIFO when needed, before performing the dot product
  ----------------------------------------------------------------------------
  --!@brief control signal after reading weight from FIFO    
  ----------------------------------------------------------------------------
  validate_fifo_wei: entity shyloc_123.ff1bit(arch)
  generic map (RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => r_update_fifo_wei_update, dout => valid_fifo_wei);
  
  validate_fifo_record: entity shyloc_123.ff1bit(arch)
  generic map (RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => r_update_record, dout => valid_ld_record);
  
  -- assigns the correct weight source to the multacc structure (from FIFO or from weight update unit)
  we_vector_dot <= wei_vector_updated when opcode_mac = "01010" or opcode_mac = "11010" else updated_weight_stored;
  
  opcode_delay_mac: entity shyloc_123.shift_ff(arch)
  generic map (N => 5, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear =>  clear, din => opcode_predictor,  dout => opcode_mac);
  
  enable_multacc: entity shyloc_123.ff1bit(arch)
  generic map (RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => valid_ld_record, dout => en_multacc_shyloc);      
  
  en_multacc_shyloc_selected <= en_multacc_shyloc; --when opcode_weight_store /= "10001" else '0'; 
  
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
      en => en_multacc_shyloc_selected, --not sure if this will always be like this or i'll need the signal at the control
      clear => clear,
      result => result_dot, 
      valid => valid_dot,
      ld_vector => ld_vector,
      wei_vector => we_vector_dot -- or updated_weight depending of the sample!! 
    );
  end generate gen_dot_product;
  
  -----------------------------------------------------------------------------
  --!@brief DOT PRODUCT -- forced to zero when Cz = 0 
  -----------------------------------------------------------------------------
  gen_dot_product_cz0: if Cz = 0 generate
    valid_dot_cz0_st1: entity shyloc_123.ff1bit(arch)
      generic map (RESET_TYPE => RESET_TYPE)
      port map (rst_n => rst_n, clk => clk, clear => clear,
        din => en_multacc_shyloc, dout => valid_multacc_shyloc  
      );
    valid_dot_cz0_st2: entity shyloc_123.ff1bit(arch)
      generic map (RESET_TYPE => RESET_TYPE)
      port map (rst_n => rst_n, clk => clk, clear => clear,
        din => valid_multacc_shyloc,  
        dout => valid_dot);
    result_dot <= (others => '0');
  end generate gen_dot_product_cz0;
  
  -- Write ld vector in FIFO when there's a valid localdiff_vector  
  -- Note that for first sample in each band the vector is not needed
  w_update_fifo_ld <= en_localdiff_shift;
  w_update_fifo_wei_tmp <= en_localdiff_shift;
  
  -----------------------------------------------------------------------------
  --!@brief Pipeline register: LS for predictor -- it is a delay of HEIGHT_TREE + 1 cycles
  -----------------------------------------------------------------------------
  ls_delay: entity shyloc_123.shift_ff(arch)
  generic map (N => W_LS,
    N_STAGES => HEIGHT_TREE + 2,
    RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear,
    din => ls_predictor, dout => ls_predictor_dot  
  );
  
  -----------------------------------------------------------------------------
  --!@brief Pipeline register: opcode for predictor -- it is a delay of HEIGHT_TREE + 1 cycles
  -----------------------------------------------------------------------------
  opcode_delay: entity shyloc_123.shift_ff(arch)
  generic map (N => 5, N_STAGES => HEIGHT_TREE + 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear,
    din => opcode_mac, dout => opcode_predictor_dot  
  );
  
  -----------------------------------------------------------------------------
  --!@brief Pipeline register: current sample for predictor -- it is a delay of HEIGHT_TREE + 1 cycles
  -----------------------------------------------------------------------------
  s_delay: entity shyloc_123.shift_ff(arch)
  generic map (N => W_S_SIGNED,
    N_STAGES => HEIGHT_TREE + 2,
    RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear,
    din => s_predictor, dout => s_predictor_dot  
  );
  
  -----------------------------------------------------------------------------
  --!@brief Pipeline register: z sample for predictor -- it is a delay of HEIGHT_TREE + 1 cycles
  -----------------------------------------------------------------------------
  z_delay: entity shyloc_123.shift_ff(arch)
  generic map (
    N => W_ADDR_IN_IMAGE, N_STAGES => HEIGHT_TREE + 2,  
    RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear,
    din => z_predictor, dout => z_predictor_dot  
  );
  
  -----------------------------------------------------------------------------
  --!@brief PREDICTOR CORE
  -----------------------------------------------------------------------------
  predictor_core: entity shyloc_123.predictor2stagesv2(arch)
  generic map (RESET_TYPE => RESET_TYPE, OMEGA => OMEGA_GEN, W_S_SIGNED => W_S_SIGNED, R => R_GEN, 
      W_DZ => W_DZ, NBP => P_MAX, W_SCALED => W_SCALED, 
      W_SMAX => W_SMAX, W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, W_LS => W_LS)
  port map (
    clk => clk, 
    rst_n => rst_n, 
    opcode => opcode_predictor_dot,  
    config_image => config_image, 
    en => valid_dot, --connecting en_predictor to valid_dot
    clear => clear, 
    config_predictor => config_predictor,
    z => z_predictor_dot, --this is not really needed
    s => s_predictor_dot,   
    smax_var => smax_var, 
    smin_var => smin_var,
    smid_var => smid_var, 
    dz => result_dot, 
    ls => ls_predictor_dot,  
    valid => valid_predictor,
    smin => smin, 
    smax => smax,
    s_mapped => s_mapped,
    s_scaled => s_scaled 
  );
  
  -----------------------------------------------------------------------------
  --!@brief Pipeline register: store opcode between predictor and rho 
  -----------------------------------------------------------------------------
  opcode_delay_ro: entity shyloc_123.shift_ff(arch)
  generic map (N => 5, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear,
    din => opcode_predictor_dot,
    dout => opcode_ro);
  
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
  port map (rst_n => rst_n, clk => clk, clear => clear,
    din => z_predictor_dot,  
    dout => z_rho);

  ----------------------------------------------------------------------------
  --!@brief PIPELINE Register: t from PRED to RO    
  ----------------------------------------------------------------------------
  t_delay_pred_rho: entity shyloc_123.shift_ff(arch)
  generic map (N => W_T, N_STAGES => HEIGHT_TREE + 2 +1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => t_predictor, dout => t_rho);

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
  
  ----------------------------------------------------------------------------
  --!@brief PIPELINE Register: z from rho to mapped
  ----------------------------------------------------------------------------
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
    smax => smax, 
    smin => smin, 
    s_scaled => s_scaled,
    valid => mapped_valid, 
    mapped => mapped
  );
  
  -- Read ld vector from FIFOs to be used in weight update.
  --note that for first sample in each band the vector is not needed.
  r_update_fifo_wei_tmp <= en_rho_update;
  
  -----------------------------------------------------------------------------
  --!@brief PIPELINE register: stores opcode from rho to update weight
  -----------------------------------------------------------------------------
  opcode_delay_weights: entity shyloc_123.shift_ff(arch)
  generic map (N => 5, N_STAGES => 1 , RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => opcode_ro, dout => opcode_weight);
  
  -- Enable update or initialization depending on opcode
  en_init_weight <= valid_predictor when opcode_weight(3 downto 0) = "0000" else '0';
  en_update <= valid_predictor when opcode_weight(3 downto 0) /= "0000" else '0';
  
  gen_vectors_temp_storage: if Cz > 0 generate    
  --i'm replacing the registers by a FIFO, to be sure we really keep the ld data between en_multacc and en_rho
  --This can be simplified by a register also, as we will only store and read one value
  --store when en_multacc_shyloc read when en_rho_update
  -----------------------------------------------------------------------------
  --!@brief Storage of ld vectors to update    
  -----------------------------------------------------------------------------
  	-- EDAC here disabled, this FIFO is expected to be
    -- implemented by FFs instead of BRAM due to limited size.
    -- assign EDAC => EDAC if you wish generic parameter value to 
    -- be passed.
    -- Check your synthesis results to ensure no BRAM is used, otherwise
    -- enable edac by assigning EDAC => EDAC
  fifo_4_ld_store_to_update: entity shyloc_123.ld_2d_fifo(arch)
  generic map (
    Cz => Cz,
    W => W_LD,
    NE => Nz_GEN, --this does not matter
    W_ADDR => W_ADDR_DOT_TO_UPDATE_BIL,
    RESET_TYPE => RESET_TYPE, EDAC => 0, TECH => TECH
  )
  port map(
    clk => clk,
    rst_n => rst_n,
    clr  => clear,
    w_update  => en_multacc_shyloc, -- write when there's a valid weight
    r_update => en_rho_update, -- read before weight update
    data_vector_in => ld_vector, -- from dot module
    data_vector_out => ld_vector_to_update, -- to weight update module
    -- Adjusted EDAC error index
    edac_double_error => edac_double_error_vector(3)
  );
  
  -----------------------------------------------------------------------------
  --!@brief Storage of weight vectors to update  
  -----------------------------------------------------------------------------  
  fifo_5_wei_storage_from_dot_to_update: entity shyloc_123.wei_2d_fifo(arch)
  generic map (
    Cz => Cz,
    W => W_WEI,
    NE => Nz_GEN,
    W_ADDR => W_ADDR_DOT_TO_UPDATE_BIL,
    RESET_TYPE => RESET_TYPE, EDAC => EDAC, TECH => TECH
  )
  port map(
    clk => clk,
    rst_n => rst_n,
    clr  => clear,
    w_update  => en_multacc_shyloc_selected, --write when I enable the mac (not sure if with selected or the other)
    r_update => en_rho_update, -- read when there's rho update (1 clk after predictor=
    data_vector_in => we_vector_dot, -- from weight update module
    data_vector_out => wei_vector_to_update, -- to dot product module
    -- Adjusted EDAC error index
    edac_double_error => edac_double_error_vector(4)
  );
  
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
    updated_weight => updated_weight --here is where things change for BIL
    );
    
      
  -----------------------------------------------------------------------------
  --!@brief Storage of weight vectors between update and MAC  
  -----------------------------------------------------------------------------  
    --note what happens when Cz = 0; it is a particular case that needs to be considered in this generate
    gen_wei_vector_to_dot: for i in 0 to Cz-1 generate
      -- Modified by AS: shift_ff_en component replaced by simple register with enable (ff_en), as the number of stages is always 1
      wieght_stored: entity shyloc_123.ff_en(arch)
      generic map (N => W_WEI, RESET_TYPE => RESET_TYPE)
      port map (
        rst_n => rst_n,
        clk => clk,
        en => valid_weight_update,
        clear => clear,
        din => updated_weight(i), 
        dout => updated_weight_stored(i)
      -- wieght_stored: entity shyloc_123.shift_ff_en(arch)
      -- generic map (N => W_WEI, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
      -- port map (
        -- rst_n => rst_n,
        -- clk => clk,
        -- en => valid_weight_update,
        -- clear => clear,
        -- din => updated_weight(i), 
        -- dout => updated_weight_stored(i)
      );
    end generate;
  end generate gen_vectors_temp_storage;
  
  --we could also put this as input andoutput of weight update
  -----------------------------------------------------------------------------
  --!@brief PIPELINE register: opcdode from weight update input to weights storage  
  -----------------------------------------------------------------------------  
  opcode_delay_weight_storage: entity shyloc_123.shift_ff(arch)
  generic map (N => 5, N_STAGES => 2, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => opcode_weight, dout => opcode_weight_store);

  --note that for INIT, the delay of opcode is not compliant - this would happen if Nx = 1 --and valid!!! weight
  w_update_weight <= '1' when valid_weight_update = '1' and (opcode_weight_store = "10001" or opcode_weight_store = "00111") else '0';
  
  gen_wei_update: if Cz > 0 generate
    -- IN BIL, it is not always necessary to store the weights, they can go straight to Dot product!
    -----------------------------------------------------------------------------
    --!@brief STORAGE OF WEIGHT VECTORS to be used in dot product
    -----------------------------------------------------------------------------
    fifo_6_wei_update_storage: entity shyloc_123.wei_2d_fifo(arch)
    generic map (Cz => Cz, W => W_WEI,
      NE => Nz_GEN, W_ADDR => W_ADDR_WEIGHT_UPDATE_BIL,  
      RESET_TYPE => RESET_TYPE, EDAC => EDAC, TECH => TECH)
    port map(
      clk => clk,
      rst_n => rst_n,
      clr  => clear,
      w_update  => w_update_weight, -- write when there's a valid weight & last sample of a row!!
      r_update => r_update_fifo_wei_update, -- read when... see on top
      data_vector_in => updated_weight, -- from weight update module
      data_vector_out => wei_vector_updated,  -- to dot product module
      full => full_wei_vector_updated,
      -- Adjusted EDAC error index
      edac_double_error => edac_double_error_vector(5)
    );
  end generate gen_wei_update;
  
  gen_no_wei_update: if Cz = 0 generate
    -- Adjusted EDAC error index
    edac_double_error_vector(5) <= '0';
  end generate gen_no_wei_update;
  
end arch_bil_mem;
