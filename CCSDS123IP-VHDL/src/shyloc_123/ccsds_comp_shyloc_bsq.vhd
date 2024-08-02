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
-- Design unit  : CCSDS123 components BSQ predictor
--
-- File name    : ccsds_comp_shyloc_bsq.vhd
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
--      <Revision number>: <Date>: <Comments>


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
library shyloc_123; 
use shyloc_123.ccsds123_parameters.all; 
use shyloc_123.ccsds123_constants.all;    

library shyloc_utils;
use shyloc_utils.amba.all;
use shyloc_123.ccsds_ahb_types.all;

--!@file #ccsds_comp_shyloc_bsq.vhd#
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--!@author Lucana Santos
--!@email lsfalcon@iuma.ulpgc.es
--!@brief Makes the connections between the different modules of the CCSDS compressor.


entity ccsds_comp_shyloc_bsq is
  generic (DRANGE: integer := 16;       --! Dynamic range of the input samples
       --W_ADDR_BANK: integer := 2;     --! Bit width of the address signal in the register banks.
       W_ADDR_IN_IMAGE: integer := 16;  --! Bit width of the image coordinates (x, y, z)
       HMINDEX_123: integer := 1;     --! AHB master index
       W_BUFFER: integer := 64;     --! Bit width of the output buffer.
       RESET_TYPE: integer := 1     --! Reset flavour (0) asynchronous (1) synchronous
      );
  port (
    clk: in std_logic;                        --! Clock signal.
    rst_n: in std_logic;                      --! Reset signal. Active low.
    
    --Input sample FIFO
    w_update_curr: in std_logic;                  --! Write enable in the CURR FIFO.  Active high.
    r_update_curr: in std_logic;                  --! Read enable in the CURR FIFO. Active high.
    w_update_top_right: in std_logic;               --! Write enable in the TOP RIGHT FIFO. Active high. 
    r_update_top_right: in std_logic;               --! Read enable in the TOP RIGHT FIFO. Active high.
    
    s: in std_logic_vector (DRANGE-1 downto 0);           --! Current sample to be compressed, s(x, y, z) - Input to CURR FIFO
    en_opcode: in std_logic;                    --! Enable opcode
  
    s_out: out std_logic_vector (DRANGE-1 downto 0);        --! Current sample to be compressed, s(x, y, z) - Read from CURR FIFO sent to FSM
    s_in_left: in std_logic_vector (DRANGE-1 downto 0);       --! Sample to be stored in LEFT FIFO. Comes from FSM.
    s_in_top_right: in std_logic_vector (DRANGE-1 downto 0);    --! Sample to be stored in TOP RIGHT FIFO. Comes from FSM.
    
    opcode: out std_logic_vector(4 downto 0);           --! Opcode to know the relative positon of a sample.
    z_opcode: out std_logic_vector(W_ADDR_IN_IMAGE-1 downto 0);   --! z coordinate output from OPCODE
    
    z: out std_logic_vector(W_ADDR_IN_IMAGE-1 downto 0);      --! z value output from OPCODE. To be sent to FSM
    z_predictor_out: out std_logic_vector(W_ADDR_IN_IMAGE-1 downto 0); --! z value read from record FIFO.
    
    en_localsum: in std_logic;                    --! Enable signal for local sum module. Active high.
    opcode_localsum: in std_logic_vector (4 downto 0);        --! Opcode read by localsum module.
    
    ls_out: out std_logic_vector (DRANGE+2 downto 0);       --! Local sum value. 
    
    en_localdiff: in std_logic;                   --! Enable localdiff computation. 
    s_in_localdiff: in std_logic_vector (DRANGE-1 downto 0);    --! Current sample - Input of localdiff module
    ld_out: out std_logic_vector(W_LD-1 downto 0);          --! Central local diff value.
    
    en_localdiff_shift: in std_logic;               --! Activates the shift of the localdiff vector.
    sign: in std_logic;                       --! Input data are signed (1) or unsigned (0).
    
    opcode_predictor_out: out std_logic_vector(4 downto 0);     --! Opcode output from predictor. Used in FSM.
    config_valid: in std_logic;                   --! Validates the configuration. 
    finished: out std_logic;                    --! Finished flag, activated when all residuals have been produced. 
    
    config_image : in config_123_image;               --! Image metadata configuration values
    config_predictor: in config_123_predictor;                      --! Predictor configuration values
    clear : in std_logic;                                           --! Synchronous clear to reset all registers.
    
    --Current FIFO
    empty_curr: out std_logic;                    --! CURR FIFO flag empty.               
    aempty_curr: out std_logic;                   --! CURR FIFO flag almost empty.
    full_curr: out std_logic;                   --! CURR FIFO flag full. 
    afull_curr: out std_logic;                    --! CURR FIFO flag almost full.
    clear_curr: in std_logic;
    
    --ahb FIFO related signals
    full_ld_ahbo: out std_logic;                  --! Full flag from AHBO FIFO. 
    empty_ld_ahbi: out std_logic;                 --! Empty flag from AHBI FIFO.
    
    w_update_ld_ahbo: in std_logic;                 --! Write update in AHBO FIFO
    r_update_ld_ahbi: in std_logic;                 --! Read update in AHBI FIFO
    
    clk_ahb: in std_logic;                      --! AHB clock
    rst_ahb: in std_logic;                      --! AHB reset
    ahbmi: in ahb_mst_in_type;                    --! AHB input
    ahbmo: out ahb_mst_out_type;                  --! AHB output
    config_ahbm: in config_123_ahbm;                --! Compressor configuration values needed by AHB module
    ahbm_status: out ahbm_123_status;               --! AHB status signals.
    
    w_update_record: in std_logic;                  --! Write update for record FIFO
    r_update_record: in std_logic;                  --! Read update for record FIFO
    hfull_record: out std_logic;                  --! Flag signals that record FIFO is hfull
    empty_record: out std_logic;                  --! Flag signals that record FIFO is empty.
    afull_record: out std_logic;                  --! Flag signals that record FIFO is almost full.
    aempty_record: out std_logic;                 --! Flag signals that record FIFO is almost empty.

    r_update_ld: in std_logic;                    --! Read a central local difference value (for dot product)
    r_update_wei: in std_logic;                   --! Read a weight value (for dot product)
    
    en_weight_dir_fsm: in std_logic;                --! Enable computation of directional weights
    en_weight_central_fsm: in std_logic;              --! Enable computation of central weights
    en_predictor: in std_logic;                   --! Enable predictor
    clear_mac: in std_logic;                    --! Clear MAC.
    address_central: in std_logic_vector (W_COUNT_PRED - 1 downto 0); --! Address to read default weight initialization values
    opcode_weight_out: out std_logic_vector (4 downto 0);     --! Opcode used by weight update
    opcode_weight_fsm: in std_logic_vector(4 downto 0);       --! Opcode sent to weight update
    r_update_wei_dir: in std_logic;                 --! Read update for directional weights
    fifo_full_pred: out std_logic;                  --! Signals that there was an attempt to write in a full FIFO.
    pred_edac_double_error: out std_logic;              --! EDAC double error.
    mapped : out std_logic_vector(DRANGE-1 downto 0);       --! Mapped prediction residual to be encoded
    mapped_valid : out std_logic                  --! Validates the mapped prediction residual for 1 clk. 
    
    );
end ccsds_comp_shyloc_bsq;

architecture arch_bsq of ccsds_comp_shyloc_bsq is

  signal s_curr: std_logic_vector(DRANGE-1 downto 0);
  signal s_left: std_logic_vector(DRANGE-1 downto 0);
  signal s_top: std_logic_vector(DRANGE-1 downto 0);
  signal s_top_left: std_logic_vector(DRANGE-1 downto 0);
  signal s_top_right: std_logic_vector(DRANGE-1 downto 0);
  
  signal opcode_ld : std_logic_vector(4 downto 0);
  signal s_left_ld, s_top_ld, s_top_left_ld: std_logic_vector(DRANGE-1 downto 0);   
  signal ls: std_logic_vector(W_LS-1 downto 0);


  signal smax_var, smid_var, smin_var: std_logic_vector (1 downto 0);  
  signal opcode_tmp: std_logic_vector(4 downto 0);
  signal t, t_predict, t_predictor, t_rho: std_logic_vector(W_T-1 downto 0);
  signal z_tmp, z_predict, z_predictor, z_weights, z_rho, z_mapped: std_logic_vector(W_ADDR_IN_IMAGE-1 downto 0);
  signal ld, ld_n, ld_w, ld_nw, ld_mac, ld_mac_synch_weight: std_logic_vector(W_LD-1 downto 0);
  

  signal ld_in_ahbo, ld_out_ahbo, ld_in_ahbi, ld_out_ahbi : std_logic_vector(31 downto 0); 
  signal r_update_ld_ahbo, w_update_ld_ahbi: std_logic;
  signal empty_ld_ahbo: std_logic;  
  signal full_ld_ahbi_out, full_ld_ahbi: std_logic; 
  signal ctrl_ahbm1: ahbtb_ctrl_type;
  signal done: std_logic;

  signal ld_vector, ld_vector_to_update, ld_vector_predict: ld_array_type(0 to Cz-1); 
  signal custom_wei_vector, updated_weight, wei_vector_to_update:  wei_array_type (0 to Cz-1);
  signal result_dot, result_dot_dir: std_logic_vector(W_DZ-1 downto 0);
  signal valid_dot: std_logic;
  signal s_scaled : std_logic_vector (W_SCALED-1 downto 0);   
  signal s_predict, s_predictor, s_mapped: std_logic_vector (W_S_SIGNED-1 downto 0);
  signal ls_predict, ls_predictor : std_logic_vector (W_LS-1 downto 0);
  signal opcode_predict, opcode_predictor, opcode_ro, opcode_weight: std_logic_vector(4 downto 0);
  signal en_rho_update: std_logic;
  signal valid_predictor: std_logic;
  signal ro: std_logic_vector(W_RO - 1 downto 0); 
  
  signal valid_weight_update: std_logic;
  signal accumulated_directional, result_dot10, product_dot2: std_logic_vector(W_DZ-1 downto 0);
  signal en_mult_directional: std_logic;
  
  signal localdiff_results_in, localdiff_results_out: ld_record_type; 
  
  signal dot_product_central: std_logic_vector (W_DZ-1 downto 0);
  signal ld_central_weight_update: std_logic_vector (W_LD-1 downto 0);
  signal updated_weight_reg, central_weight_reg: std_logic_vector (W_WEI-1 downto 0);
  signal en_init_weight_dir, en_update_weight_dir, en_init_weight_central, en_update_weight_central: std_logic;

  signal valid_init_central, valid_update_central: std_logic;
  signal w_update_ld_central, w_update_ld_dir, w_update_wei_dir, mac_enable: std_logic;
  signal updated_weight_init, updated_weight_up: std_logic_vector (W_WEI -1 downto 0);
  signal clear_multacc: std_logic;
  signal r_update_record_reg: std_logic;
  signal w_update_ld, valid_init_central_synch: std_logic;
  signal clear_current_fifo: std_logic;
  signal smin, smax: std_logic_vector (W_SMAX-1 downto 0);
  signal hfull_ld_ahbi: std_logic;
  signal full_curr_out, full_top_right, full_record, full_ld, full_ld_vector_to_update, full_wei_vector_to_update, fifo_full_pred_out: std_logic;
  signal valid_fifo_record_value: std_logic;
  constant N_FIFOS : integer := 5;
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
  z <= z_weights; -- to know how many iterations I will need to compute the MAC
  z_predictor_out <= z_predictor;
  z_opcode <= z_tmp;
  full_ld_ahbi <= full_ld_ahbi_out;
  opcode_weight_out <= opcode_weight;
  opcode_predictor_out <= opcode_predictor;
  --custom_wei_vector <= updated_weight;
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
  assert edac_double_error_reg = '0' report "BSQ comp: EDAC double error detected - compressor should stop now" severity warning;
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
    RESET_TYPE => RESET_TYPE, W => W, NE => NE_CURR, W_ADDR => W_ADDR_CURR, EDAC => 0, TECH => TECH) 
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
  generic map (N => DRANGE, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => s_in_left, dout => s_left);
  
  ----------------------------------------------------------------------------- 
  --!@brief Register for TOP neighbour
  -----------------------------------------------------------------------------
  top_delay: entity shyloc_123.shift_ff(arch)
  generic map (N => DRANGE, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => s_top_right, dout => s_top);
  
  ----------------------------------------------------------------------------- 
  --!@brief Register for TOP LEFT neighbour
  -----------------------------------------------------------------------------
  -- Modified by AS: shift_ff_en component replaced by simple register with enable (ff_en), as the number of stages is always 1
  top_left_delay: entity shyloc_123.ff_en(arch)
    generic map (N => D_GEN, RESET_TYPE => RESET_TYPE)
    port map (rst_n => rst_n, clk => clk, en => en_localsum, clear => clear, din => s_top, dout => s_top_left);
  -- top_left_delay: entity shyloc_123.shift_ff_en(arch)
    -- generic map (N => D_GEN, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
    -- port map (rst_n => rst_n, clk => clk, en => en_localsum, clear => clear, din => s_top, dout => s_top_left);
  
  -----------------------------------------------------------------------------   
  --!@brief Neighbour TOP RIGHT FIFO
  -----------------------------------------------------------------------------
  fifo_1_top_right: entity shyloc_utils.fifop2(arch)
    generic map (RESET_TYPE => RESET_TYPE, W => W, NE => NE_TOP_RIGHT_BSQ, W_ADDR => W_ADDR_TOP_RIGHT_BSQ, EDAC => EDAC, TECH => TECH)  
    port map (
      clk => clk,
      rst_n => rst_n,
      clr => clear,
      w_update => w_update_top_right,
      r_update => r_update_top_right,
      data_in => s_in_top_right,
      data_out => s_top_right, 
      full => full_top_right, 
      edac_double_error => edac_double_error_vector(1) 
    );
      
  ----------------------------------------------------------------------------- 
  --!@brief Opcode module: bsq_arch architecture
  ----------------------------------------------------------------------------- 
  opcode_update: entity shyloc_123.opcode_update(bsq_arch)
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
  --!@brief Pipeline registers for z (between opcode and record FIFO)
  -----------------------------------------------------------------------------
  z_delay: entity shyloc_123.shift_ff(arch)
  generic map ( N => z'length, 
      N_STAGES => 4, --adjust if not correct!!!
      RESET_TYPE => RESET_TYPE
    )
  port map (rst_n => rst_n, clk => clk, clear => clear, din => z_tmp, dout => z_predict);
  
  -----------------------------------------------------------------------------
  --!@brief Pipeline registers for t (between opcode and record FIFO)
  -----------------------------------------------------------------------------
  t_delay: entity shyloc_123.shift_ff(arch)
  generic map ( N => W_T,
      N_STAGES => 4, --adjust if not correct!!!
      RESET_TYPE => RESET_TYPE
    )
  port map (rst_n => rst_n, clk => clk, clear => clear, din => t, dout => t_predict);
  
  -----------------------------------------------------------------------------
  --!@brief LOCAL SUM
  -----------------------------------------------------------------------------
  localsum_core: entity shyloc_123.localsumv2(arch)
  generic map (DRANGE => DRANGE, LOCAL_SUM_MODE => LOCAL_SUM_GEN, W_LS => W_LS)
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
  --!@brief LOCAL DIFF
  -----------------------------------------------------------------------------
  localdiff_core: entity shyloc_123.localdiffv3(arch_shyloc)
  generic map (RESET_TYPE => RESET_TYPE, DRANGE => DRANGE,PREDICTION_MODE => PREDICTION_GEN, W_LS => W_LS, W_LD => W_LD)
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
  -- Assigns values to be stored in record FIFO. The record FIFO stores the
  -- necessary values for the prediction, until the local differences vector
  -- is read/written to the external memory through AHB master.
  -----------------------------------------------------------------------------
  localdiff_results_in.opcode_predict <= opcode_predict;
  localdiff_results_in.ls_predict <= ls_predict;
  localdiff_results_in.s_predict <= s_predict;
  localdiff_results_in.z_predict <= z_predict;
  localdiff_results_in.t_predict <= t_predict;
  
  -----------------------------------------------------------------------------
  --!@brief generation of localdiff vector for reduced prediction
  ----------------------------------------------------------------------------- 
  gen_ld_vector_record_in_full: if PREDICTION_GEN = 0 generate
    --Driven to 0 as they are not needed
    --We only use one central ld at a time, as the computation 
    --of the multiply and accumulation for the dot product is sequential. 
    ld_vector(4 to Cz-1) <= (others => (others => '0'));
    ld_vector_to_update(4 to Cz-1) <= (others => (others => '0'));
    ld_vector_predict(4 to Cz-1) <= (others => (others => '0'));
    custom_wei_vector(4 to Cz-1) <= (others => (others => '0'));
    updated_weight(4 to Cz-1) <= (others => (others => '0')); 
    wei_vector_to_update(4 to Cz-1) <= (others => (others => '0'));   
    -- Assign directional local differences.
    localdiff_results_in.ld_vector (0) <= ld_n;
    localdiff_results_in.ld_vector (1) <= ld_nw;
    localdiff_results_in.ld_vector (2) <= ld_w;
    gen_central_ld_record_in: if P_MAX > 0 generate
      -- Only one value of local differences is needed.
      localdiff_results_in.ld_vector (3) <= ld;
    end generate gen_central_ld_record_in;  
  end generate gen_ld_vector_record_in_full;
  
  gen_ld_vector_record_in_reduced: if PREDICTION_GEN = 1 generate
    --Driven to 0 as they are not needed
    --We only use one central ld at a time, as the computation 
    --of the multiply and accumulation for the dot product is sequential. 
    ld_vector(1 to Cz-1) <= (others => (others => '0'));
    ld_vector_to_update(1 to Cz-1) <= (others => (others => '0'));
    ld_vector_predict(1 to Cz-1) <= (others => (others => '0'));
    custom_wei_vector(1 to Cz-1) <= (others => (others => '0'));
    updated_weight(1 to Cz-1) <= (others => (others => '0')); 
    wei_vector_to_update(1 to Cz-1) <= (others => (others => '0')); 
    --No directional local differences
    gen_central_ld_record_in: if P_MAX > 0 generate
      -- Only one value of local differences is needed.
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
    generic map (
      NE => NE_RECORD_BSQ,
      W_ADDR  => W_ADDR_RECORD_BSQ, EDAC => 0, TECH => TECH
    )
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
      edac_double_error => edac_double_error_vector(2) 
  );

  -----------------------------------------------------------------------------
  --!@brief Create ld vector for prediction from values read from record FIFO
  -----------------------------------------------------------------------------
  
  gen_ld_vector_record_out: if Cz > 0 generate
    --Directional local differences
    ld_vector_predict (0 to FULL*2) <= localdiff_results_out.ld_vector(0 to FULL*2);
    gen_ld_central: if P_MAX  > 0 generate
      -- One central local difference that will be stored in external memory
      ld_vector_predict (FULL*3) <= localdiff_results_out.ld_vector(FULL*3);
    end generate gen_ld_central;
  end generate gen_ld_vector_record_out;
  
  -----------------------------------------------------------------------------
  --!@brief Validate values read from record FIFO for one clk.
  -----------------------------------------------------------------------------
  valid_ff_record_flag: entity shyloc_123.ff1bit(arch)
      generic map (RESET_TYPE => RESET_TYPE)
      port map (
        rst_n => rst_n,
        clk => clk,
        clear => clear, 
        din => r_update_record, 
        dout => valid_fifo_record_value 
    );
  
  -- Assigns values read from record FIFO to be input to the predictor module
  z_predictor <= localdiff_results_out.z_predict;
  t_predictor <= localdiff_results_out.t_predict;
  opcode_predictor <= localdiff_results_out.opcode_predict; 
  ls_predictor <= localdiff_results_out.ls_predict;         
  s_predictor <= localdiff_results_out.s_predict;
  
  -----------------------------------------------------------------------------
  --!@brief generation of localdiff vector for prediction from values read from
  --! record FIFO
  -----------------------------------------------------------------------------
  gen_vector_full: if PREDICTION_GEN = 0 generate 
    ld_vector(0) <= ld_vector_predict(0);
    ld_vector(1) <= ld_vector_predict(1);
    ld_vector(2) <= ld_vector_predict(2);
    gen_central_condition: if P_MAX > 0 generate
      ld_vector(3) <= ld_mac; --ld_vector_central(i-3);
    end generate gen_central_condition;
  end generate gen_vector_full;
        
  gen_vector_reduced: if PREDICTION_GEN = 1 generate
    gen_central_condition: if P_MAX > 0 generate
      ld_vector(0) <= ld_mac; --ld_vector_central(i); just one Ld at a time
    end generate gen_central_condition; 
  end generate gen_vector_reduced;
        
  -----------------------------------------------------------------------------
  -- Multiply and accumulate directional local differences
  -----------------------------------------------------------------------------
    gen_directional_product: if PREDICTION_GEN = 0 generate
    -----------------------------------------------------------------------------
    --!@brief DOT PRODUCT for 2 DIRECTIONAL DIFFERENCES 
    -----------------------------------------------------------------------------
    dot_product_core01: entity shyloc_123.mult_acc_shyloc(arch)
    generic map(
      Cz    =>  2, -- I have 3 directional differences only
      W_LD  =>  W_LD, W_WEI =>  W_WEI, W_RES =>  W_DZ
    )
    port map(
      clk => clk, 
      rst_n => rst_n, 
      en => mac_enable, --for the first sample there's no update and no MAC computation
      clear => clear,
      result => result_dot10, 
      valid => valid_dot,
      ld_vector => ld_vector_predict (0 to 1),
      wei_vector => updated_weight (0 to 1)
    );
    -----------------------------------------------------------------------------
    --!@brief Generate signal to enable mutiplication
    -----------------------------------------------------------------------------
    mult_enable: entity shyloc_123.ff1bit(arch)
      generic map (RESET_TYPE => RESET_TYPE)
      port map (rst_n => rst_n, clk => clk, clear => clear, din => mac_enable, dout => en_mult_directional);
      
    -----------------------------------------------------------------------------
    --!@brief DOT PRODUCT for 1 DIRECTIONAL DIFFERENCES 
    -----------------------------------------------------------------------------
    mult_core2: entity shyloc_123.mult(arch)
    generic map(W_LD  =>  W_LD, W_WEI =>  W_WEI, W_PRODUCT =>  W_DZ)
    port map(
      clk => clk, 
      rst_n => rst_n, 
      en => en_mult_directional, --not sure if this will always be like this or i'll need the signal at the control
      clear => clear,
      result => product_dot2, 
      ld_data_in => ld_vector (2),
      weight_data_in => updated_weight (2)
    );
    -----------------------------------------------------------------------------
    ---!@brief ADDER for directional product - this adder does not have an enable (0_0)
    -----------------------------------------------------------------------------
    adder_core2: entity shyloc_123.adder(arch)
      generic map ( W_OP => W_DZ, W_RES => W_DZ)
      port map (clk => clk, rst_n => rst_n, 
      clear => clear, op1 => result_dot10, op2 => product_dot2, result => accumulated_directional);
    
    -----------------------------------------------------------------------------
    --!@brief ANOTHER ADDER for directional product - this adder does not have an enable (0_0)
    -----------------------------------------------------------------------------
    add_directional_central: entity shyloc_123.adder(arch)
      generic map (W_OP => W_DZ, W_RES => W_DZ)           
      port map (clk => clk, rst_n => rst_n, clear => clear, op1 => accumulated_directional, 
        op2 => dot_product_central, -- from MAC; I need to be sure this is done at the right moment!
        result => result_dot_dir);
        
    result_dot <= result_dot_dir when config_predictor.PREDICTION = "0" else dot_product_central;
  end generate gen_directional_product;
  
  -----------------------------------------------------------------------------
  --!@brief If the directional differences are not needed, set the accumulator to 0
  -----------------------------------------------------------------------------
  gen_directional_acc: if PREDICTION_GEN = 1 generate
    accumulated_directional <= (others => '0');
    result_dot <= dot_product_central;
  end generate gen_directional_acc; 
  
  -----------------------------------------------------------------------------
  -- Resize to store in AHB FIFO
  -----------------------------------------------------------------------------
  gen_ld_in_ahbo: if P_MAX > 0 generate
    ld_in_ahbo <= std_logic_vector(resize(unsigned(ld_vector_predict(3*FULL)), ld_in_ahbo'length));
  end generate gen_ld_in_ahbo;
  
  -----------------------------------------------------------------------------
  --!@brief FIFO for ld central values, to be sent to external memory
  -----------------------------------------------------------------------------
  fifo_ld_to_ahb: entity shyloc_123.async_fifo(arch)
    generic map(
      W => 32, NE => NE_AHB_FIFO_BSQ, RESET_TYPE => RESET_TYPE, TECH => TECH
    )
    port map (
      clkw => clk, 
      resetw => rst_n, 
      async_clr => clear,
      wr => w_update_ld_ahbo, 
      full => full_ld_ahbo, 
      data_in => ld_in_ahbo, 
      data_out => ld_out_ahbo, 
      clkr => clk_ahb, 
      resetr => rst_ahb, 
      rd => r_update_ld_ahbo,
      empty => empty_ld_ahbo
    );  

  ----------------------------------------------------------------------------- 
  --!@brief Control for AHB master interface (reads/writes from FIFOs and
  --! generates data/control signals
  -----------------------------------------------------------------------------
  ahbmemio: entity shyloc_123.ahbtbm_ctrl_bsq(arch_shyloc_bsq)
    generic map  (W => 32, 
      Nx => Nx_GEN, Ny => Ny_GEN, Nz => Nz_GEN, NBP => P_MAX)
    port map (
      rst_ahb   => rst_ahb,
      clk_ahb  => clk_ahb, 
      
      rst_s   => rst_n,
      clk_s  => clk, 
      clear_s => clear,
      ahbm_status => ahbm_status, 
      config_valid_s => config_valid, 
      config_image_s => config_image, 
      config_predictor_s => config_predictor,
      --configuration clocked with AHB
      config_ahbm => config_ahbm, 
      --input FIFO
      data_out_in => ld_out_ahbo, 
      rd_in => r_update_ld_ahbo, 
      empty_in => empty_ld_ahbo,
    
      --output FIFO
      data_in_out => ld_in_ahbi, 
      wr_out => w_update_ld_ahbi, 
      full_out => full_ld_ahbi, 
      hfull_out => hfull_ld_ahbi,
    
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
  --!@brief FIFO for ld central values, received from external memory
  -----------------------------------------------------------------------------
  fifo_ld_from_ahb: entity shyloc_123.async_fifo(arch)
    generic map(W => 32, NE => NE_AHB_FIFO_BSQ, RESET_TYPE => RESET_TYPE, DIFFERENCE => DIFFERENCE_AHB_BSQ , TECH => TECH
    )
    port map (
      clkw => clk_ahb, 
      resetw => rst_ahb, 
      async_clr => clear,
      wr => w_update_ld_ahbi, 
      full => full_ld_ahbi_out, 
      data_in => ld_in_ahbi, 
      data_out => ld_out_ahbi, 
      clkr => clk, 
      resetr => rst_n, 
      rd => r_update_ld_ahbi,
      empty => empty_ld_ahbi,
      hfull => hfull_ld_ahbi
    );  
  
  -- Central local diff value read from external memory - To be used in MAC
  ld_mac <= ld_out_ahbi(ld_mac'high downto 0);
  
  ----------------------------------------------------------------------------- 
  --!@brief Pipeline register: STORAGE OF central ld sample from AHBi to local FIFO
  ----------------------------------------------------------------------------- 
  ld_mac_delay: entity shyloc_123.shift_ff(arch)
  generic map ( N => W_LD, 
      N_STAGES => 2, --adjust if not correct!!!
      RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => ld_mac, dout => ld_mac_synch_weight);
  
  ----------------------------------------------------------------------------- 
  --!@brief Register to generate write update to store the central ld in the FIFO
  ----------------------------------------------------------------------------- 
  ld_read_enable: entity shyloc_123.ff1bit(arch)
  generic map (RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => r_update_ld_ahbi, dout => w_update_ld);
  
  ----------------------------------------------------------------------------- 
  --!@brief Storage of central ld value read from external memory to be used
  --! later by weight update module
  -----------------------------------------------------------------------------
  	-- EDAC here disabled, this FIFO is expected to be
    -- implemented by FFs instead of BRAM due to limited size.
    -- assign EDAC => EDAC if you wish generic parameter value to 
    -- be passed.
    -- Check your synthesis results to ensure no BRAM is used, otherwise
    -- enable edac by assigning EDAC => EDAC
  fifo_3_ld: entity shyloc_utils.fifop2(arch)
    generic map (RESET_TYPE => RESET_TYPE, W => W_LD, NE => NE_LD_BSQ, W_ADDR => W_ADDR_LD_BSQ, EDAC => 0, TECH => TECH)  
    port map (
      clk => clk,
      rst_n => rst_n,
      clr => clear,
      w_update => w_update_ld, --read from ahbi
      r_update => r_update_ld,
      data_in => ld_mac,
      data_out => ld_central_weight_update, 
      full => full_ld, 
      edac_double_error => edac_double_error_vector(3) 
    );
  
  ----------------------------------------------------------------------------- 
  --!@brief Local diff vector to be used by weight udpate module
  -----------------------------------------------------------------------------
  gen_ld_vectort_to_update: if P_MAX > 0 generate
    ld_vector_to_update(3*FULL) <= ld_central_weight_update;
  end generate gen_ld_vectort_to_update;
  
  -----------------------------------------------------------------------------
  --!@brief PREDICTOR CORE
  -----------------------------------------------------------------------------
  predictor_core: entity shyloc_123.predictor2stagesv2(arch)
  generic map (RESET_TYPE => RESET_TYPE, OMEGA => OMEGA_GEN, W_S_SIGNED => W_S_SIGNED, R => R_GEN, W_DZ => W_DZ, NBP => P_MAX, 
       W_SCALED => W_SCALED, W_SMAX => W_SMAX, W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE, W_LS => W_LS
      )
  port map (
     clk => clk, 
     rst_n => rst_n, 
     opcode => opcode_predictor, 
     en => en_predictor, --connecting en_predictor to valid_dot
    clear => clear, 
    config_predictor => config_predictor,
    config_image => config_image, 
     z => z_predictor, --this is not really needed
     s => s_predictor, 
     smax_var => smax_var, 
     smin_var => smin_var,
     smid_var => smid_var, 
     dz => result_dot, 
     ls => ls_predictor, 
     valid => valid_predictor,
     smax => smax,
     smin => smin, 
     s_mapped => s_mapped,
     s_scaled =>  s_scaled
  );
  
  -----------------------------------------------------------------------------
  --@brief PIPELINE register: stores z from predictor to update weights
  -----------------------------------------------------------------------------
  z_delay_weights: entity shyloc_123.shift_ff(arch)
  generic map ( N => z'length, N_STAGES => 2, --adjust if not correct!!!
        RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => z_predictor, dout => z_weights);
  
  -----------------------------------------------------------------------------
  --@brief PIPELINE register: stores opcode from predictor to rho
  -----------------------------------------------------------------------------
  -- Modified by AS: shift_ff_en component replaced by simple register with enable (ff_en), as the number of stages is always 1
  opcode_delay_ro: entity shyloc_123.ff_en(arch)
  generic map (N => 5, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, en => valid_fifo_record_value, din => opcode_predictor, dout => opcode_ro);
  -- opcode_delay_ro: entity shyloc_123.shift_ff_en(arch)
  -- generic map (N => 5, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  -- port map (rst_n => rst_n, clk => clk, clear => clear, en => valid_fifo_record_value, din => opcode_predictor, dout => opcode_ro);
  
  -----------------------------------------------------------------------------
  --!@brief Register to generate enable for rho one clk after enable from predictor
  -----------------------------------------------------------------------------
  rho_enable: entity shyloc_123.ff1bit(arch)
  generic map (RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => en_predictor, dout => en_rho_update);
  
  -----------------------------------------------------------------------------
  --!@brief PIPELINE register: stores z from predictor to rho
  -----------------------------------------------------------------------------
  z_delay_pred_rho: entity shyloc_123.shift_ff(arch)
  generic map (N => W_ADDR_IN_IMAGE, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => z_predictor, dout => z_rho);
  
  -----------------------------------------------------------------------------
  --!@brief PIPELINE register: stores t from predictor to rho
  -----------------------------------------------------------------------------
  t_delay_pred_rho: entity shyloc_123.shift_ff(arch)
  generic map (N => W_T, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
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
  
  -----------------------------------------------------------------------------
  --!@brief PIPELINE register: stores z from rho to mapped
  -----------------------------------------------------------------------------
  z_delay_rho_mapped: entity shyloc_123.shift_ff(arch)
  generic map (N => W_ADDR_IN_IMAGE, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => z_rho, dout => z_mapped);
  
  -----------------------------------------------------------------------------
  --!@brief MAP CORE
  -----------------------------------------------------------------------------
  map_core: entity shyloc_123.map2stagesv2(arch)
  generic map (W_S_SIGNED => W_S_SIGNED, W_SCALED => W_SCALED, W_SMAX => W_SMAX, W_MAP => W_MAP)
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
    
    -----------------------------------------------------------------------------
    --!@brief Finished signal generation: one cycle after last mapped residual is issued
    -----------------------------------------------------------------------------
  --CYCLES MAP is (cycles map +1)
  finished_gen_core: entity shyloc_123.finished_gen(arch)
    generic map(CYCLES_MAP  => 3, W_ADDR_IN_IMAGE => W_ADDR_IN_IMAGE,  Nz => Nz_GEN, RESET_TYPE => RESET_TYPE)
    port map( rst_n => rst_n, clk => clk, 
      en => valid_predictor, 
      opcode_mapped => opcode_weight, 
      clear => clear, 
      config_image => config_image,
      z_mapped => z_mapped,
      finished => finished);
  
  -----------------------------------------------------------------------------
  --!@brief PIPELINE register: stores opcode from rho to update weight
  -----------------------------------------------------------------------------
  opcode_delay_weights: entity shyloc_123.shift_ff(arch)
  generic map (N => 5, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
  port map (rst_n => rst_n, clk => clk, clear => clear, din => opcode_ro, dout => opcode_weight);
  
  -- Enable update or initialization of the weights
  -- en_weight_dir_fsm comes from FSM. I is activated
  -- when the central local differences have arrived from the
  -- external memory.
  en_init_weight_dir <= en_weight_dir_fsm  when opcode_weight_fsm(3 downto 0) = "0000" else '0';
  en_update_weight_dir <= en_weight_dir_fsm  when opcode_weight_fsm(3 downto 0) /= "0000" else '0';
  
  en_init_weight_central <= en_weight_central_fsm when opcode_weight_fsm(3 downto 0) = "0000" else '0';
  en_update_weight_central <= en_weight_central_fsm when opcode_weight_fsm(3 downto 0) /= "0000" else '0';
  

  gen_dir_weight: if PREDICTION_GEN = 0 generate
    -----------------------------------------------------------------------------
    --!@brief WEIGHT UPDATE MODULE for directional
    --! weight update. It is done in parallel.
    -----------------------------------------------------------------------------
    dir_wei_update_core: entity shyloc_123.weight_update_shyloc_top(arch_bip)
    generic map (
        DRANGE => DRANGE, W_WEI => W_WEI, W_LD => W_LD, W_SCALED => W_SCALED, W_RO => W_RO,
        WE_MIN => WE_MIN, WE_MAX => WE_MAX, MAX_RO => MAX_RO, Cz => 3,  TABLE => WEIGHT_INIT_GEN,
        PREDICTION_MODE => PREDICTION_GEN,  OMEGA => OMEGA_GEN, RESET_TYPE => RESET_TYPE)
    port map (                                
      clk => clk,
      rst_n => rst_n,
      en_update => en_update_weight_dir,
      en_init => en_init_weight_dir,
      clear => clear, 
      config_valid => config_valid,
      config_predictor => config_predictor, 
      s_signed => s_mapped, -- they are working in paralell
      s_scaled => s_scaled,
      ld_vector => ld_vector_to_update (0 to 2),
      custom_wei_vector => custom_wei_vector (0 to 2),
      wei_vector => wei_vector_to_update (0 to 2),
      ro => ro, 
      valid => valid_weight_update,
      updated_weight => updated_weight (0 to 2)
      );
  end generate gen_dir_weight;
  
  -- The central weight values are obtained sequentially
  -- as dictated by the FSM
  gen_central_ini: if P_MAX > 0 generate
    -----------------------------------------------------------------------------
    --!@brief Central weight initialization - a single value is generated
    --! sequentially, address is generated by the FSM
    -----------------------------------------------------------------------------
    central_wei_init: entity shyloc_123.weight_init_shyloc(arch)
      generic map (
           W_WEI => W_WEI, W_INIT_TABLE => W_COUNT_PRED, --I'll count as many weights as bands used for prediction
           PREDICTION_MODE => 1, --this is fixed to 1, because I want it only to generate the central diffs ;)
           OMEGA => OMEGA_GEN, RESET_TYPE => RESET_TYPE)
      port map (                                
        clk => clk, 
        rst_n => rst_n,
        en => en_init_weight_central, 
        clear => clear, 
        config_valid => config_valid,
        config_predictor => config_predictor, 
        address => address_central, 
        def_init_weight_value => updated_weight_reg, 
        valid => valid_init_central
      );
      
    -----------------------------------------------------------------------------
    --!@brief Central weight update - a single weight value is updated
    --! sequentially, as dictated by the FSM
    -----------------------------------------------------------------------------
    central_wei_update: entity shyloc_123.weight_update_shyloc(arch)
      generic map( DRANGE => DRANGE, W_WEI => W_WEI, W_LD => W_LD, W_SCALED => W_SCALED, W_RO => W_RO, WE_MIN => WE_MIN, WE_MAX => WE_MAX, MAX_RO => MAX_RO, 
      RESET_TYPE => RESET_TYPE )  
      port map(
        clk => clk, 
        rst_n => rst_n, 
        en => en_update_weight_central, 
        clear => clear, 
        config_valid => config_valid,
        config_predictor => config_predictor, 
        s_signed => s_mapped, --from predictor
        s_scaled => s_scaled, 
        ld => ld_vector_to_update(3*FULL), 
        weight => wei_vector_to_update(3*FULL), 
        ro => ro, 
        updated_weight => updated_weight_up, 
        valid => valid_update_central 
      );
  end generate gen_central_ini;
  
  -----------------------------------------------------------------------------
  --!@brief PIPELINE register: stores initial weight to MAC
  -----------------------------------------------------------------------------
  delay_init_central: entity shyloc_123.shift_ff(arch)
    generic map (N => W_WEI, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
    port map (rst_n => rst_n, clk => clk, clear => clear, 
      din => updated_weight_reg, 
      dout => updated_weight_init  --to MAC
    );
  
  -----------------------------------------------------------------------------
  --!@brief PIPELINE register: stores validation of initial weight until MAC
  -----------------------------------------------------------------------------
  delay_valid_init_central: entity shyloc_123.ff1bit(arch)
    generic map (RESET_TYPE => RESET_TYPE)
    port map (rst_n => rst_n, clk => clk, clear => clear, din => valid_init_central, dout => valid_init_central_synch  --to MAC
    );
    
  gen_wei_update: if P_MAX > 0 generate
    -----------------------------------------------------------------------------
    --!@brief PIPELINE register: stores updated weight 
    -----------------------------------------------------------------------------
    central_wei_reg: entity shyloc_123.shift_ff(arch)
      generic map (N => W_WEI, N_STAGES => 1, RESET_TYPE => RESET_TYPE)
      port map (rst_n => rst_n, clk => clk, clear => clear, din => updated_weight (FULL*3), dout => central_weight_reg );
    -- Select between init and central weight for MAC
    -- I need the local differences and weight pairs to be synchronized for the
    -- multiply & accumulate operation.
    updated_weight (FULL*3) <= updated_weight_init when valid_init_central_synch = '1' else updated_weight_up when valid_update_central = '1' else central_weight_reg;  
  end generate gen_wei_update;

  -----------------------------------------------------------------------------
  --!@brief Register the read flag of the record FIFO; will be use
  --! to generate a write update to the ld FIFO.
  -----------------------------------------------------------------------------
  read_record_reg: entity shyloc_123.ff1bit(arch)
    generic map (RESET_TYPE => RESET_TYPE)
    port map (rst_n => rst_n, clk => clk, clear => clear, din => r_update_record, dout => r_update_record_reg);
  

  -----------------------------------------------------------------------------
  --!@brief Flags to write in ld and weights intermediate FIFOs (full prediction)
  -----------------------------------------------------------------------------
  write_fifo_full: if PREDICTION_GEN = 0 generate
    w_update_ld_central <= valid_init_central_synch or valid_update_central;
    w_update_wei_dir <= valid_weight_update;  
    w_update_ld_dir <= '0'  when opcode_predictor(3 downto 0) = "0000" and unsigned(z_predictor) = 0 else r_update_record_reg;
    mac_enable <= valid_weight_update;-- or valid_init_central or valid_update_central; --for directional mac
  end generate;
  
  -----------------------------------------------------------------------------
  --!@brief Flags to write in ld and weights intermediate FIFOs (reduced prediction)
  -----------------------------------------------------------------------------
  write_fifo_reduced: if PREDICTION_GEN = 1 generate
    w_update_ld_central <= valid_init_central_synch or valid_update_central;
  end generate write_fifo_reduced;
  

  gen_dir_weight_storage: if PREDICTION_GEN = 0 generate
    wei_vector_to_update (0 to 2) <= updated_weight(0 to 2);
    -----------------------------------------------------------------------------
    --!@brief FIFO stores directional local differences until weight update
    -----------------------------------------------------------------------------
	-- EDAC here disabled, this FIFO is expected to be
    -- implemented by FFs instead of BRAM due to limited size.
    -- assign EDAC => EDAC if you wish generic parameter value to 
    -- be passed.
    -- Check your synthesis results to ensure no BRAM is used, otherwise
    -- enable edac by assigning EDAC => EDAC
    localdiff_dir_fifo_4: entity shyloc_123.ld_2d_fifo(arch)
      generic map( Cz => 3, W => W_LD, NE => NE_LD_DIR_BSQ, W_ADDR => W_ADDR_LD_DIR_BSQ, RESET_TYPE => RESET_TYPE, EDAC => 0, TECH => TECH)
      port map(
        clk => clk,
        rst_n => rst_n,
        clr  => clear,
        w_update  => w_update_ld_dir, 
        r_update => r_update_wei_dir,
        data_vector_in => ld_vector_predict(0 to 2),
        data_vector_out => ld_vector_to_update(0 to 2), 
        full => full_ld_vector_to_update, 
        edac_double_error => edac_double_error_vector(4)
      );
  end generate gen_dir_weight_storage; 
  
  gen_no_dir_weight_storage: if PREDICTION_GEN /= 0 generate
    --Drive to zero when not assigned.
    edac_double_error_vector(4) <= '0';
  end generate gen_no_dir_weight_storage;
  
  -- Clear multacc registers.
  clear_multacc <= en_predictor or clear;
  
  gen_central_mac: if P_MAX > 0 generate
    -----------------------------------------------------------------------------
    --!@brief FIFO stores weight update values until update
    -----------------------------------------------------------------------------
	-- EDAC here disabled, this FIFO is expected to be
    -- implemented by FFs instead of BRAM due to limited size.
    -- assign EDAC => EDAC if you wish generic parameter value to 
    -- be passed.
    -- Check your synthesis results to ensure no BRAM is used, otherwise
    -- enable edac by assigning EDAC => EDAC
    fifo_5_weight_update: entity shyloc_utils.fifop2(arch)
      generic map (RESET_TYPE => RESET_TYPE, W => W_WEI,
        NE => NE_WEI_BSQ,
        W_ADDR => W_ADDR_WEI_BSQ, EDAC => 0, TECH => TECH)  
      port map (
        clk => clk,
        rst_n => rst_n,
        clr => clear,
        w_update => w_update_ld_central,  --synchronized with ld
        r_update => r_update_wei,
        data_in => updated_weight(3*FULL), -- to MAC
        data_out => wei_vector_to_update(3*FULL), 
        full => full_wei_vector_to_update, 
        edac_double_error => edac_double_error_vector(5) 
      );
      
    -----------------------------------------------------------------------------
    --!@brief Multiply and accumulate a pair of central ld and weight values.
    ----------------------------------------------------------------------------- 
    multacc: entity shyloc_123.mult_acc2stagesv2(arch)
    generic map (W_LD => W_LD,          
         W_WEI => W_WEI,        
         W_RESULT_MAC => W_DZ, RESET_TYPE => RESET_TYPE)
                  
    port map (
      clk => clk,
      rst_n => rst_n, 
      en => w_update_ld_central, --ld_mac has to be also ready
      clear => clear_multacc, --clearing it with prediction's enable shall do the job!
      ld_data_in => ld_mac_synch_weight,  -- from ahbo
      weight_data_in => updated_weight(3*FULL),
      result => dot_product_central
      );
  end generate gen_central_mac;
  
  gen_central_mac_p0: if P_MAX = 0 generate
    -- force zero if P = 0
    dot_product_central <= (others => '0');
    edac_double_error_vector(5)  <= '0';
  end generate gen_central_mac_p0;

end arch_bsq;
